import 'package:flutter/material.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _lanAccess = false;
  bool _startAutomatically = false;
  bool _keepServerRunning = true;
  bool _darkTheme = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text('General', style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold)),
          SwitchListTile(
            title: const Text('Dark Theme'),
            value: _darkTheme,
            onChanged: (val) => setState(() => _darkTheme = val),
          ),
          SwitchListTile(
            title: const Text('Start Services Automatically'),
            value: _startAutomatically,
            onChanged: (val) => setState(() => _startAutomatically = val),
          ),
          SwitchListTile(
            title: const Text('Keep Server Running'),
            subtitle: const Text('Run in background (Foreground Service)'),
            value: _keepServerRunning,
            onChanged: (val) => setState(() => _keepServerRunning = val),
          ),
          const Divider(),
          const Text('Network & Server', style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold)),
          SwitchListTile(
            title: const Text('Allow LAN Access'),
            subtitle: const Text('Expose services to the local network (Warning)'),
            value: _lanAccess,
            onChanged: (val) {
              if (val) {
                _showSecurityWarning(context);
              } else {
                setState(() => _lanAccess = false);
              }
            },
          ),
          ListTile(
            title: const Text('Port Manager'),
            subtitle: const Text('Detect port conflicts (80, 8080, 3306)'),
            trailing: const Icon(Icons.arrow_forward_ios),
            onTap: () {},
          ),
          const Divider(),
          const Text('Advanced Configuration', style: TextStyle(color: Colors.blueAccent, fontWeight: FontWeight.bold)),
          ListTile(title: const Text('Edit nginx.conf'), trailing: const Icon(Icons.edit), onTap: () {}),
          ListTile(title: const Text('Edit php-fpm.conf'), trailing: const Icon(Icons.edit), onTap: () {}),
          ListTile(title: const Text('Edit my.cnf (MariaDB)'), trailing: const Icon(Icons.edit), onTap: () {}),
          ListTile(
            title: const Text('RESET TO DEFAULT', style: TextStyle(color: Colors.red)),
            onTap: () {},
          ),
        ],
      ),
    );
  }

  void _showSecurityWarning(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Security Warning'),
        content: const Text('Enabling LAN Access will allow anyone on your WiFi network to access your local development server. Ensure you have no sensitive data exposed.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
          ElevatedButton(
            onPressed: () {
              setState(() => _lanAccess = true);
              Navigator.pop(context);
            },
            child: const Text('ENABLE'),
          ),
        ],
      ),
    );
  }
}
