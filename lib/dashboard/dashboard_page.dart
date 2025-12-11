import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../widgets/app_bar_icon.dart';
import '../settings/settings_page.dart';
import '../details/details_page.dart';
import 'dashboard_controller.dart';
import '../utils/sensor_status_colors.dart';

class DashboardPage extends StatelessWidget {
  final DashboardController c = Get.put(DashboardController());

  DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: AppBarIcon(),
        title: Center(
          child: Text(
            'dashboard'.tr,
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        actions: [
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
              child: Obx(() => ListTile(
                leading: CircleAvatar(
                  backgroundColor: SensorStatusColors.getTemperatureColor(sensor.temperature.value),
                  foregroundColor: Colors.white,
                  child: const Icon(Icons.thermostat),
                ),
                title: Text(sensor.name.value, style: const TextStyle(fontWeight: FontWeight.bold)),
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
                            Text('${'temperature'.tr}: ${sensor.temperature.value}°C'),
                          ],
                        ),
                        if (sensor.humidity.value != null)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.water_drop, size: 16, color: Colors.grey[600]),
                              const SizedBox(width: 4),
                              Text('${'humidity'.tr}: ${sensor.humidity.value}%'),
                            ],
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(Icons.battery_std, size: 16, color: SensorStatusColors.getBatteryColor(sensor.batteryLevel.value)),
                        const SizedBox(width: 4),
                        Text('${'battery'.tr}: ${sensor.batteryLevel.value}%'),
                        const SizedBox(width: 16),
                        Icon(Icons.signal_cellular_alt, size: 16, color: SensorStatusColors.getRssiColor(sensor.rssi.value)),
                        const SizedBox(width: 4),
                        Text('${sensor.rssi.value} dBm'),
                        const Spacer(),
                        Text(
                          DateFormat('HH:mm:ss').format(sensor.lastUpdated.value),
                          style: TextStyle(color: Colors.grey[500], fontSize: 12),
                        ),
                      ],
                    ),
                  ],
                ),
                onTap: () {
                  Get.to(() => DetailsPage(sensor: sensor));
                },
              )),
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
            if (c.discoveredDevices.isEmpty && c.isScanning.value) {
              return Center(child: Text('no_devices'.tr));
            } else {
              return ListView.builder(
                itemCount: c.discoveredDevices.length,
                itemBuilder: (context, index) {
                  final result = c.discoveredDevices[index];
                  final deviceName = result.device.platformName.isNotEmpty
                      ? result.device.platformName
                      : 'unknown_device'.tr;
                      
                  // Check if device is already added
                  final isAdded = c.isSensorAdded(result);
                  
                  return ListTile(
                    title: Text(deviceName),
                    subtitle: Text(result.device.remoteId.toString()),
                    trailing: isAdded
                        ? const Icon(Icons.check_circle, color: Colors.green)
                        : ElevatedButton(
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
              // Removed c.stopScan() to keep background scanning active
              Get.back();
            },
            child: Text('close'.tr),
          ),
        ],
      ),
      // Keep scanning active when the dialog is dismissed.
      barrierDismissible: true,
    );
  }
}
