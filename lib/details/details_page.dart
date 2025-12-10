import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../models/sensor.dart';
import 'details_controller.dart';

class DetailsPage extends StatelessWidget {
  final Sensor sensor;
  final DetailsController controller;

  DetailsPage({super.key, required this.sensor})
      : controller = Get.put(DetailsController(sensorId: sensor.id));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('details'.tr),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
      ),
      body: Obx(() => _buildBody(context)),
      bottomNavigationBar: Obx(() => BottomNavigationBar(
            currentIndex: controller.currentTab.value,
            onTap: controller.changeTab,
            backgroundColor: Theme.of(context).colorScheme.primary,
            selectedItemColor: Theme.of(context).colorScheme.secondary,
            unselectedItemColor: Theme.of(context).colorScheme.onPrimary.withOpacity(0.6),
            items: [
              BottomNavigationBarItem(
                icon: const Icon(Icons.info),
                label: 'details'.tr,
              ),
              BottomNavigationBarItem(
                icon: const Icon(Icons.history),
                label: 'History',
              ),
            ],
          )),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (controller.currentTab.value == 0) {
      return _buildDetailsTab(context);
    } else {
      return _buildHistoryTab(context);
    }
  }

  Widget _buildDetailsTab(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Obx(() => _buildDetailItem(context, 'Name', sensor.name.value, Icons.label)),
          const Divider(),
          _buildDetailItem(context, 'ID', sensor.id, Icons.fingerprint),
          const Divider(),
          Obx(() => _buildDetailItem(context, 'temperature'.tr, '${sensor.temperature.value}°C', Icons.thermostat)),
          const Divider(),
          Obx(() {
            if (sensor.humidity.value != null) {
              return Column(
                children: [
                  _buildDetailItem(context, 'humidity'.tr, '${sensor.humidity.value}%', Icons.water_drop),
                  const Divider(),
                ],
              );
            }
            return const SizedBox.shrink();
          }),
          Obx(() => _buildDetailItem(context, 'battery'.tr, '${sensor.batteryLevel.value}%', Icons.battery_std)),
          const Divider(),
          Obx(() => _buildDetailItem(context, 'rssi'.tr, '${sensor.rssi.value} dBm', Icons.signal_cellular_alt)),
          const Divider(),
          Obx(() => _buildDetailItem(context, 'last_updated'.tr, DateFormat('yyyy-MM-dd HH:mm:ss').format(sensor.lastUpdated.value), Icons.access_time)),
        ],
      ),
    );
  }

  Widget _buildHistoryTab(BuildContext context) {
    return Obx(() {
      if (controller.isLoading.value) {
        return const Center(child: CircularProgressIndicator());
      }

      if (controller.history.isEmpty) {
        return const Center(child: Text('No history available'));
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
              '${measure.temperature}°C' + (measure.humidity != null ? ' | ${measure.humidity}%' : ''),
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(DateFormat('yyyy-MM-dd HH:mm:ss').format(measure.timestamp)),
            trailing: Text('${measure.batteryLevel}% Bat'),
          );
        },
      );
    });
  }

  Widget _buildDetailItem(BuildContext context, String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        children: [
          Icon(icon, size: 28, color: Theme.of(context).colorScheme.secondary),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
