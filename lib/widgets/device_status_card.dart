import 'package:flutter/material.dart';

import '../models/device_data.dart';

/// Status satu anchor: RSSI, perkiraan jarak, tekanan, umur data.
class DeviceStatusCard extends StatelessWidget {
  final DeviceData device;
  final double distance;
  const DeviceStatusCard({super.key, required this.device, required this.distance});

  @override
  Widget build(BuildContext context) {
    final rssi = device.medianRssi;
    final strength = ((rssi + 100) / 60).clamp(0.0, 1.0); // -100..-40 dBm
    final active = device.isActive();
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: active ? Colors.teal : Colors.grey,
          child: Text('A${device.id}', style: const TextStyle(color: Colors.white)),
        ),
        title: Text('${rssi.toStringAsFixed(0)} dBm  ≈ ${distance.toStringAsFixed(1)} m'),
        subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const SizedBox(height: 4),
          LinearProgressIndicator(value: strength.toDouble()),
          const SizedBox(height: 4),
          Text('${device.pressure.toStringAsFixed(2)} hPa  |  ${device.lat.toStringAsFixed(5)}, ${device.lon.toStringAsFixed(5)}  |  ${device.ageSeconds}s lalu',
              style: const TextStyle(fontSize: 11)),
        ]),
      ),
    );
  }
}
