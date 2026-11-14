import 'dart:math' as math;

import '../models/device_data.dart';
import 'multilateration.dart';
import 'trilateration.dart';

const double kEarthRadius = 6378137.0;

/// Bidang datar lokal (meter) di sekitar titik acuan (lat0, lon0).
class LocalFrame {
  final double lat0, lon0;
  const LocalFrame(this.lat0, this.lon0);

  (double, double) toXY(double lat, double lon) => (
        (lon - lon0) * math.pi / 180 * kEarthRadius * math.cos(lat0 * math.pi / 180),
        (lat - lat0) * math.pi / 180 * kEarthRadius,
      );

  (double, double) toLatLon(double x, double y) => (
        lat0 + y / kEarthRadius * 180 / math.pi,
        lon0 + x / (kEarthRadius * math.cos(lat0 * math.pi / 180)) * 180 / math.pi,
      );
}

/// Elevasi dari barometer (diferensial terhadap tekanan anchor).
class Barometry {
  /// Beda tinggi (m) antara tekanan p dan tekanan acuan pRef (hPa).
  static double heightDiff(double p, double pRef) =>
      44330.0 * (1 - math.pow(p / pRef, 0.190294957));
}

/// Fusi inverse-variance antara estimasi BLE dan GPS.
class GpsFusion {
  /// Mengembalikan (x, y, sigma) hasil fusi.
  static (double, double, double) fuse({
    required double bleX,
    required double bleY,
    required double bleSigma,
    double? gpsX,
    double? gpsY,
    double gpsSigma = 10,
  }) {
    if (gpsX == null || gpsY == null) return (bleX, bleY, bleSigma);
    final wb = 1 / (bleSigma * bleSigma);
    final wg = 1 / (gpsSigma * gpsSigma);
    return (
      (wb * bleX + wg * gpsX) / (wb + wg),
      (wb * bleY + wg * gpsY) / (wb + wg),
      math.sqrt(1 / (wb + wg)),
    );
  }
}

class FusedEstimate {
  final double lat, lon, z, bleRms, sigma, pressure;
  final double? gpsOffset; // jarak hasil fusi terhadap GPS mentah (m)
  final int nAnchors;
  const FusedEstimate({
    required this.lat,
    required this.lon,
    required this.z,
    required this.bleRms,
    required this.sigma,
    required this.pressure,
    required this.gpsOffset,
    required this.nAnchors,
  });
}

/// Pipeline lengkap: jarak BLE -> trilaterasi (tebakan awal) -> multilaterasi
/// -> fusi dengan GPS -> elevasi barometer.
class PositionEstimator {
  static FusedEstimate? estimate({
    required List<DeviceData> anchors,
    required double Function(DeviceData) distanceOf,
    required double? pressure,
    double? gpsLat,
    double? gpsLon,
    double? gpsAcc,
    double refElevation = 0,
  }) {
    if (anchors.length < 3 || pressure == null) return null;

    final lat0 = anchors.map((a) => a.lat).reduce((a, b) => a + b) / anchors.length;
    final lon0 = anchors.map((a) => a.lon).reduce((a, b) => a + b) / anchors.length;
    final f = LocalFrame(lat0, lon0);

    final ax = <double>[], ay = <double>[], d = <double>[];
    for (final a in anchors) {
      final p = f.toXY(a.lat, a.lon);
      ax.add(p.$1);
      ay.add(p.$2);
      d.add(distanceOf(a));
    }

    final init = Trilateration.solve(ax, ay, d) ??
        (ax.reduce((a, b) => a + b) / ax.length, ay.reduce((a, b) => a + b) / ay.length);
    final ml = Multilateration.solve(ax: ax, ay: ay, d: d, x0: init.$1, y0: init.$2);
    if (ml == null) return null;

    double? gx, gy;
    if (gpsLat != null && gpsLon != null) {
      final g = f.toXY(gpsLat, gpsLon);
      gx = g.$1;
      gy = g.$2;
    }
    final fused = GpsFusion.fuse(
      bleX: ml.x,
      bleY: ml.y,
      bleSigma: math.max(2.0, ml.rms),
      gpsX: gx,
      gpsY: gy,
      gpsSigma: math.max(gpsAcc ?? 10, 5),
    );
    final ll = f.toLatLon(fused.$1, fused.$2);

    final pRef = anchors.map((a) => a.pressure).reduce((a, b) => a + b) / anchors.length;
    final z = refElevation + Barometry.heightDiff(pressure, pRef);

    double? off;
    if (gx != null && gy != null) {
      off = math.sqrt(math.pow(fused.$1 - gx, 2) + math.pow(fused.$2 - gy, 2));
    }
    return FusedEstimate(
      lat: ll.$1,
      lon: ll.$2,
      z: z,
      bleRms: ml.rms,
      sigma: fused.$3,
      pressure: pressure,
      gpsOffset: off,
      nAnchors: anchors.length,
    );
  }
}
