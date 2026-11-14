import 'package:flutter/material.dart';

import '../algorithms/gps_fusion.dart';
import '../models/survey_point.dart';
import '../services/database_service.dart';
import '../services/gps_service.dart';
import '../widgets/coordinate_card.dart';

/// Survei: ambil titik (rata-rata 10 sampel / 5 detik) dan simpan ke database.
class SurveyScreen extends StatefulWidget {
  final ValueNotifier<FusedEstimate?> live;
  final ValueNotifier<double> refElev;
  final FusedEstimate? Function() compute;
  const SurveyScreen({super.key, required this.live, required this.refElev, required this.compute});

  @override
  State<SurveyScreen> createState() => _SurveyScreenState();
}

class _SurveyScreenState extends State<SurveyScreen> {
  final elevCtl = TextEditingController(text: '0');
  final labelCtl = TextEditingController();
  bool capturing = false;
  double progress = 0;
  SurveyPoint? last;

  Future<void> capture() async {
    if (capturing) return;
    setState(() {
      capturing = true;
      progress = 0;
    });
    final list = <FusedEstimate>[];
    for (var i = 0; i < 10; i++) {
      final e = widget.compute();
      if (e != null) list.add(e);
      await Future.delayed(const Duration(milliseconds: 500));
      if (mounted) setState(() => progress = (i + 1) / 10);
    }
    if (!mounted) return;
    if (list.length < 3) {
      setState(() => capturing = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Gagal: data kurang (butuh ≥3 anchor + barometer stabil).')));
      return;
    }
    double avg(double Function(FusedEstimate) f) =>
        list.map(f).reduce((a, b) => a + b) / list.length;
    final gps = GpsService.instance.position;
    final p = SurveyPoint(
      time: DateTime.now(),
      lat: avg((e) => e.lat),
      lon: avg((e) => e.lon),
      z: avg((e) => e.z),
      bleRms: avg((e) => e.bleRms),
      sigma: avg((e) => e.sigma),
      pressure: avg((e) => e.pressure),
      gpsLat: gps?.latitude,
      gpsLon: gps?.longitude,
      gpsAcc: gps?.accuracy,
      nAnchors: list.last.nAnchors,
      label: labelCtl.text.trim(),
    );
    await DatabaseService.instance.insert(p);
    if (!mounted) return;
    setState(() {
      capturing = false;
      last = p;
      labelCtl.clear();
    });
  }

  @override
  void dispose() {
    elevCtl.dispose();
    labelCtl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Survei Titik')),
      body: ValueListenableBuilder<FusedEstimate?>(
        valueListenable: widget.live,
        builder: (context, e, _) => ListView(padding: const EdgeInsets.all(12), children: [
          CoordinateCard(
            title: 'Posisi rover (BLE multilaterasi + GPS)',
            lat: e?.lat,
            lon: e?.lon,
            z: e?.z,
            icon: Icons.gps_fixed,
            color: Theme.of(context).colorScheme.primaryContainer,
            footer: e == null
                ? 'Butuh ≥3 anchor terdeteksi dan barometer aktif.'
                : '${e.nAnchors} anchor | RMS BLE ${e.bleRms.toStringAsFixed(2)} m | σ fusi ${e.sigma.toStringAsFixed(2)} m'
                    '${e.gpsOffset == null ? "" : " | geser dari GPS ${e.gpsOffset!.toStringAsFixed(1)} m"}',
          ),
          const SizedBox(height: 8),
          TextField(
            controller: elevCtl,
            keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
            decoration: const InputDecoration(
                labelText: 'Elevasi acuan anchor (m dpl) — 0 = relatif',
                border: OutlineInputBorder()),
            onChanged: (v) => widget.refElev.value = double.tryParse(v.replaceAll(',', '.')) ?? 0,
          ),
          const SizedBox(height: 8),
          TextField(
            controller: labelCtl,
            decoration: const InputDecoration(
                labelText: 'Label titik (opsional, mis. "puncak", "selokan")',
                border: OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            icon: const Icon(Icons.add_location_alt),
            label: Padding(
              padding: const EdgeInsets.all(12),
              child: Text(capturing ? 'Mengambil…' : 'AMBIL TITIK SURVEI'),
            ),
            onPressed: capturing || e == null ? null : capture,
          ),
          if (capturing) Padding(
            padding: const EdgeInsets.only(top: 8),
            child: LinearProgressIndicator(value: progress),
          ),
          if (last != null)
            CoordinateCard(
              title: 'Titik terakhir tersimpan',
              lat: last!.lat,
              lon: last!.lon,
              z: last!.z,
              icon: Icons.check_circle,
              footer: last!.label.isEmpty ? null : last!.label,
            ),
          Text('Total titik: ${DatabaseService.instance.points.length}',
              textAlign: TextAlign.center),
        ]),
      ),
    );
  }
}
