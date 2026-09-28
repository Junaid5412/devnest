import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

class PhpManagerScreen extends StatefulWidget {
  const PhpManagerScreen({super.key});

  @override
  State<PhpManagerScreen> createState() => _PhpManagerScreenState();
}

class _PhpManagerScreenState extends State<PhpManagerScreen> {
  String _phpIniPath = '';
  List<String> _phpIniLines = [];
  bool _isLoading = true;

  final List<String> _availableExtensions = [
    'mysqli', 'pdo_mysql', 'curl', 'openssl', 'mbstring', 
    'gd', 'zip', 'dom', 'bcmath', 'sodium', 'fileinfo', 'intl'
  ];

  final Map<String, bool> _extensionsState = {};

  @override
  void initState() {
    super.initState();
    _loadPhpIni();
  }

  Future<void> _loadPhpIni() async {
    try {
      final appSupportDir = await getApplicationSupportDirectory();
      _phpIniPath = '${appSupportDir.path}/config/php.ini';
      
      final file = File(_phpIniPath);
      if (!file.existsSync()) {
        // Create dummy for testing if it doesn't exist
        file.createSync(recursive: true);
        file.writeAsStringSync('; Dummy php.ini\nextension=mysqli\n;extension=curl\n');
      }

      _phpIniLines = file.readAsLinesSync();
      
      // Parse extensions
      for (var ext in _availableExtensions) {
        _extensionsState[ext] = false;
        for (var line in _phpIniLines) {
          if (line.trim() == 'extension=$ext' || line.trim() == 'extension=$ext.so') {
            _extensionsState[ext] = true;
            break;
          }
        }
      }

      setState(() => _isLoading = false);
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleExtension(String ext, bool enable) async {
    setState(() {
      _extensionsState[ext] = enable;
    });

    // Update php.ini content
    bool found = false;
    for (int i = 0; i < _phpIniLines.length; i++) {
      final line = _phpIniLines[i].trim();
      if (line == 'extension=$ext' || line == ';extension=$ext' || line == 'extension=$ext.so' || line == ';extension=$ext.so') {
        _phpIniLines[i] = enable ? 'extension=$ext' : ';extension=$ext';
        found = true;
        break;
      }
    }

    if (!found && enable) {
      _phpIniLines.add('extension=$ext');
    }

    final file = File(_phpIniPath);
    await file.writeAsString(_phpIniLines.join('\n'));
    
    if(mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('php.ini updated. Please restart PHP-FPM.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return Scaffold(
      appBar: AppBar(title: const Text('PHP Manager')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const ListTile(
            title: Text('PHP Version'),
            subtitle: Text('8.2.0 (ARM64)'),
            trailing: Icon(Icons.arrow_forward_ios),
          ),
          const Divider(),
          ListTile(
            title: const Text('Edit php.ini'),
            subtitle: Text(_phpIniPath),
            trailing: const Icon(Icons.edit),
            onTap: () {
              // Should open code editor
            },
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: Text('PHP Extensions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          ..._availableExtensions.map((ext) => SwitchListTile(
            title: Text(ext),
            value: _extensionsState[ext] ?? false,
            onChanged: (val) => _toggleExtension(ext, val),
          )),
        ],
      ),
    );
  }
}
