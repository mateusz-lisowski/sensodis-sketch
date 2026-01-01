import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:wakelock_plus/wakelock_plus.dart';
import 'database/app_database.dart';
import 'dashboard/dashboard_page.dart';
import 'messages.dart';
import 'services/ble_service.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Initialize services
  Get.put(BleService());
  Get.put(AppDatabase());

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
