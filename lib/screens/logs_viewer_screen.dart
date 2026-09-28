import 'package:flutter/material.dart';

class LogsViewerScreen extends StatefulWidget {
  const LogsViewerScreen({super.key});

  @override
  State<LogsViewerScreen> createState() => _LogsViewerScreenState();
}

class _LogsViewerScreenState extends State<LogsViewerScreen> {
  String _selectedLog = 'Nginx Access Log';
  final List<String> _logs = [
    'Nginx Access Log',
    'Nginx Error Log',
    'PHP Error Log',
    'PHP-FPM Log',
    'MariaDB Log',
    'Node.js Logs',
    'Application Logs'
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Logs Viewer'),
        actions: [
          IconButton(icon: const Icon(Icons.copy), onPressed: () {}),
          IconButton(icon: const Icon(Icons.delete_sweep), onPressed: () {}),
          IconButton(icon: const Icon(Icons.download), onPressed: () {}),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: DropdownButton<String>(
              isExpanded: true,
              value: _selectedLog,
              items: _logs.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (val) {
                if (val != null) setState(() => _selectedLog = val);
              },
            ),
          ),
          Expanded(
            child: Container(
              width: double.infinity,
              color: Colors.black,
              padding: const EdgeInsets.all(8),
              child: const SingleChildScrollView(
                child: Text(
                  '[01/Oct/2026:12:00:00] "GET / HTTP/1.1" 200 1234\n'
                  '[01/Oct/2026:12:00:05] "POST /api/login HTTP/1.1" 401 56\n',
                  style: TextStyle(color: Colors.greenAccent, fontFamily: 'monospace'),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
