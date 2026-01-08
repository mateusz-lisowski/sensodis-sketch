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
            child: Text('backup_settings'.tr, style: Theme.of(context).textTheme.titleLarge),
          ),
          ListTile(
            leading: const Icon(Icons.cloud_upload),
            title: Text('endpoint_url'.tr),
            subtitle: Obx(() => Text(settingsService.endpointUrl.value)),
            onTap: () => _showEndpointDialog(context, settingsService),
          ),
          ListTile(
            leading: const Icon(Icons.timer),
            title: Text('backup_interval'.tr),
            subtitle: Obx(() => Text('backup_interval_minutes'.trParams({
                  'count': settingsService.backupInterval.value.toString(),
                }))),
            onTap: () => _showIntervalDialog(context, settingsService),
          ),
          Obx(() => SwitchListTile(
            title: Text('backup_favorites_only'.tr),
            value: settingsService.backupFavoritesOnly.value,
            onChanged: (value) {
              settingsService.setBackupFavoritesOnly(value);
            },
          )),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: Text('app_version'.tr),
            subtitle: Obx(() => Text(settingsService.appVersion.value)),
          ),
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
        title: Text('endpoint_url'.tr),
        content: TextField(
          controller: controller,
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('cancel'.tr),
          ),
          TextButton(
            onPressed: () {
              settingsService.setEndpointUrl(controller.text);
              Get.back();
            },
            child: Text('save'.tr),
          ),
        ],
      ),
    );
  }

  void _showIntervalDialog(BuildContext context, SettingsService settingsService) {
    final intervals = [1, 5, 10, 15, 30, 60];
    Get.dialog(
      AlertDialog(
        title: Text('backup_interval'.tr),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: intervals
              .map((interval) => ListTile(
                    title: Text('backup_interval_minutes'.trParams({
                      'count': interval.toString(),
                    })),
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
