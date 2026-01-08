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

  // Subscriptions for pages so updates (like backedUp flag changes) reflect in-place
  StreamSubscription<List<MeasureEntity>>? _historyPageSubscription;
  StreamSubscription<List<BackupLogEntity>>? _logsPageSubscription;

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
    _historyPageSubscription?.cancel();
    _logsPageSubscription?.cancel();
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

  void _resubscribeHistoryPage() {
    _historyPageSubscription?.cancel();
    final limit = history.isNotEmpty ? history.length : pageSize;
    _historyPageSubscription = _database.watchSensorHistoryPage(sensor.id, limit: limit).listen((page) {
      for (var m in page) {
        final idx = history.indexWhere((h) => h.id == m.id);
        if (idx >= 0) {
          // replace existing item to reflect updates (e.g., backedUp changes)
          history[idx] = m;
        } else {
          // If item is not present, insert it at the correct position
          final insertAt = page.indexOf(m);
          if (insertAt <= history.length) {
            history.insert(insertAt, m);
          }
        }
      }
    });
  }

  void _resubscribeLogsPage() {
    _logsPageSubscription?.cancel();
    final limit = backupLogs.isNotEmpty ? backupLogs.length : pageSize;
    _logsPageSubscription = _database.watchBackupLogsPage(sensor.id, limit: limit).listen((page) {
      for (var l in page) {
        final idx = backupLogs.indexWhere((b) => b.id == l.id);
        if (idx >= 0) {
          backupLogs[idx] = l;
        } else {
          final insertAt = page.indexOf(l);
          if (insertAt <= backupLogs.length) {
            backupLogs.insert(insertAt, l);
          }
        }
      }
    });
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

    // Subscribe to a watch window that covers all currently loaded history items so
    // updates (for example, the backedUp flag) are reflected in the list in-place
    _resubscribeHistoryPage();

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

    // Subscribe to a watch window that covers all currently loaded logs so updates
    // to existing items are reflected in the list in-place
    _resubscribeLogsPage();

    isLoadingLogs.value = false;
  }
}
