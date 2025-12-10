import 'package:flutter/material.dart';

class SensorStatusColors {
  static Color getTemperatureColor(double temp) {
    if (temp < 0) return Colors.blue;
    if (temp > 25) return Colors.orange;
    if (temp > 30) return Colors.red;
    return Colors.green;
  }

  static Color getBatteryColor(int level) {
    if (level < 20) return Colors.red;
    if (level < 50) return Colors.orange;
    return Colors.green;
  }

  static Color getRssiColor(int rssi) {
    if (rssi > -60) return Colors.green;
    if (rssi > -80) return Colors.orange;
    return Colors.red;
  }
}
