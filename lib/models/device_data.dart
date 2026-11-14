import 'dart:typed_data';

/// Manufacturer-id & magic byte untuk paket beacon Anchor.
const int kMfgId = 0x0FFF;
const int kMagic = 0x54; // 'T'
const int kPacketLength = 14;

double median(List<num> v) {
  final s = v.map((e) => e.toDouble()).toList()..sort();
  final n = s.length;
  return n.isOdd ? s[n ~/ 2] : (s[n ~/ 2 - 1] + s[n ~/ 2]) / 2;
}

/// Data satu perangkat Anchor yang terdeteksi lewat BLE.
/// Paket (14 byte): magic, id, tekanan*100 (u32), lat*1e6 (i32), lon*1e6 (i32)
class DeviceData {
  final int id;
  double pressure; // hPa
  double lat, lon;
  DateTime lastSeen;
  final List<int> rssiWindow = [];

  DeviceData({
    required this.id,
    required this.pressure,
    required this.lat,
    required this.lon,
    required this.lastSeen,
  });

  static Uint8List encode({
    required int id,
    required double pressureHpa,
    required double lat,
    required double lon,
  }) {
    final b = ByteData(kPacketLength);
    b.setUint8(0, kMagic);
    b.setUint8(1, id);
    b.setUint32(2, (pressureHpa * 100).round());
    b.setInt32(6, (lat * 1e6).round());
    b.setInt32(10, (lon * 1e6).round());
    return b.buffer.asUint8List();
  }

  static DeviceData? decode(List<int> bytes) {
    if (bytes.length != kPacketLength || bytes[0] != kMagic) return null;
    final bd = ByteData.sublistView(Uint8List.fromList(bytes));
    return DeviceData(
      id: bytes[1],
      pressure: bd.getUint32(2) / 100.0,
      lat: bd.getInt32(6) / 1e6,
      lon: bd.getInt32(10) / 1e6,
      lastSeen: DateTime.now(),
    );
  }

  void addRssi(int rssi, {int window = 15}) {
    rssiWindow.add(rssi);
    if (rssiWindow.length > window) rssiWindow.removeAt(0);
  }

  double get medianRssi => median(rssiWindow);
  int get ageSeconds => DateTime.now().difference(lastSeen).inSeconds;
  bool isActive({int withinSeconds = 6}) =>
      rssiWindow.isNotEmpty && lat != 0 && ageSeconds <= withinSeconds;
}
