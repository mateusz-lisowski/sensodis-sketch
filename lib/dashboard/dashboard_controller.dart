import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/sensor.dart';

/// Decoded data from a T&D advertising packet.
class _TR4SensorData {
  final double temperature;
  final String serialNumber;
  final int batteryLevel;

  _TR4SensorData({
    required this.temperature,
    required this.serialNumber,
    required this.batteryLevel,
  });
}

class DashboardController extends GetxController {
  final sensors = <Sensor>[].obs;
  final scanResults = <ScanResult>[].obs;
  final isScanning = false.obs;
  StreamSubscription<List<ScanResult>>? _scanSubscription;

  @override
  void onInit() {
    super.onInit();
    fetchSensors();
    // Start scanning immediately to receive updates for existing sensors
    startScan();
  }

  @override
  void onClose() {
    _scanSubscription?.cancel();
    FlutterBluePlus.stopScan();
    super.onClose();
  }

  /// Clears any existing sensors from the list.
  void fetchSensors() {
    sensors.clear();
  }

  /// Clears the sensor list. User can re-scan to populate it.
  void refreshSensors() {
    sensors.clear();
  }

  /// Decodes the manufacturer-specific data from a T&D advertising packet.
  _TR4SensorData? _decodeTr4AdvertisingPacket(AdvertisementData data) {
    // T&D Corporation's Bluetooth Company ID is 0x0392 (914).
    const tndCompanyId = 914;
    final manufacturerData = data.manufacturerData;

    if (manufacturerData.containsKey(tndCompanyId)) {
      final tndData = manufacturerData[tndCompanyId]!;
      // The TR4 advertising packet payload is 18 bytes.
      if (tndData.length == 18) {
        try {
          final byteData = ByteData.sublistView(Uint8List.fromList(tndData));
          
          // <I: Device Serial Number (4B, LE) at offset 0
          final serialNumberRaw = byteData.getUint32(0, Endian.little);
          // B: Status Code 2 (1B) -> battery level [1, 5] at offset 7
          final batteryLevelRaw = byteData.getUint8(7);
          // <H: Measurement Reading 1 / Raw Temp (2B, LE) at offset 8
          final rawTemp = byteData.getUint16(8, Endian.little);

          // Convert raw temperature to Celsius
          final temperature = (rawTemp - 1000) / 10.0;
          // Format serial number as a hex string
          final serialNumber =
              serialNumberRaw.toRadixString(16).toUpperCase().padLeft(8, '0');

          return _TR4SensorData(
            temperature: temperature,
            serialNumber: serialNumber,
            batteryLevel: batteryLevelRaw,
          );
        } catch (e) {
          print("Error decoding T&D packet: $e");
          return null;
        }
      }
    }
    return null;
  }

  Future<void> startScan() async {
    // Avoid restarting scan if already active
    if (isScanning.value) return;

    // Request necessary Bluetooth permissions
    if (await Permission.bluetoothScan.request().isGranted &&
        await Permission.bluetoothConnect.request().isGranted &&
        await Permission.location.request().isGranted) {
      
      // Check if Location Services are enabled
      if (await Permission.location.serviceStatus != ServiceStatus.enabled) {
        Get.snackbar('Location Required', 'Please enable Location Services to scan for devices');
        return;
      }
      
      // Check if Bluetooth is enabled and turn it on if needed
      if (await FlutterBluePlus.adapterState.first != BluetoothAdapterState.on) {
        if (GetPlatform.isAndroid) {
          try {
            await FlutterBluePlus.turnOn();
          } catch (e) {
            Get.snackbar('Error', 'Could not enable Bluetooth');
            return;
          }
        } else {
          Get.snackbar('Bluetooth Required', 'Please enable Bluetooth to scan for devices');
          return;
        }
      }
      
      // Wait for adapter state to be 'on'
      await FlutterBluePlus.adapterState.where((s) => s == BluetoothAdapterState.on).first;

      isScanning.value = true;
      scanResults.clear();

      // Listen to scan results and filter for T&D devices
      await _scanSubscription?.cancel();
      _scanSubscription = FlutterBluePlus.scanResults.listen((results) {
        final filteredResults = results
            .where((r) => r.device.platformName.startsWith('TR'))
            .toList();
        
        scanResults.value = filteredResults;

        // Update existing sensors if their data is found in the scan results
        for (var result in filteredResults) {
          _updateExistingSensor(result);
        }
      });

      // Start scanning indefinitely.
      await FlutterBluePlus.startScan();
    } else {
       Get.snackbar('Error', 'Bluetooth permissions are required to scan for devices');
       openAppSettings();
    }
  }

  /// Stops the continuous BLE scan.
  Future<void> stopScan() async {
    isScanning.value = false;
    await _scanSubscription?.cancel();
    _scanSubscription = null;
    await FlutterBluePlus.stopScan();
  }

  /// Silently updates an existing sensor if found in the scan result.
  void _updateExistingSensor(ScanResult result) {
    final decodedData = _decodeTr4AdvertisingPacket(result.advertisementData);

    if (decodedData != null) {
      final index = sensors.indexWhere((s) => s.id == decodedData.serialNumber);
      if (index != -1) {
        final currentSensor = sensors[index];
        // Create a new sensor object with updated values
        final updatedSensor = Sensor(
          id: currentSensor.id,
          name: currentSensor.name, // Keep the existing name
          temperature: decodedData.temperature,
          humidity: currentSensor.humidity,
          batteryLevel: (decodedData.batteryLevel / 5.0 * 100).round(),
          lastUpdated: DateTime.now(),
        );
        sensors[index] = updatedSensor;
      }
    }
  }

  /// Adds a new sensor from a scan result or updates an existing one via UI.
  void addDevice(ScanResult result) {
    final decodedData = _decodeTr4AdvertisingPacket(result.advertisementData);

    if (decodedData != null) {
      final deviceName = result.device.platformName.isNotEmpty 
          ? result.device.platformName 
          : 'T&D Sensor';
      
      final newSensor = Sensor(
        id: decodedData.serialNumber, // Use serial number as the unique ID
        name: deviceName,
        temperature: decodedData.temperature,
        // Convert battery level from 1-5 scale to percentage
        batteryLevel: (decodedData.batteryLevel / 5.0 * 100).round(),
        lastUpdated: DateTime.now(),
      );
      
      // If a sensor with the same ID exists, update it; otherwise, add a new one.
      final existingIndex = sensors.indexWhere((s) => s.id == newSensor.id);
      if (existingIndex != -1) {
        sensors[existingIndex] = newSensor;
        Get.snackbar('Success', 'sensor_updated'.tr);
      } else {
        sensors.add(newSensor);
        Get.snackbar('Success', 'device_added'.tr);
      }
    } else {
      // Notify user if data from a 'TR' device can't be decoded
      Get.snackbar('Error', 'Could not read data from this device.');
    }
  }
}
