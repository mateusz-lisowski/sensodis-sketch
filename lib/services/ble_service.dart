import 'dart:async';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:get/get.dart';
import 'package:location/location.dart' hide PermissionStatus;
import 'package:permission_handler/permission_handler.dart';
import '../utils/app_constants.dart';

class BleService extends GetxService {
  final devices = <ScanResult>[].obs;
  final isScanning = false.obs;

  StreamSubscription<List<ScanResult>>? _scanSub;
  Timer? _restartTimer;

  @override
  void onInit() {
    super.onInit();
    _startAutoScan();
  }

  Future<void> _startAutoScan() async {
    while (true) {
      try {
        await _ensurePermissionsAndServices();
        await _startScan();
        break; // Exit loop if successful
      } catch (e) {
        print("Setup failed, retrying in 3s: $e");
        await Future.delayed(Duration(seconds: 3));
      }
    }
  }

  /// Unified interface to check and request all necessary permissions and services
  Future<void> _ensurePermissionsAndServices() async {
    // 1. Request Runtime Permissions
    Map<Permission, PermissionStatus> statuses = await [
      Permission.location,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
    ].request();

    if (statuses[Permission.location]!.isDenied ||
        statuses[Permission.bluetoothScan]!.isDenied ||
        statuses[Permission.bluetoothConnect]!.isDenied) {
      throw Exception("Required permissions are denied.");
    }

    // 2. Ensure Bluetooth is On
    if (await FlutterBluePlus.adapterState.first == BluetoothAdapterState.off) {
      try {
        await FlutterBluePlus.turnOn();
        // Wait up to 5 seconds for Bluetooth to turn on
        try {
            await FlutterBluePlus.adapterState
                .firstWhere((s) => s == BluetoothAdapterState.on)
                .timeout(Duration(seconds: 5));
        } catch (_) {
            throw Exception("Bluetooth failed to turn on in time.");
        }
      } catch (e) {
        throw Exception("Could not turn on Bluetooth: $e");
      }
    }

    // 3. Ensure Location Service is Enabled
    Location location = Location();
    bool serviceEnabled = await location.serviceEnabled();
    if (!serviceEnabled) {
      serviceEnabled = await location.requestService();
      if (!serviceEnabled) {
        throw Exception("Location service is disabled.");
      }
    }
  }

  Future<void> _startScan() async {
    await _stopScan();

    // Listen for devices (only T&D devices)
    _scanSub = FlutterBluePlus.scanResults.listen((results) {
      devices.value = results.where((r) {
        return r.device.platformName.startsWith('TR') ||
            r.advertisementData.manufacturerData.containsKey(AppConstants.tndCompanyId);
      }).toList();
    });

    // Restart every 2 minutes to keep scan alive
    _restartTimer = Timer.periodic(Duration(minutes: 2), (_) {
      _restartScan();
    });

    await FlutterBluePlus.startScan(
      timeout: Duration(seconds: 60),
      continuousUpdates: true,
      androidUsesFineLocation: true,
    );

    isScanning.value = true;
    print("BLE Scan: Started");
  }

  Future<void> _restartScan() async {
    try {
      await FlutterBluePlus.stopScan();
      await Future.delayed(Duration(milliseconds: 100));
      await FlutterBluePlus.startScan(
        timeout: Duration(seconds: 30),
        continuousUpdates: true,
        androidUsesFineLocation: true,
      );
      print("BLE Scan: Restarted");
    } catch (_) {}
  }

  Future<void> _stopScan() async {
    _scanSub?.cancel();
    _scanSub = null;

    _restartTimer?.cancel();
    _restartTimer = null;

    try {
      await FlutterBluePlus.stopScan();
    } catch (_) {}

    isScanning.value = false;
  }

  @override
  void onClose() {
    _stopScan();
    super.onClose();
  }
}
