import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../widgets/app_bar_icon.dart';
import '../settings/settings_page.dart';
import 'dashboard_controller.dart';

class DashboardPage extends StatelessWidget {
  final DashboardController c = Get.put(DashboardController());

  DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: AppBarIcon(),
        title: Text(
          'dashboard'.tr,
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: c.refreshSensors,
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Get.to(() => const SettingsPage()),
          ),
        ],
      ),
      body: Obx(
        () => ListView.builder(
          itemCount: c.sensors.length,
          itemBuilder: (context, index) {
            final sensor = c.sensors[index];
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: _getTemperatureColor(sensor.temperature),
                  foregroundColor: Colors.white,
                  child: const Icon(Icons.thermostat),
                ),
                title: Text(sensor.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 16,
                      runSpacing: 4,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.thermostat, size: 16, color: Colors.grey[600]),
                            const SizedBox(width: 4),
                            Text('${'temperature'.tr}: ${sensor.temperature}°C'),
                          ],
                        ),
                        if (sensor.humidity != null)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.water_drop, size: 16, color: Colors.grey[600]),
                              const SizedBox(width: 4),
                              Text('${'humidity'.tr}: ${sensor.humidity}%'),
                            ],
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.battery_std, size: 16, color: _getBatteryColor(sensor.batteryLevel)),
                        const SizedBox(width: 4),
                        Text('${'battery'.tr}: ${sensor.batteryLevel}%'),
                        const Spacer(),
                        Text(
                          DateFormat('HH:mm:ss').format(sensor.lastUpdated),
                          style: TextStyle(color: Colors.grey[500], fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
                onTap: () {
                  // Navigate to sensor details if needed
                },
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Theme.of(context).colorScheme.secondary,
        foregroundColor: Theme.of(context).colorScheme.onSecondary,
        onPressed: () => _showScanDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showScanDialog(BuildContext context) {
    c.startScan();
    Get.dialog(
      AlertDialog(
        title: Row(
          children: [
            Text('scan_devices'.tr),
            const Spacer(),
            Obx(() {
              if (c.isScanning.value) {
                return const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                );
              }
              return const SizedBox.shrink();
            }),
          ],
        ),
        content: SizedBox(
          width: double.maxFinite,
          height: 300,
          child: Obx(() {
            if (c.scanResults.isEmpty && c.isScanning.value) {
              return Center(child: Text('no_devices'.tr));
            } else {
              return ListView.builder(
                itemCount: c.scanResults.length,
                itemBuilder: (context, index) {
                  final result = c.scanResults[index];
                  final deviceName = result.device.platformName.isNotEmpty
                      ? result.device.platformName
                      : 'unknown_device'.tr;
                  return ListTile(
                    title: Text(deviceName),
                    subtitle: Text(result.device.remoteId.toString()),
                    trailing: ElevatedButton(
                      onPressed: () {
                        c.addDevice(result);
                      },
                      child: Text('add'.tr),
                    ),
                  );
                },
              );
            }
          }),
        ),
        actions: [
          TextButton(
            onPressed: () {
              c.stopScan();
              Get.back();
            },
            child: Text('close'.tr),
          ),
        ],
      ),
      // Stop scanning when the dialog is dismissed.
      barrierDismissible: false,
    );
  }

  Color _getTemperatureColor(double temp) {
    if (temp < 0) return Colors.blue;
    if (temp > 25) return Colors.orange;
    if (temp > 30) return Colors.red;
    return Colors.green;
  }

  Color _getBatteryColor(int level) {
    if (level < 20) return Colors.red;
    if (level < 50) return Colors.orange;
    return Colors.green;
  }
}
