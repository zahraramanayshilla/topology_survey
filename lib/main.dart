import 'package:flutter/material.dart';

import 'screens/dashboard_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const TopoApp());
}

class TopoApp extends StatelessWidget {
  const TopoApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
        title: 'Topo Survey',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(colorSchemeSeed: Colors.teal, useMaterial3: true),
        home: const DashboardScreen(),
      );
}
