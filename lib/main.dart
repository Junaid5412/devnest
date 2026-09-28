import 'package:flutter/material.dart';
import 'screens/dashboard_screen.dart';

void main() {
  runApp(const DevNestApp());
}

class DevNestApp extends StatelessWidget {
  const DevNestApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'DevNest',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.blueAccent,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const DashboardScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
