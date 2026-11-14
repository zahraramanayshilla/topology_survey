import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../algorithms/gps_fusion.dart';
import '../models/device_data.dart';
import '../models/survey_point.dart';
import '../services/ble_service.dart';
import '../services/database_service.dart';

/// Peta sebar titik survei; warna = elevasi (biru rendah → merah tinggi).
class MapScreen extends StatelessWidget {
  const MapScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final db = DatabaseService.instance, ble = BleService.instance;
    return ListenableBuilder(
      listenable: Listenable.merge([db, ble]),
      builder: (context, _) => Scaffold(
        appBar: AppBar(title: const Text('Peta Titik')),
        body: Container(
          color: Colors.white,
          width: double.infinity,
          height: double.infinity,
          child: CustomPaint(painter: _MapPainter(db.points, ble.activeDevices)),
        ),
      ),
    );
  }
}

class _MapPainter extends CustomPainter {
  final List<SurveyPoint> pts;
  final List<DeviceData> anchors;
  _MapPainter(this.pts, this.anchors);

  void _text(Canvas c, String s, Offset o, {double size = 11}) {
    final tp = TextPainter(
        text: TextSpan(text: s, style: TextStyle(color: Colors.black, fontSize: size)),
        textDirection: TextDirection.ltr)
      ..layout();
    tp.paint(c, o);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final all = <(double, double)>[
      for (final p in pts) (p.lat, p.lon),
      for (final a in anchors) (a.lat, a.lon),
    ];
    if (all.isEmpty) {
      _text(canvas, 'Belum ada titik. Ambil titik di tab Survei.', const Offset(16, 16), size: 14);
      return;
    }
    final f = LocalFrame(all.map((e) => e.$1).reduce((a, b) => a + b) / all.length,
        all.map((e) => e.$2).reduce((a, b) => a + b) / all.length);
    final xy = all.map((e) => f.toXY(e.$1, e.$2)).toList();
    final minX = xy.map((e) => e.$1).reduce(math.min), maxX = xy.map((e) => e.$1).reduce(math.max);
    final minY = xy.map((e) => e.$2).reduce(math.min), maxY = xy.map((e) => e.$2).reduce(math.max);
    final span = math.max(math.max(maxX - minX, maxY - minY), 5.0);
    final scale = (math.min(size.width, size.height) - 70) / span;
    Offset tr((double, double) p) =>
        Offset(35 + (p.$1 - minX) * scale, size.height - 35 - (p.$2 - minY) * scale);

    final zs = pts.map((p) => p.z).toList();
    final zmin = zs.isEmpty ? 0.0 : zs.reduce(math.min);
    final zmax = zs.isEmpty ? 1.0 : zs.reduce(math.max);

    for (var i = 0; i < pts.length; i++) {
      final o = tr(xy[i]);
      final t = zmax == zmin ? 0.5 : (pts[i].z - zmin) / (zmax - zmin);
      canvas.drawCircle(o, 9, Paint()..color = Color.lerp(Colors.blue, Colors.red, t)!);
      _text(canvas, pts[i].z.toStringAsFixed(1), o + const Offset(11, -6));
    }
    for (var j = 0; j < anchors.length; j++) {
      final o = tr(xy[pts.length + j]);
      final path = Path()
        ..moveTo(o.dx, o.dy - 10)
        ..lineTo(o.dx - 9, o.dy + 8)
        ..lineTo(o.dx + 9, o.dy + 8)
        ..close();
      canvas.drawPath(path, Paint()..color = Colors.black);
      _text(canvas, 'A${anchors[j].id}', o + const Offset(11, -6), size: 12);
    }
    _text(canvas,
        'Sisi peta ≈ ${span.toStringAsFixed(0)} m   |   z: ${zmin.toStringAsFixed(1)} – ${zmax.toStringAsFixed(1)} m',
        const Offset(10, 6));
  }

  @override
  bool shouldRepaint(covariant _MapPainter old) => true;
}
