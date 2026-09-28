import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/dashboard_screen.dart';
import 'screens/setup_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final bool isSetupComplete = prefs.getBool('is_setup_complete') ?? false;

  runApp(DevNestApp(isSetupComplete: isSetupComplete));
}

class DevNestApp extends StatelessWidget {
  final bool isSetupComplete;

  const DevNestApp({super.key, required this.isSetupComplete});

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
      home: isSetupComplete ? const DashboardScreen() : const SetupScreen(),
      debugShowCheckedModeBanner: false,
    );
  }
}
