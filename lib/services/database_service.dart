import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:sqflite/sqflite.dart';

import '../models/survey_point.dart';

/// Penyimpanan lokal (SQLite) titik survei + ekspor CSV.
class DatabaseService extends ChangeNotifier {
  static final DatabaseService instance = DatabaseService._();
  DatabaseService._();

  Database? _db;
  List<SurveyPoint> points = [];

  Future<void> init() async {
    if (_db != null) return;
    final path = '${await getDatabasesPath()}/topo_survey.db';
    _db = await openDatabase(path, version: 1, onCreate: (db, _) async {
      await db.execute('''
        CREATE TABLE points(
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          time TEXT, lat REAL, lon REAL, z REAL,
          ble_rms REAL, sigma REAL, pressure REAL,
          gps_lat REAL, gps_lon REAL, gps_acc REAL,
          n_anchors INTEGER, label TEXT
        )''');
    });
    await load();
  }

  Future<void> load() async {
    final rows = await _db!.query('points', orderBy: 'id ASC');
    points = rows.map(SurveyPoint.fromMap).toList();
    notifyListeners();
  }

  Future<void> insert(SurveyPoint p) async {
    await _db!.insert('points', p.toMap());
    await load();
  }

  Future<void> delete(int id) async {
    await _db!.delete('points', where: 'id = ?', whereArgs: [id]);
    await load();
  }

  Future<void> clear() async {
    await _db!.delete('points');
    await load();
  }

  Future<void> exportCsv() async {
    final sb = StringBuffer('${SurveyPoint.csvHeader}\n');
    for (final p in points) {
      sb.writeln(p.toCsvRow());
    }
    final dir = await getTemporaryDirectory();
    final f = File('${dir.path}/topo_survey_${DateTime.now().millisecondsSinceEpoch}.csv');
    await f.writeAsString(sb.toString());
    await Share.shareXFiles([XFile(f.path)], text: 'Data survei topografi');
  }
}
