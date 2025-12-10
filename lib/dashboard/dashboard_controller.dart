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

  // List to hold unique discovered devices
  final discoveredDevices = <ScanResult>[].obs;

  // Expose scanning state from the service
  RxBool get isScanning => _bleService.isScanning;

  // Track the timestamp of the last processed packet for each sensor to avoid duplicate logs
  final Map<String, DateTime> _lastLogTimestamps = {};

  @override
  void onInit() {
    super.onInit();
    fetchSensors();
    
    // Listen to scan results from the service to update existing sensors and discovered devices list
    ever(_bleService.scanResults, (List<ScanResult> results) {
      for (var result in results) {
        _updateExistingSensor(result);
        _updateDiscoveredDevices(result);
      }
    });

    // Start scanning via the service
    _bleService.startScan();
  }

  @override
  void onClose() {
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
    discoveredDevices.clear();
  }
  
  /// Wrapper to start scanning from UI
  Future<void> startScan() async {
    discoveredDevices.clear();
    await _bleService.startScan();
  }

  /// Wrapper to stop scanning from UI
  Future<void> stopScan() async {
    await _bleService.stopScan();
  }

  /// Updates the list of discovered devices with the latest scan result
  void _updateDiscoveredDevices(ScanResult result) {
    final index = discoveredDevices.indexWhere((r) => r.device.remoteId == result.device.remoteId);
    if (index != -1) {
      discoveredDevices[index] = result;
    } else {
      discoveredDevices.add(result);
    }
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
