import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

class LogsViewerScreen extends StatefulWidget {
  const LogsViewerScreen({super.key});

  @override
  State<LogsViewerScreen> createState() => _LogsViewerScreenState();
}

class _LogsViewerScreenState extends State<LogsViewerScreen> {
  String _selectedLog = 'Nginx Access Log';
  String _logContent = 'Loading...';
  
  final Map<String, String> _logFilesMap = {
    'Nginx Access Log': 'nginx/logs/access.log',
    'Nginx Error Log': 'nginx/logs/error.log',
    'PHP Error Log': 'php/logs/php_error.log',
    'PHP-FPM Log': 'php/logs/php-fpm.log',
    'MariaDB Log': 'mariadb/data/mysql.err',
    'Node.js Logs': 'nodejs/logs/node.log',
  };

  @override
  void initState() {
    super.initState();
    _loadLogContent();
  }

  Future<void> _loadLogContent() async {
    setState(() => _logContent = 'Loading $_selectedLog...');
    try {
      final appSupportDir = await getApplicationSupportDirectory();
      final relativePath = _logFilesMap[_selectedLog]!;
      final logFile = File('${appSupportDir.path}/$relativePath');

      if (logFile.existsSync()) {
        final content = await logFile.readAsString();
        setState(() {
          _logContent = content.isEmpty ? '(Empty log file)' : content;
        });
      } else {
        setState(() {
          _logContent = 'Log file not found at $relativePath. The service may not have started yet or the logs are stored elsewhere.';
        });
      }
    } catch (e) {
      setState(() {
        _logContent = 'Failed to read log file: $e';
      });
    }
  }

  Future<void> _clearLog() async {
    try {
      final appSupportDir = await getApplicationSupportDirectory();
      final logFile = File('${appSupportDir.path}/${_logFilesMap[_selectedLog]}');
      if (logFile.existsSync()) {
        await logFile.writeAsString('');
        _loadLogContent();
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Log cleared.')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error clearing log: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Logs Viewer'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadLogContent),
          IconButton(icon: const Icon(Icons.delete_sweep), onPressed: _clearLog),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: DropdownButton<String>(
              isExpanded: true,
              value: _selectedLog,
              items: _logFilesMap.keys.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (val) {
                if (val != null) {
                  setState(() => _selectedLog = val);
                  _loadLogContent();
                }
              },
            ),
          ),
          Expanded(
            child: Container(
              width: double.infinity,
              color: Colors.black,
              padding: const EdgeInsets.all(8),
              child: SingleChildScrollView(
                child: Text(
                  _logContent,
                  style: const TextStyle(color: Colors.greenAccent, fontFamily: 'monospace'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
