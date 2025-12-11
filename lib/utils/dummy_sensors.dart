import '../models/sensor.dart';

List<Sensor> getDummySensors() {
  return [
    Sensor(
      id: 'DUMMY_001',
      name: 'Living Room',
      temperature: 22.5,
      humidity: 45.0,
      batteryLevel: 85,
      lastUpdated: DateTime.now().subtract(const Duration(minutes: 5)),
      rssi: -65,
      isFavorite: true,
    ),
    Sensor(
      id: 'DUMMY_002',
      name: 'Kitchen',
      temperature: 24.1,
      humidity: 50.2,
      batteryLevel: 60,
      lastUpdated: DateTime.now().subtract(const Duration(minutes: 15)),
      rssi: -72,
      isFavorite: false,
    ),
    Sensor(
      id: 'DUMMY_003',
      name: 'Bedroom',
      temperature: 19.8,
      humidity: 40.5,
      batteryLevel: 92,
      lastUpdated: DateTime.now().subtract(const Duration(hours: 1)),
      rssi: -58,
      isFavorite: false,
    ),
  ];
}
