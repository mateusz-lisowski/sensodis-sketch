import 'dart:async';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:get/get.dart';

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
        await _startScan();
        break; // Exit loop if successful
      } catch (e) {
        print("Scan failed, retrying in 3s: $e");
        await Future.delayed(Duration(seconds: 3));
      }
    }
  }

  Future<void> _startScan() async {
    await _stopScan();

    // Listen for devices (only T&D devices)
    _scanSub = FlutterBluePlus.scanResults.listen((results) {
      devices.value = results.where((r) {
        return r.device.platformName.startsWith('TR') ||
            r.advertisementData.manufacturerData.containsKey(914);
      }).toList();
    });

    // Restart every 2 minutes to keep scan alive
    _restartTimer = Timer.periodic(Duration(minutes: 2), (_) {
      _restartScan();
    });

    await FlutterBluePlus.startScan(
      timeout: Duration(seconds: 30),
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