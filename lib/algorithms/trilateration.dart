/// Trilaterasi 2D bentuk tertutup dari TEPAT 3 titik acuan.
/// Dipakai sebagai tebakan awal bagi multilaterasi.
class Trilateration {
  /// ax, ay, d: koordinat lokal (m) 3 anchor & jarak terukur (m).
  /// Mengembalikan (x, y) atau null bila anchor segaris / data kurang.
  static (double, double)? solve(List<double> ax, List<double> ay, List<double> d) {
    if (ax.length < 3) return null;
    final x1 = ax[0], y1 = ay[0], x2 = ax[1], y2 = ay[1], x3 = ax[2], y3 = ay[2];
    final r1 = d[0], r2 = d[1], r3 = d[2];

    final a11 = 2 * (x2 - x1), a12 = 2 * (y2 - y1);
    final a21 = 2 * (x3 - x1), a22 = 2 * (y3 - y1);
    final b1 = r1 * r1 - r2 * r2 + x2 * x2 - x1 * x1 + y2 * y2 - y1 * y1;
    final b2 = r1 * r1 - r3 * r3 + x3 * x3 - x1 * x1 + y3 * y3 - y1 * y1;

    final det = a11 * a22 - a12 * a21;
    if (det.abs() < 1e-9) return null; // anchor segaris
    final x = (b1 * a22 - a12 * b2) / det;
    final y = (a11 * b2 - b1 * a21) / det;
    return (x, y);
  }
}
