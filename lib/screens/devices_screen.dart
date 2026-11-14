import 'package:flutter/material.dart';

import '../services/ble_service.dart';
import '../services/gps_service.dart';
import '../widgets/coordinate_card.dart';
import '../widgets/device_status_card.dart';

/// Perangkat: jadikan HP ini Anchor, kalibrasi RSSI, lihat anchor terdeteksi.
class DevicesScreen extends StatefulWidget {
  const DevicesScreen({super.key});
  @override
  State<DevicesScreen> createState() => _DevicesScreenState();
}

class _DevicesScreenState extends State<DevicesScreen> {
  final ble = BleService.instance;
  final gps = GpsService.instance;
  int id = 1;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([ble, gps]),
      builder: (context, _) {
        final act = ble.activeDevices;
        return Scaffold(
          appBar: AppBar(title: const Text('Perangkat & Anchor')),
          body: ListView(padding: const EdgeInsets.all(12), children: [
            const Text('Jadikan HP ini ANCHOR',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const Text('Letakkan diam di patok, tunggu GPS terkumpul, kunci, lalu mulai pancaran.',
                style: TextStyle(fontSize: 12)),
            Row(children: [
              const Text('ID: '),
              DropdownButton<int>(
                value: id,
                items: [for (var i = 1; i <= 6; i++) DropdownMenuItem(value: i, child: Text('A$i'))],
                onChanged: ble.advertising ? null : (v) => setState(() => id = v!),
              ),
              const Spacer(),
              TextButton(
                  onPressed: gps.resetAveraging, child: const Text('Reset rata-rata GPS')),
            ]),
            CoordinateCard(
              title: 'Posisi anchor (rata-rata GPS)',
              lat: gps.samples == 0 ? null : gps.meanLat,
              lon: gps.samples == 0 ? null : gps.meanLon,
              footer:
                  'Sampel: ${gps.samples}  |  tekanan: ${gps.pressure?.toStringAsFixed(2) ?? "-"} hPa',
              icon: Icons.push_pin,
            ),
            SwitchListTile(
              title: const Text('Kunci posisi'),
              value: gps.locked,
              onChanged: gps.setLocked,
            ),
            FilledButton.icon(
              icon: Icon(ble.advertising ? Icons.stop : Icons.podcasts),
              label: Text(ble.advertising ? 'Hentikan pancaran BLE' : 'Mulai pancaran BLE (A$id)'),
              onPressed: () => ble.advertising ? ble.stopAdvertising() : ble.startAdvertising(id),
            ),
            const Divider(height: 32),
            const Text('Kalibrasi jarak (BLE)',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            Text('TxPower (RSSI @1 m): ${ble.txPower.toStringAsFixed(0)} dBm'),
            Slider(value: ble.txPower, min: -80, max: -40, onChanged: ble.setTxPower),
            Text('Eksponen path-loss n: ${ble.pathN.toStringAsFixed(1)}'),
            Slider(value: ble.pathN, min: 1.5, max: 4, onChanged: ble.setPathN),
            OutlinedButton(
              onPressed: ble.calibrateAt1m,
              child: const Text('Kalibrasi: dekatkan ±1 m ke satu anchor, lalu tekan'),
            ),
            const Divider(height: 32),
            Text('Anchor terdeteksi: ${act.length} (min. 3)',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            if (act.isEmpty) const Text('Belum ada anchor di jangkauan.'),
            for (final d in act) DeviceStatusCard(device: d, distance: ble.distanceOf(d)),
          ]),
        );
      },
    );
  }
}
