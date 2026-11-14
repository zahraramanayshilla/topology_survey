import 'package:flutter/material.dart';

import '../services/database_service.dart';

/// Riwayat titik tersimpan: hapus per titik (geser), ekspor CSV, hapus semua.
class HistoryScreen extends StatelessWidget {
  const HistoryScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final db = DatabaseService.instance;
    return ListenableBuilder(
      listenable: db,
      builder: (context, _) {
        final pts = db.points.reversed.toList();
        return Scaffold(
          appBar: AppBar(title: Text('Riwayat (${pts.length})'), actions: [
            IconButton(
              tooltip: 'Ekspor CSV',
              icon: const Icon(Icons.ios_share),
              onPressed: pts.isEmpty ? null : db.exportCsv,
            ),
            IconButton(
              tooltip: 'Hapus semua',
              icon: const Icon(Icons.delete_sweep),
              onPressed: pts.isEmpty
                  ? null
                  : () async {
                      final ok = await showDialog<bool>(
                        context: context,
                        builder: (c) => AlertDialog(
                          title: const Text('Hapus semua titik?'),
                          actions: [
                            TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Batal')),
                            TextButton(onPressed: () => Navigator.pop(c, true), child: const Text('Hapus')),
                          ],
                        ),
                      );
                      if (ok == true) await db.clear();
                    },
            ),
          ]),
          body: pts.isEmpty
              ? const Center(child: Text('Belum ada titik tersimpan.'))
              : ListView.builder(
                  itemCount: pts.length,
                  itemBuilder: (_, i) {
                    final p = pts[i];
                    return Dismissible(
                      key: ValueKey(p.id),
                      background: Container(color: Colors.red),
                      onDismissed: (_) => db.delete(p.id!),
                      child: ListTile(
                        leading: CircleAvatar(child: Text('${p.id}')),
                        title: Text('z = ${p.z.toStringAsFixed(2)} m'
                            '${p.label.isEmpty ? "" : "  •  ${p.label}"}'),
                        subtitle: Text(
                            '${p.lat.toStringAsFixed(6)}, ${p.lon.toStringAsFixed(6)}\n'
                            'RMS ${p.bleRms.toStringAsFixed(1)} m | σ ${p.sigma.toStringAsFixed(1)} m | ${p.nAnchors} anchor'),
                        isThreeLine: true,
                      ),
                    );
                  },
                ),
        );
      },
    );
  }
}
