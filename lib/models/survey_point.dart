class SurveyPoint {
  final int? id;
  final DateTime time;
  final double lat, lon, z; // z = elevasi (m)
  final double bleRms; // sisa kuadrat terkecil multilaterasi (m)
  final double sigma; // perkiraan simpangan posisi hasil fusi (m)
  final double pressure; // hPa
  final double? gpsLat, gpsLon, gpsAcc;
  final int nAnchors;
  final String label;

  const SurveyPoint({
    this.id,
    required this.time,
    required this.lat,
    required this.lon,
    required this.z,
    required this.bleRms,
    required this.sigma,
    required this.pressure,
    this.gpsLat,
    this.gpsLon,
    this.gpsAcc,
    required this.nAnchors,
    this.label = '',
  });

  Map<String, Object?> toMap() => {
        'time': time.toIso8601String(),
        'lat': lat,
        'lon': lon,
        'z': z,
        'ble_rms': bleRms,
        'sigma': sigma,
        'pressure': pressure,
        'gps_lat': gpsLat,
        'gps_lon': gpsLon,
        'gps_acc': gpsAcc,
        'n_anchors': nAnchors,
        'label': label,
      };

  factory SurveyPoint.fromMap(Map<String, Object?> m) => SurveyPoint(
        id: m['id'] as int?,
        time: DateTime.parse(m['time'] as String),
        lat: (m['lat'] as num).toDouble(),
        lon: (m['lon'] as num).toDouble(),
        z: (m['z'] as num).toDouble(),
        bleRms: (m['ble_rms'] as num).toDouble(),
        sigma: (m['sigma'] as num).toDouble(),
        pressure: (m['pressure'] as num).toDouble(),
        gpsLat: (m['gps_lat'] as num?)?.toDouble(),
        gpsLon: (m['gps_lon'] as num?)?.toDouble(),
        gpsAcc: (m['gps_acc'] as num?)?.toDouble(),
        nAnchors: m['n_anchors'] as int,
        label: (m['label'] as String?) ?? '',
      );

  static const csvHeader =
      'id,waktu,lat,lon,elevasi_m,ble_rms_m,sigma_m,tekanan_hpa,n_anchor,gps_lat,gps_lon,gps_acc_m,label';

  String toCsvRow() => [
        id ?? '',
        time.toIso8601String(),
        lat.toStringAsFixed(7),
        lon.toStringAsFixed(7),
        z.toStringAsFixed(2),
        bleRms.toStringAsFixed(2),
        sigma.toStringAsFixed(2),
        pressure.toStringAsFixed(2),
        nAnchors,
        gpsLat?.toStringAsFixed(7) ?? '',
        gpsLon?.toStringAsFixed(7) ?? '',
        gpsAcc?.toStringAsFixed(1) ?? '',
        '"${label.replaceAll('"', '""')}"',
      ].join(',');
}
