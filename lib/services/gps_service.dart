import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:sensors_plus/sensors_plus.dart';

/// GPS + barometer. Juga merata-ratakan posisi GPS (untuk mode Anchor).
class GpsService extends ChangeNotifier {
  static final GpsService instance = GpsService._();
  GpsService._();

  Position? position;
  double? pressure; // hPa, sudah dihaluskan (EMA)

  // rata-rata GPS untuk Anchor
  double meanLat = 0, meanLon = 0;
  int samples = 0;
  bool locked = false;

  StreamSubscription? _pos, _baro;
  bool _started = false;

  static Future<bool> requestPermissions() async {
    final r = await [
      Permission.locationWhenInUse,
      Permission.bluetoothScan,
      Permission.bluetoothConnect,
      Permission.bluetoothAdvertise,
    ].request();
    return r[Permission.locationWhenInUse]?.isGranted ?? false;
  }

  Future<void> start() async {
    if (_started) return;
    _started = true;
    _pos = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.best),
    ).listen((p) {
      position = p;
      if (!locked && p.accuracy <= 30) {
        samples++;
        meanLat += (p.latitude - meanLat) / samples;
        meanLon += (p.longitude - meanLon) / samples;
      }
      notifyListeners();
    }, onError: (_) {});
    _baro = barometerEventStream().listen((e) {
      pressure = pressure == null ? e.pressure : pressure! * 0.9 + e.pressure * 0.1;
    }, onError: (_) {});
  }

  void resetAveraging() {
    meanLat = 0;
    meanLon = 0;
    samples = 0;
    locked = false;
    notifyListeners();
  }

  void setLocked(bool v) {
    locked = v;
    notifyListeners();
  }

  Future<void> stop() async {
    await _pos?.cancel();
    await _baro?.cancel();
    _started = false;
  }
}
