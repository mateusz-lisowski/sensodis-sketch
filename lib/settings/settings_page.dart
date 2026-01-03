import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../services/settings_service.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final SettingsService settingsService = Get.find<SettingsService>();

    return Scaffold(
      appBar: AppBar(
        title: Text('settings'.tr),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
      ),
      body: ListView(
        children: [
          ListTile(
            leading: const Icon(Icons.language),
            title: Text('change_lang'.tr),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () => _showLanguageDialog(context),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text('Backup Settings', style: Theme.of(context).textTheme.titleLarge),
          ),
          ListTile(
            leading: const Icon(Icons.cloud_upload),
            title: const Text('Endpoint URL'),
            subtitle: Obx(() => Text(settingsService.endpointUrl.value)),
            onTap: () => _showEndpointDialog(context, settingsService),
          ),
          ListTile(
            leading: const Icon(Icons.timer),
            title: const Text('Backup Interval'),
            subtitle: Obx(() => Text('${settingsService.backupInterval.value} minutes')),
            onTap: () => _showIntervalDialog(context, settingsService),
          ),
          Obx(() => SwitchListTile(
            title: const Text('Backup Favorites Only'),
            value: settingsService.backupFavoritesOnly.value,
            onChanged: (value) {
              settingsService.setBackupFavoritesOnly(value);
            },
          )),
        ],
      ),
    );
  }

  void _showLanguageDialog(BuildContext context) {
    Get.dialog(
      AlertDialog(
        title: Text('change_lang'.tr),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              title: const Text('English'),
              onTap: () {
                Get.updateLocale(const Locale('en', 'US'));
                Get.back();
              },
            ),
            ListTile(
              title: const Text('Polski'),
              onTap: () {
                Get.updateLocale(const Locale('pl', 'PL'));
                Get.back();
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showEndpointDialog(BuildContext context, SettingsService settingsService) {
    final controller = TextEditingController(text: settingsService.endpointUrl.value);
    Get.dialog(
      AlertDialog(
        title: const Text('Endpoint URL'),
        content: TextField(
          controller: controller,
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              settingsService.setEndpointUrl(controller.text);
              Get.back();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showIntervalDialog(BuildContext context, SettingsService settingsService) {
    final intervals = [1, 5, 10, 15, 30, 60];
    Get.dialog(
      AlertDialog(
        title: const Text('Backup Interval'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: intervals
              .map((interval) => ListTile(
                    title: Text('$interval minutes'),
                    onTap: () {
                      settingsService.setBackupInterval(interval);
                      Get.back();
                    },
                  ))
              .toList(),
        ),
      ),
    );
  }
}
