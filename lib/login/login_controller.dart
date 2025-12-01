import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../dashboard/dashboard_page.dart';

class LoginController extends GetxController {
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();

  void login() {
    // Implement login logic here
    // For now, we simulate a successful login and navigate to the dashboard
    Get.offAll(() => DashboardPage());
  }

  void changeLanguage(String lang, String country) {
    var locale = Locale(lang, country);
    Get.updateLocale(locale);
  }

  @override
  void onClose() {
    usernameController.dispose();
    passwordController.dispose();
    super.onClose();
  }
}
