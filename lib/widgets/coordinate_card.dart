import 'package:flutter/material.dart';

/// Kartu koordinat: lat, lon, elevasi.
class CoordinateCard extends StatelessWidget {
  final String title;
  final double? lat, lon, z;
  final String? footer;
  final IconData icon;
  final Color? color;

  const CoordinateCard({
    super.key,
    required this.title,
    this.lat,
    this.lon,
    this.z,
    this.footer,
    this.icon = Icons.my_location,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final has = lat != null && lon != null;
    return Card(
      color: color,
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(icon, size: 18),
            const SizedBox(width: 8),
            Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
          ]),
          const SizedBox(height: 8),
          if (!has)
            const Text('Menunggu data…')
          else ...[
            Text('Lat  ${lat!.toStringAsFixed(6)}', style: const TextStyle(fontFamily: 'monospace')),
            Text('Lon  ${lon!.toStringAsFixed(6)}', style: const TextStyle(fontFamily: 'monospace')),
            if (z != null)
              Text('Elev ${z!.toStringAsFixed(2)} m',
                  style: const TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold)),
          ],
          if (footer != null) ...[
            const SizedBox(height: 6),
            Text(footer!, style: Theme.of(context).textTheme.bodySmall),
          ],
        ]),
      ),
    );
  }
}
