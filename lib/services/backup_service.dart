import 'dart:async';
import 'dart:convert';
import 'dart:developer';

import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import '../database/app_database.dart';
import '../services/settings_service.dart';

class BackupService extends GetxService {
  final AppDatabase _database = Get.find<AppDatabase>();
  final SettingsService _settingsService = Get.find<SettingsService>();
  Timer? _timer;

  void start() {
    _timer?.cancel();
    _timer = Timer.periodic(Duration(minutes: _settingsService.backupInterval.value), (timer) {
      _backupData();
    });
  }

  void stop() {
    _timer?.cancel();
  }

  Future<void> _backupData() async {
    final sensorsToBackup = await _getSensorsToBackup();

    for (final sensor in sensorsToBackup) {
      final lastMeasurement = await _database.getLastMeasureForSensor(sensor.id);
      if (lastMeasurement != null && !lastMeasurement.backedUp) {
        await _sendMeasurement(sensor, lastMeasurement);
      }
    }
  }

  Future<List<SensorEntity>> _getSensorsToBackup() {
    if (_settingsService.backupFavoritesOnly.value) {
      return _database.getFavoriteSensors();
    }
    return _database.getAllSensors();
  }

  Future<void> _sendMeasurement(SensorEntity sensor, MeasureEntity measurement) async {
    final url = _settingsService.endpointUrl.value;

    final objectJSON = <String, dynamic>{
      'temperature': measurement.temperature,
    };
    if (measurement.humidity != null) {
      objectJSON['humidity'] = measurement.humidity;
    }

    final body = {
      "applicationID": 1,
      "applicationName": "BLE_1.0",
      "devEUI": sensor.id,
      "battery": measurement.batteryLevel,
      "data": measurement.rawData,
      "deviceName": sensor.name,
      "objectJSON": objectJSON,
      "rxInfo": [
        {
          "rssi": measurement.rssi,
          "time": measurement.timestamp.toIso8601String(),
        }
      ]
    };

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      await _database.addBackupLog(
        sensorId: sensor.id,
        timestamp: DateTime.now(),
        statusCode: response.statusCode,
        response: response.body,
      );

      if (response.statusCode == 200) {
        log('Successfully backed up measurement for sensor ${sensor.id}');
        await _database.updateMeasureBackedUp(measurement.id, true);
      } else {
        log('Failed to backup measurement for sensor ${sensor.id}. Status code: ${response.statusCode}');
      }
    } catch (e) {
      log('Error backing up measurement for sensor ${sensor.id}: $e');
      await _database.addBackupLog(
        sensorId: sensor.id,
        timestamp: DateTime.now(),
        statusCode: -1,
        response: e.toString(),
      );
    }
  }

  @override
  void onInit() {
    super.onInit();
    // Start the backup service when the app starts
    start();
    // Listen for changes in settings and restart the timer if needed
    ever(_settingsService.backupInterval, (_) => start());
  }

  @override
  void onClose() {
    stop();
    super.onClose();
  }
}
