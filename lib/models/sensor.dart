class Sensor {
  final String id;
  final String name;
  final double temperature;
  final double? humidity;
  final int batteryLevel;
  final DateTime lastUpdated;

  Sensor({
    required this.id,
    required this.name,
    required this.temperature,
    this.humidity,
    required this.batteryLevel,
    required this.lastUpdated,
  });
}
