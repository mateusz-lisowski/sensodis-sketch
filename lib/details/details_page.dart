import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../models/sensor.dart';
import 'details_controller.dart';
import '../widgets/detail_item.dart';

class DetailsPage extends StatelessWidget {
  final Sensor sensor;
  final DetailsController controller;

  DetailsPage({super.key, required this.sensor})
      : controller = Get.put(DetailsController(sensor: sensor));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('details'.tr),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        actions: [
          Obx(() => IconButton(
                icon: Icon(
                  sensor.isFavorite.value ? Icons.star : Icons.star_border,
                  color: sensor.isFavorite.value ? Colors.orange : null,
                ),
                onPressed: controller.toggleFavorite,
              )),
        ],
      ),
      body: Obx(() => _buildBody(context)),
      bottomNavigationBar: Obx(() => BottomNavigationBar(
            currentIndex: controller.currentTab.value,
            onTap: controller.changeTab,
            backgroundColor: Theme.of(context).colorScheme.primary,
            selectedItemColor: Theme.of(context).colorScheme.secondary,
            unselectedItemColor: Theme.of(context).colorScheme.onPrimary.withAlpha(153),
            items: [
              BottomNavigationBarItem(
                icon: const Icon(Icons.info),
                label: 'details'.tr,
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.history),
                label: 'history'.tr,
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.receipt_long),
                label: 'logs'.tr,
              ),
            ],
          )),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (controller.currentTab.value == 0) {
      return _buildDetailsTab(context);
    } else if (controller.currentTab.value == 1) {
      return _buildHistoryTab(context);
    } else {
      return _buildLogsTab(context);
    }
  }

  Widget _buildDetailsTab(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Obx(() => DetailItem(label: 'name'.tr, value: sensor.name.value, icon: Icons.label)),
          const Divider(),
          DetailItem(label: 'id'.tr, value: sensor.id, icon: Icons.fingerprint),
          const Divider(),
          Obx(() => DetailItem(label: 'temperature'.tr, value: '${sensor.temperature.value}°C', icon: Icons.thermostat)),
          const Divider(),
          Obx(() {
            if (sensor.humidity.value != null) {
              return Column(
                children: [
                  DetailItem(label: 'humidity'.tr, value: '${sensor.humidity.value}%', icon: Icons.water_drop),
                  const Divider(),
                ],
              );
            }
            return const SizedBox.shrink();
          }),
          Obx(() => DetailItem(label: 'battery'.tr, value: '${(sensor.batteryLevel.value / 5 * 100).round()}%', icon: Icons.battery_std)),
          const Divider(),
          Obx(() => DetailItem(label: 'rssi'.tr, value: '${sensor.rssi.value} dBm', icon: Icons.signal_cellular_alt)),
          const Divider(),
          Obx(() => DetailItem(label: 'last_updated'.tr, value: DateFormat('yyyy-MM-dd HH:mm:ss').format(sensor.lastUpdated.value), icon: Icons.access_time)),
        ],
      ),
    );
  }

  Widget _buildHistoryTab(BuildContext context) {
    return Obx(() {
      if (controller.history.isEmpty) {
        return Center(child: Text('no_history'.tr));
      }

      return ListView.separated(
        padding: const EdgeInsets.all(16.0),
        itemCount: controller.history.length,
        separatorBuilder: (context, index) => const Divider(),
        itemBuilder: (context, index) {
          final measure = controller.history[index];
          return ListTile(
            leading: Icon(Icons.history, color: Theme.of(context).colorScheme.primary),
            title: Text(
              '${measure.temperature}°C${measure.humidity != null ? ' | ${measure.humidity}%' : ''}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(DateFormat('yyyy-MM-dd HH:mm:ss').format(measure.timestamp)),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (measure.backedUp)
                  Icon(Icons.check_circle, color: Colors.green, size: 16),
                SizedBox(width: 8),
                Text('${(measure.batteryLevel / 5 * 100).round()}% Bat'),
              ],
            ),
          );
        },
      );
    });
  }

  Widget _buildLogsTab(BuildContext context) {
    return Obx(() {
      if (controller.backupLogs.isEmpty) {
        return Center(child: Text('no_logs'.tr));
      }

      return ListView.separated(
        padding: const EdgeInsets.all(16.0),
        itemCount: controller.backupLogs.length,
        separatorBuilder: (context, index) => const Divider(),
        itemBuilder: (context, index) {
          final log = controller.backupLogs[index];
          return ListTile(
            leading: Icon(Icons.receipt, color: Theme.of(context).colorScheme.primary),
            title: Text(
              '${log.statusCode} - ${log.response}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(DateFormat('yyyy-MM-dd HH:mm:ss').format(log.timestamp)),
          );
        },
      );
    });
  }
}
