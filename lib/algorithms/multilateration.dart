import 'dart:math' as math;

class MultilaterationResult {
  final double x, y, rms;
  const MultilaterationResult(this.x, this.y, this.rms);
}

/// Multilaterasi 2D untuk >= 3 anchor: Gauss-Newton berbobot.
/// Bobot tiap anchor = 1/sigma^2, dengan sigma ~ 30% jarak (error RSSI
/// membesar seiring jarak), minimal 1,5 m.
class Multilateration {
  static MultilaterationResult? solve({
    required List<double> ax,
    required List<double> ay,
    required List<double> d,
    required double x0,
    required double y0,
    int maxIter = 40,
  }) {
    if (ax.length < 3) return null;
    var x = x0, y = y0;
    for (var it = 0; it < maxIter; it++) {
      double a11 = 0, a12 = 0, a22 = 0, b1 = 0, b2 = 0;
      for (var i = 0; i < ax.length; i++) {
        final dx = x - ax[i], dy = y - ay[i];
        final r = math.max(math.sqrt(dx * dx + dy * dy), 1e-6);
        final res = r - d[i];
        final sigma = math.max(1.5, 0.3 * d[i]);
        final w = 1 / (sigma * sigma);
        final jx = dx / r, jy = dy / r;
        a11 += w * jx * jx;
        a12 += w * jx * jy;
        a22 += w * jy * jy;
        b1 += w * jx * res;
        b2 += w * jy * res;
      }
      final det = a11 * a22 - a12 * a12;
      if (det.abs() < 1e-12) break;
      final sx = (a22 * b1 - a12 * b2) / det;
      final sy = (-a12 * b1 + a11 * b2) / det;
      x -= sx;
      y -= sy;
      if (sx.abs() < 1e-4 && sy.abs() < 1e-4) break;
    }
    double ss = 0;
    for (var i = 0; i < ax.length; i++) {
      final r = math.sqrt(math.pow(x - ax[i], 2) + math.pow(y - ay[i], 2));
      ss += math.pow(r - d[i], 2);
    }
    return MultilaterationResult(x, y, math.sqrt(ss / ax.length));
  }
}
