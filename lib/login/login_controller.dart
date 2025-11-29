import 'package:flutter/material.dart';
import 'package:get/get.dart';

class LoginController extends GetxController {
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();

  void login() {
    // Implement login logic here
    Get.snackbar('Login', 'Login functionality not implemented yet');
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
