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

  // Pagination state
  static const int pageSize = 50;
  int _historyPage = 0;
  int _logsPage = 0;

  final isLoadingHistory = false.obs;
  final hasMoreHistory = true.obs;

  final isLoadingLogs = false.obs;
  final hasMoreLogs = true.obs;

  // Initialization flags to ensure the first page is loaded once when the tab is opened
  bool _historyInitialized = false;
  bool _logsInitialized = false;

  StreamSubscription<MeasureEntity?>? _latestMeasureSubscription;
  StreamSubscription<BackupLogEntity?>? _latestLogSubscription;

  DetailsController({required this.sensor});

  @override
  void onInit() {
    super.onInit();
    // Listen for newly inserted items and prepend them so the UI stays up-to-date
    _latestMeasureSubscription = _database.watchLatestMeasureForSensor(sensor.id).listen((measure) {
      if (measure == null) return;
      if (history.isEmpty || measure.timestamp.isAfter(history.first.timestamp)) {
        if (!history.any((m) => m.id == measure.id)) {
          history.insert(0, measure);
        }
      }
    });

    _latestLogSubscription = _database.watchLatestBackupLogForSensor(sensor.id).listen((log) {
      if (log == null) return;
      if (backupLogs.isEmpty || log.timestamp.isAfter(backupLogs.first.timestamp)) {
        if (!backupLogs.any((l) => l.id == log.id)) {
          backupLogs.insert(0, log);
        }
      }
    });

    // If the page opens with History or Logs selected, ensure we load the initial page once
    if (currentTab.value == 1 && !_historyInitialized) {
      _historyInitialized = true;
      loadInitialHistory();
    } else if (currentTab.value == 2 && !_logsInitialized) {
      _logsInitialized = true;
      loadInitialLogs();
    }
  }

  @override
  void onClose() {
    _latestMeasureSubscription?.cancel();
    _latestLogSubscription?.cancel();
    super.onClose();
  }

  void changeTab(int index) {
    currentTab.value = index;
    if (index == 1 && !_historyInitialized) {
      _historyInitialized = true;
      loadInitialHistory();
    } else if (index == 2 && !_logsInitialized) {
      _logsInitialized = true;
      loadInitialLogs();
    }
  }

  void toggleFavorite() {
    sensor.isFavorite.toggle();
  }

  Future<void> loadInitialHistory() async {
    _historyPage = 0;
    hasMoreHistory.value = true;
    // Do NOT clear history to preserve any item added by "latest item" subscription
    await loadMoreHistory();
  }

  Future<void> loadMoreHistory() async {
    if (isLoadingHistory.value || !hasMoreHistory.value) return;
    isLoadingHistory.value = true;

    final offset = _historyPage * pageSize;
    final page = await _database.getSensorHistoryPage(sensor.id, limit: pageSize, offset: offset);

    if (page.isEmpty) {
      hasMoreHistory.value = false;
    } else {
      final newItems = page.where((m) => !history.any((h) => h.id == m.id)).toList();
      history.addAll(newItems);
      if (page.length < pageSize) {
        hasMoreHistory.value = false;
      } else {
        _historyPage++;
      }
    }

    isLoadingHistory.value = false;
  }

  Future<void> loadInitialLogs() async {
    _logsPage = 0;
    hasMoreLogs.value = true;
    // Do NOT clear backupLogs to preserve any item added by "latest item" subscription
    await loadMoreLogs();
  }

  Future<void> loadMoreLogs() async {
    if (isLoadingLogs.value || !hasMoreLogs.value) return;
    isLoadingLogs.value = true;

    final offset = _logsPage * pageSize;
    final page = await _database.getBackupLogsPage(sensor.id, limit: pageSize, offset: offset);

    if (page.isEmpty) {
      hasMoreLogs.value = false;
    } else {
      final newItems = page.where((m) => !backupLogs.any((h) => h.id == m.id)).toList();
      backupLogs.addAll(newItems);
      if (page.length < pageSize) {
        hasMoreLogs.value = false;
      } else {
        _logsPage++;
      }
    }

    isLoadingLogs.value = false;
  }
}
