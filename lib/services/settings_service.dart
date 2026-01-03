import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsService extends GetxService {
  late SharedPreferences _prefs;

  // Keys
  static const String keyEndpointUrl = 'endpointUrl';
  static const String keyBackupInterval = 'backupInterval';
  static const String keyBackupFavoritesOnly = 'backupFavoritesOnly';

  // Reactive properties with default values
  final endpointUrl = 'https://test.sensodis.com/app/service/bluetooth/'.obs;
  final backupInterval = 1.obs; // in minutes
  final backupFavoritesOnly = false.obs;

  Future<SettingsService> init() async {
    _prefs = await SharedPreferences.getInstance();
    _loadSettings();
    return this;
  }

  void _loadSettings() {
    endpointUrl.value = _prefs.getString(keyEndpointUrl) ?? endpointUrl.value;
    backupInterval.value = _prefs.getInt(keyBackupInterval) ?? backupInterval.value;
    backupFavoritesOnly.value = _prefs.getBool(keyBackupFavoritesOnly) ?? backupFavoritesOnly.value;
  }

  void setEndpointUrl(String url) {
    endpointUrl.value = url;
    _prefs.setString(keyEndpointUrl, url);
  }

  void setBackupInterval(int interval) {
    backupInterval.value = interval;
    _prefs.setInt(keyBackupInterval, interval);
  }

  void setBackupFavoritesOnly(bool value) {
    backupFavoritesOnly.value = value;
    _prefs.setBool(keyBackupFavoritesOnly, value);
  }
}
