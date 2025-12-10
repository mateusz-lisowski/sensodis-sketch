import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:location/location.dart' as loc;
import '../utils/ble_decoder.dart';

class BleService extends GetxService {
  final isScanning = false.obs;
  final scanResults = <ScanResult>[].obs;

  // T&D Corporation's Bluetooth Company ID is 0x0392 (914).
  static const int tndCompanyId = 914;

  // Internal state management
  StreamSubscription<List<ScanResult>>? _scanSubscription;
  StreamSubscription<bool>? _isScanningSubscription;
  Timer? _scanUpdateTimer;
  Timer? _scanTimeoutTimer;
  List<ScanResult> _latestResults = [];
  bool _wantsToScan = false; // Tracks our intention to scan
  int _restartAttempts = 0;
  DateTime? _lastRestartAttempt;
  AppLifecycleState? _appLifecycleState;
  bool _isRestarting = false; // Track if we're in restart process

  @override
  void onInit() {
    super.onInit();

    // Initialize app lifecycle monitoring
    _setupAppLifecycleMonitoring();

    // Setup scan results processing with debouncing
    _setupScanResultsProcessing();

    // Monitor scan state for unexpected stops
    _isScanningSubscription = FlutterBluePlus.isScanning.listen((scanning) {
      isScanning.value = scanning;

      // Only trigger restart if we want to scan but system stopped
      if (!scanning && _wantsToScan && !_isRestarting) {
        print("BleService: System stopped scanning. Attempting to restart...");
        _restartScanWithBackoff();
      }
    });
  }

  void _setupAppLifecycleMonitoring() {
    // Monitor app lifecycle to pause/resume scanning
    SystemChannels.lifecycle.setMessageHandler((msg) async {
      _appLifecycleState = _parseAppLifecycleMessage(msg);

      if (_appLifecycleState == AppLifecycleState.paused ||
          _appLifecycleState == AppLifecycleState.inactive) {
        print("BleService: App paused, stopping scan");
        await stopScan();
      } else if (_appLifecycleState == AppLifecycleState.resumed && _wantsToScan) {
        print("BleService: App resumed, restarting scan");
        await Future.delayed(const Duration(seconds: 1));
        await startScan();
      }
      return null;
    });
  }

