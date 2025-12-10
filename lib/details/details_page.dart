import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import '../models/sensor.dart';

class DetailsPage extends StatelessWidget {
  final Sensor sensor;

  const DetailsPage({super.key, required this.sensor});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('details'.tr),
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
      ),
      body: SingleChildScrollView(
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
      ),
    );
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
