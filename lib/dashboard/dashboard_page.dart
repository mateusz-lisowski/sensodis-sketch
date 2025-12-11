import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../models/sensor.dart';
import '../utils/ble_decoder.dart';
import '../widgets/app_bar_icon.dart';
import '../settings/settings_page.dart';
import '../details/details_page.dart';
import 'dashboard_controller.dart';
import '../services/ble_service.dart';
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
              child: Obx(() => InkWell(
                onTap: () {
                  Get.to(() => DetailsPage(sensor: sensor));
                },
                onLongPress: () => _showDeleteConfirmation(context, sensor),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            backgroundColor: SensorStatusColors.getTemperatureColor(sensor.temperature.value),
                            foregroundColor: Colors.white,
                            child: const Icon(Icons.thermostat),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(sensor.name.value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                Text(
                                  sensor.id,
                                  style: TextStyle(color: Colors.grey[500], fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            DateFormat('HH:mm:ss').format(sensor.lastUpdated.value),
                            style: TextStyle(color: Colors.grey[500], fontSize: 12),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '${sensor.temperature.value}°C',
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Row(
                            children: [
                              if (sensor.humidity.value != null) ...[
                                Column(
                                  children: [
                                    Icon(Icons.water_drop, color: Colors.grey[600]),
                                    const SizedBox(height: 4),
                                    Text('${sensor.humidity.value}%', style: const TextStyle(fontSize: 12)),
                                  ],
                                ),
                                const SizedBox(width: 16),
                              ],
                              Column(
                                children: [
                                  Icon(Icons.battery_std, color: SensorStatusColors.getBatteryColor(sensor.batteryLevel.value)),
                                  const SizedBox(height: 4),
                                  Text('${sensor.batteryLevel.value}%', style: const TextStyle(fontSize: 12)),
                                ],
                              ),
                              const SizedBox(width: 16),
                              Column(
                                children: [
                                  Icon(Icons.signal_cellular_alt, color: SensorStatusColors.getRssiColor(sensor.rssi.value)),
                                  const SizedBox(height: 4),
                                  Text('${sensor.rssi.value} dBm', style: const TextStyle(fontSize: 12)),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              )),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: Theme.of(context).colorScheme.secondary,
        foregroundColor: Theme.of(context).colorScheme.onSecondary,
        onPressed: () => _showAddDeviceDialog(context),
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, Sensor sensor) {
    Get.dialog(
      AlertDialog(
        title: Text('delete_sensor'.tr),
        content: Text('delete_sensor_confirmation'.trParams({'name': sensor.name.value})),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('cancel'.tr),
          ),
          TextButton(
            onPressed: () {
              c.deleteSensor(sensor);
              Get.back();
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: Text('delete'.tr),
          ),
        ],
      ),
    );
  }

  void _showAddDeviceDialog(BuildContext context) {
    final BleService bleService = Get.find<BleService>();

    Get.dialog(
      AlertDialog(
        title: Row(
          children: [
            Text('available_devices'.tr),
            const Spacer(),
            Obx(() {
              if (bleService.isScanning.value) {
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
            final currentDevices = bleService.devices;

            if (currentDevices.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.bluetooth_searching, size: 48, color: Colors.grey[400]),
                    const SizedBox(height: 16),
                    Text('searching_devices'.tr),
                    const SizedBox(height: 8),
                    Text(
                      'scanning_automatically'.tr,
                      style: TextStyle(color: Colors.grey[500], fontSize: 12),
                    ),
                  ],
                ),
              );
            } else {
              return ListView.builder(
                itemCount: currentDevices.length,
                itemBuilder: (context, index) {
                  final result = currentDevices[index];
                  final deviceName = result.device.platformName.isNotEmpty
                      ? result.device.platformName
                      : 'unknown_device'.tr;

                  // Get device ID from the BLE decoder
                  final decodedData = decodeTr4AdvertisingPacket(result.advertisementData);
                  final deviceId = decodedData?.serialNumber ?? result.device.remoteId.toString();

                  // Check if device is already added
                  final isAdded = c.isSensorAdded(deviceId);

                  return ListTile(
                    title: Text(deviceName),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('ID: $deviceId'),
                        Text('RSSI: ${result.rssi} dBm'),
                      ],
                    ),
                    trailing: isAdded
                        ? Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle, color: Colors.green, size: 16),
                          SizedBox(width: 4),
                          Text('added'.tr, style: TextStyle(color: Colors.green)),
                        ],
                      ),
                    )
                        : ElevatedButton(
                      onPressed: () {
                        c.addDevice(result);
                        Get.back();
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
            onPressed: () => Get.back(),
            child: Text('close'.tr),
          ),
        ],
      ),
      barrierDismissible: true,
    );
  }
}
