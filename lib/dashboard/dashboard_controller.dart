import 'dart:async';
import 'package:flutter_blue_plus/flutter_blue_plus.dart' as ble;
import 'package:get/get.dart';
import 'package:sensodis_sketch/utils/ble_decoder.dart';
import '../models/sensor.dart';
import '../services/ble_service.dart';
import '../database/app_database.dart';

class DashboardController extends GetxController {
  final sensors = <Sensor>[].obs;
  final BleService _bleService = Get.find<BleService>();
  final AppDatabase _database = Get.find<AppDatabase>();

  // Note: Removed discoveredDevices since BleService now handles scanning automatically
  RxBool get isScanning => _bleService.isScanning;

  @override
  void onInit() {
    super.onInit();
    _loadSavedSensors();
    _setupScanListener();
  }

  void _setupScanListener() {
    // Listen to the BleService's scan results
    ever(_bleService.devices, (List<ble.ScanResult> results) {
      for (var result in results) {
        _updateExistingSensor(result);
      }
    });
  }

  Future<void> _loadSavedSensors() async {
    sensors.clear();
    final savedSensors = await _database.getAllSensors();

    for (var s in savedSensors) {
      sensors.add(Sensor(
        id: s.id,
        name: s.name,
        temperature: s.temperature,
        humidity: s.humidity,
        batteryLevel: s.batteryLevel,
        lastUpdated: s.lastUpdated,
        rssi: s.rssi,
      ));
    }
  }

  void _updateExistingSensor(ble.ScanResult result) {
    final decodedData = decodeTr4AdvertisingPacket(result.advertisementData);

    if (decodedData != null) {
      final index = sensors.indexWhere((s) => s.id == decodedData.serialNumber);

      if (index != -1) {
        final sensor = sensors[index];

        // Update sensor with latest data
        sensor.temperature.value = decodedData.temperature;
        sensor.batteryLevel.value = (decodedData.batteryLevel / 5.0 * 100).round();
        sensor.lastUpdated.value = result.timeStamp;
        sensor.rssi.value = result.rssi;

        // Save to database
        _saveSensorAndMeasure(sensor);
      }
    }
  }

  void addDevice(ble.ScanResult result) {
    final decodedData = decodeTr4AdvertisingPacket(result.advertisementData);

    if (decodedData == null) {
      Get.snackbar('Error', 'Could not read data from this device.');
      return;
    }

    final deviceName = result.device.platformName.isNotEmpty
        ? result.device.platformName
        : 'T&D Sensor';

    // Check if sensor already exists
    final existingIndex = sensors.indexWhere((s) => s.id == decodedData.serialNumber);

    if (existingIndex != -1) {
      // Update existing sensor
      final sensor = sensors[existingIndex];
      sensor.name.value = deviceName;
      sensor.temperature.value = decodedData.temperature;
      sensor.batteryLevel.value = (decodedData.batteryLevel / 5.0 * 100).round();
      sensor.lastUpdated.value = result.timeStamp;
      sensor.rssi.value = result.rssi;

      _saveSensorAndMeasure(sensor);
      Get.snackbar('Success', 'sensor_updated'.tr);
    } else {
      // Add new sensor
      final newSensor = Sensor(
        id: decodedData.serialNumber,
        name: deviceName,
        temperature: decodedData.temperature,
        batteryLevel: (decodedData.batteryLevel / 5.0 * 100).round(),
        lastUpdated: result.timeStamp,
        rssi: result.rssi,
      );

      sensors.add(newSensor);
      _saveSensorAndMeasure(newSensor);
      Get.snackbar('Success', 'device_added'.tr);
    }
  }

  void _saveSensorAndMeasure(Sensor sensor) {
    // Save sensor to database
    _database.insertSensor(SensorEntity(
      id: sensor.id,
      name: sensor.name.value,
      temperature: sensor.temperature.value,
      humidity: sensor.humidity.value,
      batteryLevel: sensor.batteryLevel.value,
      lastUpdated: sensor.lastUpdated.value,
      rssi: sensor.rssi.value,
    ));

    // Add measurement to database
    _database.addMeasure(
      sensor.id,
      sensor.temperature.value,
      sensor.humidity.value,
      sensor.batteryLevel.value,
      sensor.lastUpdated.value,
      sensor.rssi.value,
    );
  }

  bool isSensorAdded(String deviceId) {
    return sensors.any((s) => s.id == deviceId);
  }

  // Simple refresh method to reload sensors from database
  Future<void> refreshSensors() async {
    await _loadSavedSensors();
  }
}