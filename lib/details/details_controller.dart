import 'dart:async';
import 'package:get/get.dart';
import '../database/app_database.dart';
import '../models/sensor.dart';

class DetailsController extends GetxController {
  final Sensor sensor;
  final AppDatabase _database = Get.find<AppDatabase>();

  final currentTab = 0.obs;
  final history = <MeasureEntity>[].obs;
  final backupLogs = <BackupLogEntity>[].obs;

  StreamSubscription<List<MeasureEntity>>? _historySubscription;
  StreamSubscription<List<BackupLogEntity>>? _backupLogsSubscription;

  DetailsController({required this.sensor});

  @override
  void onInit() {
    super.onInit();
    _historySubscription = _database.getSensorHistory(sensor.id).listen((data) {
      history.assignAll(data);
    });
    _backupLogsSubscription = _database.watchBackupLogs(sensor.id).listen((logs) {
      backupLogs.assignAll(logs);
    });
  }

  @override
  void onClose() {
    _historySubscription?.cancel();
    _backupLogsSubscription?.cancel();
    super.onClose();
  }

  void changeTab(int index) {
    currentTab.value = index;
  }

  void toggleFavorite() {
    sensor.isFavorite.toggle();
  }
}
