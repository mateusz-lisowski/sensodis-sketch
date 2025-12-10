import 'dart:async';
import 'package:get/get.dart';
import '../database/app_database.dart';

class DetailsController extends GetxController {
  final String sensorId;
  final AppDatabase _database = Get.find<AppDatabase>();
  
  final currentTab = 0.obs;
  final history = <MeasureEntity>[].obs;
  final isLoading = true.obs;
  
  // Timer to periodically refresh history
  Timer? _refreshTimer;

  DetailsController({required this.sensorId});

  @override
  void onInit() {
    super.onInit();
    fetchHistory();
    // Refresh history every 5 seconds to show real-time updates
    _refreshTimer = Timer.periodic(const Duration(seconds: 5), (_) => fetchHistory());
  }
  
  @override
  void onClose() {
    _refreshTimer?.cancel();
    super.onClose();
  }

  void changeTab(int index) {
    currentTab.value = index;
    if (index == 1) {
      fetchHistory();
    }
  }

  Future<void> fetchHistory() async {
    // Don't show loading indicator on periodic refresh
    if (history.isEmpty) isLoading.value = true;
    
    try {
      final data = await _database.getSensorHistory(sensorId);
      history.assignAll(data);
    } finally {
      isLoading.value = false;
    }
  }
}
