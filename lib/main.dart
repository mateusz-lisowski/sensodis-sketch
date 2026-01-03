import 'dart:io';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sensodis_sketch/services/backup_service.dart';
import 'package:sensodis_sketch/services/settings_service.dart';
import 'package:sensodis_sketch/utils/http_overrides.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'database/app_database.dart';
import 'dashboard/dashboard_page.dart';
import 'messages.dart';
import 'services/ble_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  HttpOverrides.global = MyHttpOverrides();

  // Initialize services
  await Get.putAsync(() => SettingsService().init());
  Get.put(AppDatabase());
  Get.put(BleService());
  Get.put(BackupService());

  // Keep the screen on.
  WakelockPlus.enable();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      translations: Messages(),
      locale: const Locale('en', 'US'),
      fallbackLocale: const Locale('en', 'US'),
      title: 'Sensodis',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF1E1E1E),
          primary: const Color(0xFF1E1E1E),
          secondary: Colors.red,
          surface: Colors.white,
        ),
        scaffoldBackgroundColor: Colors.white,
        useMaterial3: true,
      ),
      home: DashboardPage(),
    );
  }
}
