import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:get/get.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/sensor.dart';

class DashboardController extends GetxController {
  final sensors = <Sensor>[].obs;
  final scanResults = <ScanResult>[].obs;
  final isScanning = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchSensors();
  }

  void fetchSensors() {
    // Mock data - keep existing ones
    sensors.value = [
      Sensor(
        id: '1',
        name: 'Warehouse A',
        temperature: 22.5,
        humidity: 45.0,
        batteryLevel: 85,
        lastUpdated: DateTime.now().subtract(const Duration(minutes: 5)),
      ),
      Sensor(
        id: '2',
        name: 'Cold Storage',
        temperature: -4.0,
        humidity: 30.0,
        batteryLevel: 92,
        lastUpdated: DateTime.now().subtract(const Duration(minutes: 2)),
      ),
    ];
  }

  void refreshSensors() {
    // Simulate refresh
    // In a real app, this would re-fetch data from API or BLE
    fetchSensors();
  }

  Future<void> startScan() async {
    // Request permissions first
    if (await Permission.bluetoothScan.request().isGranted &&
        await Permission.bluetoothConnect.request().isGranted &&
        await Permission.location.request().isGranted) {
      
      // Check if Bluetooth is enabled
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
      
      // Wait for Bluetooth to actually turn on if it was off
      if (await FlutterBluePlus.adapterState.first != BluetoothAdapterState.on) {
        // Give it a moment or user denied
        return; 
      }

      isScanning.value = true;
      scanResults.clear();

      // Listen to scan results
      FlutterBluePlus.scanResults.listen((results) {
        scanResults.value = results;
      });

      // Start scanning
      await FlutterBluePlus.startScan(timeout: const Duration(seconds: 4));
      
      // Stop scanning after timeout
      await Future.delayed(const Duration(seconds: 4));
      await FlutterBluePlus.stopScan();
      isScanning.value = false;
    } else {
       Get.snackbar('Error', 'Bluetooth permissions are required to scan for devices');
       openAppSettings();
    }
  }

  void addDevice(ScanResult result) {
    // In a real app, you would connect to the device and read characteristics
    // Here we just add it as a mock sensor to the list
    final deviceName = result.device.platformName.isNotEmpty 
        ? result.device.platformName 
        : 'Unknown Device (${result.device.remoteId.toString().substring(0, 4)})';
        
    final newSensor = Sensor(
      id: result.device.remoteId.toString(),
      name: deviceName,
      temperature: 20.0, // Default/Placeholder value
      batteryLevel: 100, // Default/Placeholder value
      lastUpdated: DateTime.now(),
    );
    
    // Check if already exists
    if (!sensors.any((s) => s.id == newSensor.id)) {
      sensors.add(newSensor);
      Get.snackbar('Success', 'device_added'.tr);
    }
  }
}
