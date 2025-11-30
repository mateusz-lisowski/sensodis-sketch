import 'package:get/get.dart';
import '../models/sensor.dart';

class DashboardController extends GetxController {
  final sensors = <Sensor>[].obs;

  @override
  void onInit() {
    super.onInit();
    fetchSensors();
  }

  void fetchSensors() {
    // Mock data
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
      Sensor(
        id: '3',
        name: 'Office Area',
        temperature: 24.0,
        batteryLevel: 60,
        lastUpdated: DateTime.now().subtract(const Duration(minutes: 15)),
      ),
       Sensor(
        id: '4',
        name: 'Server Room',
        temperature: 18.0,
        humidity: 35.0,
        batteryLevel: 100,
        lastUpdated: DateTime.now().subtract(const Duration(minutes: 1)),
      ),
    ];
  }

  void refreshSensors() {
    // Simulate refresh
    fetchSensors();
  }
}
