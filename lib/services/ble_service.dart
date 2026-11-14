import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter_ble_peripheral/flutter_ble_peripheral.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';

import '../models/device_data.dart';
import 'gps_service.dart';

/// BLE: scan beacon Anchor (peran Rover) dan/atau pancarkan beacon (peran Anchor).
class BleService extends ChangeNotifier {
  static final BleService instance = BleService._();
  BleService._();

  final Map<int, DeviceData> devices = {};
  double txPower = -59; // RSSI pada jarak 1 m (dBm)
  double pathN = 2.5; // eksponen path-loss
  bool scanning = false, advertising = false;
  int anchorId = 1;

  StreamSubscription? _scanSub;
  Timer? _tick, _advTimer;
  final FlutterBlePeripheral _peripheral = FlutterBlePeripheral();

  List<DeviceData> get activeDevices =>
      devices.values.where((d) => d.isActive()).toList()..sort((a, b) => a.id.compareTo(b.id));

  double distanceOf(DeviceData d) =>
      math.pow(10, (txPower - d.medianRssi) / (10 * pathN)).toDouble();

  void setTxPower(double v) {
    txPower = v;
    notifyListeners();
  }

  void setPathN(double v) {
    pathN = v;
    notifyListeners();
  }

  /// Dekatkan HP ke satu anchor (~1 m), lalu panggil ini.
  void calibrateAt1m() {
    final act = activeDevices;
    if (act.isEmpty) return;
    act.sort((a, b) => b.medianRssi.compareTo(a.medianRssi));
    txPower = act.first.medianRssi;
    notifyListeners();
  }

  Future<void> startScan() async {
    if (scanning) return;
    scanning = true;
    _scanSub = FlutterBluePlus.onScanResults.listen((results) {
      for (final r in results) {
        final raw = r.advertisementData.manufacturerData[kMfgId];
        if (raw == null) continue;
        final parsed = DeviceData.decode(raw);
        if (parsed == null) continue;
        final dev = devices.putIfAbsent(parsed.id, () => parsed);
        dev.pressure = parsed.pressure;
        dev.lat = parsed.lat;
        dev.lon = parsed.lon;
        dev.lastSeen = DateTime.now();
        dev.addRssi(r.rssi);
      }
    });
    try {
      await FlutterBluePlus.startScan(
        continuousUpdates: true,
        androidScanMode: AndroidScanMode.lowLatency,
      );
    } catch (e) {
      debugPrint('scan error: $e');
    }
    _tick = Timer.periodic(const Duration(seconds: 1), (_) => notifyListeners());
    notifyListeners();
  }

  Future<void> stopScan() async {
    _tick?.cancel();
    await _scanSub?.cancel();
    try {
      await FlutterBluePlus.stopScan();
    } catch (_) {}
    scanning = false;
    notifyListeners();
  }

  Future<void> startAdvertising(int id) async {
    anchorId = id;
    advertising = true;
    await _advertiseOnce();
    _advTimer?.cancel();
    _advTimer = Timer.periodic(const Duration(seconds: 4), (_) => _advertiseOnce());
    notifyListeners();
  }

  Future<void> stopAdvertising() async {
    _advTimer?.cancel();
    advertising = false;
    try {
      await _peripheral.stop();
    } catch (_) {}
    notifyListeners();
  }

  Future<void> _advertiseOnce() async {
    final gps = GpsService.instance;
    if (!advertising || gps.samples == 0 || gps.pressure == null) return;
    final bytes = DeviceData.encode(
      id: anchorId,
      pressureHpa: gps.pressure!,
      lat: gps.meanLat,
      lon: gps.meanLon,
    );
    try {
      await _peripheral.stop();
      await _peripheral.start(
        advertiseData: AdvertiseData(
          manufacturerId: kMfgId,
          manufacturerData: bytes,
          includeDeviceName: false,
        ),
        advertiseSettings: AdvertiseSettings(
          advertiseMode: AdvertiseMode.advertiseModeLowLatency,
          txPowerLevel: AdvertiseTxPower.advertiseTxPowerHigh,
          connectable: false,
          timeout: 0,
        ),
      );
    } catch (e) {
      debugPrint('advertise error: $e');
    }
  }
}
