import 'package:get/get.dart';

class Sensor {
  final String id;
  final RxString name;
  final RxDouble temperature;
  final RxnDouble humidity;
  final RxInt batteryLevel;
  final Rx<DateTime> lastUpdated;
  final RxInt rssi;
  final RxBool isFavorite;

  Sensor({
    required this.id,
    required String name,
    required double temperature,
    double? humidity,
    required int batteryLevel,
    required DateTime lastUpdated,
    required int rssi,
    bool isFavorite = false,
  })  : name = name.obs,
        temperature = temperature.obs,
        humidity = RxnDouble(humidity),
        batteryLevel = batteryLevel.obs,
        lastUpdated = lastUpdated.obs,
        rssi = rssi.obs,
        isFavorite = isFavorite.obs;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Sensor && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
