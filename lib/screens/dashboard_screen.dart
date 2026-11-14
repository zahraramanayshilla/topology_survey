import 'dart:async';

import 'package:flutter/material.dart';

import '../algorithms/gps_fusion.dart';
import '../services/ble_service.dart';
import '../services/database_service.dart';
import '../services/gps_service.dart';
import '../widgets/coordinate_card.dart';
import '../widgets/device_status_card.dart';
import 'devices_screen.dart';
import 'history_screen.dart';
import 'map_screen.dart';
import 'survey_screen.dart';

/// Shell aplikasi: bottom navigation + tab Ringkasan.
class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});
  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final ble = BleService.instance;
  final gps = GpsService.instance;
  final db = DatabaseService.instance;
  final live = ValueNotifier<FusedEstimate?>(null);
  final refElev = ValueNotifier<double>(0);
  Timer? _timer;
  int tab = 0;

  @override
  void initState() {
    super.initState();
    _boot();
  }

  Future<void> _boot() async {
    await GpsService.requestPermissions();
    await db.init();
    await gps.start();
    await ble.startScan();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => live.value = compute());
  }

  FusedEstimate? compute() => PositionEstimator.estimate(
        anchors: ble.activeDevices,
        distanceOf: ble.distanceOf,
        pressure: gps.pressure,
        gpsLat: gps.position?.latitude,
        gpsLon: gps.position?.longitude,
        gpsAcc: gps.position?.accuracy,
        refElevation: refElev.value,
      );

  @override
  void dispose() {
    _timer?.cancel();
    live.dispose();
    refElev.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: tab, children: [
        _Overview(ble: ble, gps: gps, db: db, live: live),
        const DevicesScreen(),
        SurveyScreen(live: live, refElev: refElev, compute: compute),
        const MapScreen(),
        const HistoryScreen(),
      ]),
      bottomNavigationBar: NavigationBar(
        selectedIndex: tab,
        onDestinationSelected: (i) => setState(() => tab = i),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard), label: 'Ringkasan'),
          NavigationDestination(icon: Icon(Icons.bluetooth_searching), label: 'Perangkat'),
          NavigationDestination(icon: Icon(Icons.add_location_alt), label: 'Survei'),
          NavigationDestination(icon: Icon(Icons.map), label: 'Peta'),
          NavigationDestination(icon: Icon(Icons.history), label: 'Riwayat'),
        ],
      ),
    );
  }
}

class _Overview extends StatelessWidget {
  final BleService ble;
  final GpsService gps;
  final DatabaseService db;
  final ValueNotifier<FusedEstimate?> live;
  const _Overview({required this.ble, required this.gps, required this.db, required this.live});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([ble, gps, db, live]),
      builder: (context, _) {
        final act = ble.activeDevices;
        final e = live.value;
        final acc = gps.position?.accuracy;
        return Scaffold(
          appBar: AppBar(title: const Text('Topo Survey')),
          body: ListView(padding: const EdgeInsets.all(12), children: [
            Wrap(spacing: 8, children: [
              Chip(
                avatar: Icon(Icons.cell_tower, size: 18, color: act.length >= 3 ? Colors.teal : Colors.orange),
                label: Text('Anchor ${act.length}/3'),
              ),
              Chip(
                avatar: const Icon(Icons.gps_fixed, size: 18),
                label: Text(acc == null ? 'GPS -' : 'GPS ±${acc.toStringAsFixed(0)} m'),
              ),
              Chip(
                avatar: const Icon(Icons.speed, size: 18),
                label: Text(gps.pressure == null ? 'Baro -' : '${gps.pressure!.toStringAsFixed(1)} hPa'),
              ),
              Chip(
                avatar: const Icon(Icons.place, size: 18),
                label: Text('${db.points.length} titik'),
              ),
            ]),
            const SizedBox(height: 8),
            CoordinateCard(
              title: 'Posisi terfusi (BLE + GPS)',
              lat: e?.lat,
              lon: e?.lon,
              z: e?.z,
              icon: Icons.my_location,
              color: Theme.of(context).colorScheme.primaryContainer,
              footer: e == null
                  ? 'Butuh ≥3 anchor + barometer. Atur di tab Perangkat.'
                  : 'σ ${e.sigma.toStringAsFixed(2)} m | RMS BLE ${e.bleRms.toStringAsFixed(2)} m',
            ),
            const SizedBox(height: 8),
            const Text('Anchor terdeteksi', style: TextStyle(fontWeight: FontWeight.bold)),
            if (act.isEmpty) const Text('Belum ada. Jalankan mode Anchor di ≥3 HP lain.'),
            for (final d in act) DeviceStatusCard(device: d, distance: ble.distanceOf(d)),
          ]),
        );
      },
    );
  }
}
