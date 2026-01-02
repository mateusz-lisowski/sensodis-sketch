import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart' as ble;
import 'package:get/get.dart';
import 'package:sensodis_sketch/utils/ble_decoder.dart';
import '../models/sensor.dart';
import '../services/ble_service.dart';
import '../database/app_database.dart';
import '../utils/dummy_sensors.dart';

enum SensorFilter { all, favorites }
enum SensorSort { none, favorites, temperatureAsc, temperatureDesc }

class DashboardController extends GetxController {
  final sensors = <Sensor>[].obs;
  final currentFilter = SensorFilter.all.obs;
  final currentSort = SensorSort.favorites.obs; // Default to favorites based on previous requirement, can be changed to none if desired
  
  final BleService _bleService = Get.find<BleService>();
  final AppDatabase _database = Get.find<AppDatabase>();

  // Note: Removed discoveredDevices since BleService now handles scanning automatically
  RxBool get isScanning => _bleService.isScanning;

  List<Sensor> get sortedAndFilteredSensors {
    List<Sensor> filtered;
    if (currentFilter.value == SensorFilter.favorites) {
      filtered = sensors.where((s) => s.isFavorite.value).toList();
    } else {
      filtered = sensors.toList();
    }

    filtered.sort((a, b) {
      switch (currentSort.value) {
        case SensorSort.favorites:
          if (a.isFavorite.value && !b.isFavorite.value) {
            return -1;
          } else if (!a.isFavorite.value && b.isFavorite.value) {
            return 1;
          }
          return a.name.value.compareTo(b.name.value);
        case SensorSort.temperatureAsc:
          // Sort by temperature ascending (coldest first)
          return a.temperature.value.compareTo(b.temperature.value);
        case SensorSort.temperatureDesc:
          // Sort by temperature descending (hottest first)
          return b.temperature.value.compareTo(a.temperature.value);
        case SensorSort.none:
        default:
          return a.name.value.compareTo(b.name.value);
      }
    });
    
    return filtered;
  }

  void setFilter(SensorFilter filter) {
    currentFilter.value = filter;
  }
  
  void setSort(SensorSort sort) {
    currentSort.value = sort;
  }

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

    if (savedSensors.isEmpty && kDebugMode) {
      await _addDummySensors();
    } else {
      for (var s in savedSensors) {
        sensors.add(Sensor(
          id: s.id,
          name: s.name,
          temperature: s.temperature,
          humidity: s.humidity,
          batteryLevel: s.batteryLevel,
          lastUpdated: s.lastUpdated,
          rssi: s.rssi,
          isFavorite: s.isFavorite,
        ));
      }
    }
  }

  Future<void> _addDummySensors() async {
    final dummySensors = getDummySensors();

    for (var s in dummySensors) {
      sensors.add(s);
      _saveSensorAndMeasure(s);
    }
  }

  void _updateExistingSensor(ble.ScanResult result) {
    final decodedData = decodeTr4AdvertisingPacket(result.advertisementData);

    if (decodedData != null) {
      final index = sensors.indexWhere((s) => s.id == decodedData.serialNumber);

      if (index != -1) {
        final sensor = sensors[index];

        // Only update if we have a newer advertisement frame
        if (!result.timeStamp.isAfter(sensor.lastUpdated.value)) {
          return;
        }

        // Update sensor with latest data
        sensor.temperature.value = decodedData.temperature;
        if (decodedData.humidity != null) {
          sensor.humidity.value = decodedData.humidity!;
        }
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
      if (decodedData.humidity != null) {
        sensor.humidity.value = decodedData.humidity!;
      }
      sensor.batteryLevel.value = (decodedData.batteryLevel / 5.0 * 100).round();
      sensor.lastUpdated.value = result.timeStamp;
      sensor.rssi.value = result.rssi;

      _saveSensorAndMeasure(sensor);
    } else {
      // Add new sensor
      final newSensor = Sensor(
        id: decodedData.serialNumber,
        name: deviceName,
        temperature: decodedData.temperature,
        humidity: decodedData.humidity,
        batteryLevel: (decodedData.batteryLevel / 5.0 * 100).round(),
        lastUpdated: result.timeStamp,
        rssi: result.rssi,
      );

      sensors.add(newSensor);
      _saveSensorAndMeasure(newSensor);
    }
  }

  Future<void> deleteSensor(Sensor sensor) async {
    await _database.deleteSensor(sensor.id);
    sensors.remove(sensor);
  }

  void toggleFavorite(Sensor sensor) {
    sensor.isFavorite.toggle();
    _saveSensorAndMeasure(sensor);
    // Force refresh the list to re-sort/filter
    sensors.refresh();
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
      isFavorite: sensor.isFavorite.value,
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