  void _setupScanResultsProcessing() {
    // Listen to raw scan results
    _scanSubscription = FlutterBluePlus.scanResults.listen((results) {
      // Filter for T&D devices
      final filteredResults = results.where((r) {
        final hasName = r.device.platformName.startsWith('TR');
        final hasManufacturerData =
        r.advertisementData.manufacturerData.containsKey(tndCompanyId);
        return hasName || hasManufacturerData;
      }).toList();

      // Store filtered results for periodic UI updates
      _latestResults.addAll(filteredResults);
    });

    // Update UI periodically to reduce main thread load
    _scanUpdateTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (_latestResults.isNotEmpty) {
        scanResults.value = List.from(_latestResults);
        _logScanResults(_latestResults);
        _latestResults.clear();
      }
    });
  }

  Future<void> _restartScanWithBackoff() async {
    if (!_wantsToScan || _isRestarting) return;

    _isRestarting = true;

    final now = DateTime.now();
    if (_lastRestartAttempt != null &&
        now.difference(_lastRestartAttempt!) < const Duration(seconds: 5)) {
      _restartAttempts++;
    } else {
      _restartAttempts = 1;
    }
    _lastRestartAttempt = now;

    // Exponential backoff with maximum of 30 seconds
    final backoffSeconds = min(_restartAttempts * 2, 30);

    // Stop trying after 5 attempts
    if (_restartAttempts > 5) {
      print("BleService: Too many restart attempts, stopping scan");
      _wantsToScan = false;
      _isRestarting = false;
      Get.snackbar(
        'BLE Error',
        'Failed to maintain BLE scan after multiple attempts',
        duration: const Duration(seconds: 5),
      );
      return;
    }

    print("BleService: Restarting scan in $backoffSeconds seconds (attempt $_restartAttempts)");
    await Future.delayed(Duration(seconds: backoffSeconds));

    if (!_wantsToScan) {
      _isRestarting = false;
      return;
    }

    try {
      // Force a clean stop first
      await _cleanStopScan();
      await Future.delayed(const Duration(milliseconds: 500));

      // Start fresh scan
      await _startFreshScan();

      _restartAttempts = 0; // Reset on successful restart
      print("BleService: Scan successfully restarted");
    } catch (e) {
      print("BleService: Failed to restart scan: $e");
      // Retry with backoff
      _restartScanWithBackoff();
    } finally {
      _isRestarting = false;
    }
  }

  Future<void> _cleanStopScan() async {
    try {
      // Cancel subscription first
      await _scanSubscription?.cancel();
      _scanSubscription = null;

      // Stop the scan (don't worry if it fails)
      await FlutterBluePlus.stopScan();
    } catch (e) {
      print("BleService: Error during clean stop (expected if already stopped): $e");
    }
  }

  Future<void> _startFreshScan() async {
    // Ensure permissions and services are available
    if (!await _ensurePermissions()) {
      _wantsToScan = false;
      return;
    }
    if (!await _ensureLocationService()) {
      _wantsToScan = false;
      return;
    }
    if (!await _ensureBluetooth()) {
      _wantsToScan = false;
      return;
    }

    // Recreate scan subscription
    if (_scanSubscription == null || _scanSubscription!.isPaused) {
      await _scanSubscription?.cancel();
      _setupScanResultsProcessing();
    }

    try {
      // Clear any existing timeout
      _scanTimeoutTimer?.cancel();

      // Set new scan timeout (restart every 2 minutes for reliability)
      _scanTimeoutTimer = Timer(const Duration(minutes: 2), () {
        if (_wantsToScan && !_isRestarting) {
          print("BleService: Scan timeout reached, restarting...");
          _restartScanWithBackoff();
        }
      });

      await FlutterBluePlus.startScan(
        timeout: const Duration(seconds: 30), // Internal restart every 30 seconds
        continuousUpdates: true,
        androidUsesFineLocation: true,
        removeIfGone: const Duration(seconds: 10), // Remove devices not seen for 10s
      );

      print("BleService: Scan started successfully");
      _logScanState();
    } catch (e) {
      print("BleService: Error starting scan: $e");
      Get.snackbar(
        'Scan Error',
        'Failed to start scan: ${e.toString()}',
        duration: const Duration(seconds: 3),
      );
      _wantsToScan = false;
      throw e; // Re-throw to trigger retry
    }
  }

  Future<void> startScan() async {
    if (_wantsToScan) {
      print("BleService: Already wanting to scan, ignoring start request");
      return;
    }

    _wantsToScan = true;
    _restartAttempts = 0;
    _lastRestartAttempt = null;

    await _startFreshScan();
  }

  Future<void> stopScan() async {
    _wantsToScan = false;
    _restartAttempts = 0;

    _scanTimeoutTimer?.cancel();
    _scanTimeoutTimer = null;

    try {
      await _cleanStopScan();
      print("BleService: Scan stopped");
    } catch (e) {
      print("BleService: Error stopping scan: $e");
    }
  }

  Future<bool> _ensurePermissions() async {
    final permissions = [
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.location,
    ];

    while (true) {
      Map<Permission, PermissionStatus> statuses = await permissions.request();
      if (statuses.values.every((s) => s.isGranted)) return true;

      bool? retry = await Get.defaultDialog<bool>(
        title: 'Permissions Required',
        middleText: 'Bluetooth and Location permissions are required to scan for devices.',
        barrierDismissible: false,
        confirm: TextButton(
          onPressed: () async {
            Get.back(result: true);
            await openAppSettings();
          },
          child: const Text('Open Settings'),
        ),
        cancel: TextButton(
          onPressed: () => Get.back(result: false),
          child: const Text('Cancel'),
        ),
      );

      if (retry != true) return false;
    }
  }

  Future<bool> _ensureLocationService() async {
    final location = loc.Location();

    if (await location.serviceEnabled()) return true;

    if (await location.requestService()) return true;

    while (!await location.serviceEnabled()) {
      bool requestResult = await location.requestService();
      if (requestResult) return true;

      bool? retry = await Get.defaultDialog<bool>(
        title: 'Location Required',
        middleText: 'Please enable Location Services to scan for devices.',
        barrierDismissible: false,
        confirm: TextButton(
          onPressed: () => Get.back(result: true),
          child: const Text('Retry'),
        ),
        cancel: TextButton(
          onPressed: () => Get.back(result: false),
          child: const Text('Cancel'),
        ),
      );
      if (retry != true) return false;
    }

    return true;
  }

  Future<bool> _ensureBluetooth() async {
    if (GetPlatform.isAndroid &&
        await FlutterBluePlus.adapterState.first != BluetoothAdapterState.on) {
      try {
        await FlutterBluePlus.turnOn();
      } catch (_) {
        print("BleService: Failed to turn on Bluetooth programmatically");
      }
    }

    while (await FlutterBluePlus.adapterState.first != BluetoothAdapterState.on) {
      bool? retry = await Get.defaultDialog<bool>(
        title: 'Bluetooth Required',
        middleText: 'Please enable Bluetooth to scan for devices.',
        barrierDismissible: false,
        confirm: TextButton(
          onPressed: () async {
            Get.back(result: true);
            if (GetPlatform.isAndroid) {
              try {
                await FlutterBluePlus.turnOn();
              } catch (_) {
                print("BleService: Failed to turn on Bluetooth");
              }
            }
          },
          child: Text(GetPlatform.isAndroid ? 'Turn On' : 'Retry'),
        ),
        cancel: TextButton(
          onPressed: () => Get.back(result: false),
          child: const Text('Cancel'),
        ),
      );

      if (retry != true) return false;
    }
    return true;
  }

  void _logScanResults(List<ScanResult> results) {
    for (final result in results) {
      // Use shared decoder logic
      final decodedData = decodeTr4AdvertisingPacket(result.advertisementData);

      if (decodedData != null) {
        print('TR4 Packet: Serial=${decodedData.serialNumber}, Temp=${decodedData.temperature}, Battery=${decodedData.batteryLevel}, RSSI=${result.rssi}, Time=${DateTime.now()}');
      } else if (result.device.platformName.isNotEmpty) {
        print('Found device: ${result.device.platformName}, RSSI: ${result.rssi}');
      }
    }
  }

  void _logScanState() {
    print('''
  Scan State:
  - Wants to scan: $_wantsToScan
  - Is scanning: ${isScanning.value}
  - Is restarting: $_isRestarting
  - Results count: ${scanResults.length}
  - Restart attempts: $_restartAttempts
  - App lifecycle: $_appLifecycleState
  ''');
  }

  AppLifecycleState _parseAppLifecycleMessage(String? message) {
    if (message == null) return AppLifecycleState.resumed;
    switch (message) {
      case 'AppLifecycleState.paused':
        return AppLifecycleState.paused;
      case 'AppLifecycleState.resumed':
        return AppLifecycleState.resumed;
      case 'AppLifecycleState.inactive':
        return AppLifecycleState.inactive;
      case 'AppLifecycleState.detached':
        return AppLifecycleState.detached;
      default:
        return AppLifecycleState.resumed;
    }
  }

  @override
  void onClose() {
    print("BleService: Cleaning up resources");

    // Cancel all timers
    _scanUpdateTimer?.cancel();
    _scanTimeoutTimer?.cancel();

    // Cancel all subscriptions
    _isScanningSubscription?.cancel();
    _scanSubscription?.cancel();

    // Stop scanning
    stopScan();

    super.onClose();
  }
}
