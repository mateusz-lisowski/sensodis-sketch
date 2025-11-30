import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:sensodis_sketch/widgets/app_bar_icon.dart';
import 'login_controller.dart';

class LoginPage extends StatelessWidget {
  final LoginController c = Get.put(LoginController());

  LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        leading: AppBarIcon(),
        actions: [
          IconButton(
            onPressed: () {
              if (Get.locale?.languageCode == 'en') {
                c.changeLanguage('de', 'DE');
              } else {
                c.changeLanguage('en', 'US');
              }
            },
            icon: const Icon(Icons.language),
            tooltip: 'change_lang'.tr,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Center(
          child: SingleChildScrollView(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Image.asset(
                  'assets/images/sensodis-logo.png',
                  height: 100,
                ),
                const SizedBox(height: 40),
                TextField(
                  controller: c.usernameController,
                  decoration: InputDecoration(
                    labelText: 'username'.tr,
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.person),
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: c.passwordController,
                  obscureText: true,
                  decoration: InputDecoration(
                    labelText: 'password'.tr,
                    border: const OutlineInputBorder(),
                    prefixIcon: const Icon(Icons.lock),
                  ),
                ),
                const SizedBox(height: 40),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: c.login,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.secondary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'login'.tr,
                      style: const TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
