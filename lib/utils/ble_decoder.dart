import 'dart:typed_data';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'app_constants.dart';

/// Decoded data from a T&D advertising packet.
class TR4SensorData {
  final double temperature;
  final double? humidity;
  final String serialNumber;
  final int batteryLevel;

  TR4SensorData({
    required this.temperature,
    this.humidity,
    required this.serialNumber,
    required this.batteryLevel,
  });
}

/// Decodes the manufacturer-specific data from a T&D advertising packet.
TR4SensorData? decodeTr4AdvertisingPacket(AdvertisementData data) {
  // T&D Corporation's Bluetooth Company ID
  final manufacturerData = data.manufacturerData;

  if (manufacturerData.containsKey(AppConstants.tndCompanyId)) {
    final tndData = manufacturerData[AppConstants.tndCompanyId]!;
    // The TR4 advertising packet payload is 18 bytes.
    if (tndData.length == 18) {
      try {
        final byteData = ByteData.sublistView(Uint8List.fromList(tndData));
        
        // <I: Device Serial Number (4B, LE) at offset 0
        final serialNumberRaw = byteData.getUint32(0, Endian.little);
        // B: Status Code 2 (1B) -> battery level [1, 5] at offset 7
        final batteryLevelRaw = byteData.getUint8(7);
        // <h: Measurement Reading 1 / Raw Temp (2B, LE) at offset 8
        final rawTemp = byteData.getInt16(8, Endian.little);
        // <h: Measurement Reading 2 / Raw Humidity (2B, LE) at offset 10
        final rawHumidity = byteData.getInt16(10, Endian.little);

        // Convert raw temperature to Celsius
        final temperature = (rawTemp - 1000) / 10.0;
        // Convert raw humidity to % if valid, otherwise null
        // We assume that a non-positive value indicates no humidity sensor.
        var tempHumidity = (rawHumidity - 1000) / 10.0;
        final humidity = tempHumidity > 0 ? tempHumidity : null;
        // Format serial number as a hex string
        final serialNumber =
            serialNumberRaw.toRadixString(16).toUpperCase().padLeft(8, '0');

        return TR4SensorData(
          temperature: temperature,
          humidity: humidity,
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
