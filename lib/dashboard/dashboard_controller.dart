import 'dart:async';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:get/get.dart';
import 'package:sensodis_sketch/utils/ble_decoder.dart';
import '../models/sensor.dart';
import '../services/ble_service.dart';

class DashboardController extends GetxController {
  final sensors = <Sensor>[].obs;
  // Access the shared BleService
  final BleService _bleService = Get.find<BleService>();

  // Expose scan results and scanning state from the service
  RxList<ScanResult> get scanResults => _bleService.scanResults;
  RxBool get isScanning => _bleService.isScanning;

  // Track the timestamp of the last processed packet for each sensor to avoid duplicate logs
  final Map<String, DateTime> _lastLogTimestamps = {};

  @override
  void onInit() {
    super.onInit();
    fetchSensors();
    
    // Listen to scan results from the service to update existing sensors
    ever(_bleService.scanResults, (List<ScanResult> results) {
      for (var result in results) {
        _updateExistingSensor(result);
      }
    });

    // Start scanning via the service
    _bleService.startScan();
  }

  @override
  void onClose() {
    // We don't stop the scan here because the service might be used elsewhere,
    // or we might want to keep scanning in the background if the service allows.
    // However, if this controller is the only consumer, we might want to stop it.
    // For now, let's leave the service running or handle its lifecycle separately.
    // If we want to stop scanning when leaving the dashboard:
    // _bleService.stopScan(); 
    super.onClose();
  }

  /// Clears any existing sensors from the list.
  void fetchSensors() {
    sensors.clear();
    _lastLogTimestamps.clear();
  }

  /// Clears the sensor list. User can re-scan to populate it.
  void refreshSensors() {
    sensors.clear();
    _lastLogTimestamps.clear();
  }
  
  /// Wrapper to start scanning from UI
  Future<void> startScan() async {
    await _bleService.startScan();
  }

  /// Wrapper to stop scanning from UI
  Future<void> stopScan() async {
    await _bleService.stopScan();
  }

  /// Silently updates an existing sensor if found in the scan result.
  void _updateExistingSensor(ScanResult result) {
    final decodedData = decodeTr4AdvertisingPacket(result.advertisementData);

    if (decodedData != null) {
      // Log packet if it is new
      if (_lastLogTimestamps[decodedData.serialNumber] != result.timeStamp) {
        _lastLogTimestamps[decodedData.serialNumber] = result.timeStamp;
        print('TR4 Packet: Serial=${decodedData.serialNumber}, Temp=${decodedData.temperature}, Battery=${decodedData.batteryLevel}, RSSI=${result.rssi}, Time=${result.timeStamp}');
      }

      final index = sensors.indexWhere((s) => s.id == decodedData.serialNumber);
      if (index != -1) {
        final sensor = sensors[index];
        sensor.temperature.value = decodedData.temperature;
        sensor.batteryLevel.value = (decodedData.batteryLevel / 5.0 * 100).round();
        sensor.lastUpdated.value = result.timeStamp;
        sensor.rssi.value = result.rssi;
        
        // Force refresh to ensure UI updates even if values haven't changed
        // This addresses the issue where the UI might not reflect the latest packet reception
        sensor.temperature.refresh();
        sensor.batteryLevel.refresh();
        sensor.lastUpdated.refresh();
        sensor.rssi.refresh();
      }
    }
  }

  /// Adds a new sensor from a scan result or updates an existing one via UI.
  void addDevice(ScanResult result) {
    final decodedData = decodeTr4AdvertisingPacket(result.advertisementData);

    if (decodedData != null) {
      final deviceName = result.device.platformName.isNotEmpty
          ? result.device.platformName
          : 'T&D Sensor';

      final existingIndex =
          sensors.indexWhere((s) => s.id == decodedData.serialNumber);
      if (existingIndex != -1) {
        final sensor = sensors[existingIndex];
        sensor.name.value = deviceName;
        sensor.temperature.value = decodedData.temperature;
        sensor.batteryLevel.value =
            (decodedData.batteryLevel / 5.0 * 100).round();
        sensor.lastUpdated.value = result.timeStamp;
        sensor.rssi.value = result.rssi;
        
        // Force refresh
        sensor.temperature.refresh();
        sensor.batteryLevel.refresh();
        sensor.lastUpdated.refresh();
        sensor.rssi.refresh();
        
        Get.snackbar('Success', 'sensor_updated'.tr);
      } else {
        final newSensor = Sensor(
          id: decodedData.serialNumber,
          name: deviceName,
          temperature: decodedData.temperature,
          batteryLevel: (decodedData.batteryLevel / 5.0 * 100).round(),
          lastUpdated: result.timeStamp,
          rssi: result.rssi,
        );
        sensors.add(newSensor);
        Get.snackbar('Success', 'device_added'.tr);
      }
    } else {
      Get.snackbar('Error', 'Could not read data from this device.');
    }
  }
}
