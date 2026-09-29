import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:http/http.dart' as http;
import 'package:archive/archive.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/web_server.dart';
import '../services/project_manager.dart';

class DatabaseManagerScreen extends StatefulWidget {
  const DatabaseManagerScreen({super.key});

  @override
  State<DatabaseManagerScreen> createState() => _DatabaseManagerScreenState();
}

class _DatabaseManagerScreenState extends State<DatabaseManagerScreen> {
  bool _isPhpMyAdminInstalled = false;
  bool _isPhpMyAdminRunning = false;
  int _pmaPort = 8888;
  String _pmaPath = '';
  bool _isDownloading = false;
  double _downloadProgress = 0;
  String _status = '';

  @override
  void initState() {
    super.initState();
    _checkPhpMyAdmin();
  }

  Future<void> _checkPhpMyAdmin() async {
    final docDir = await getApplicationDocumentsDirectory();
    _pmaPath = '${docDir.path}/projects/phpmyadmin';
    final pmaDir = Directory(_pmaPath);
    final pmaIndex = File('$_pmaPath/index.php');

    setState(() {
      _isPhpMyAdminInstalled = pmaDir.existsSync() && pmaIndex.existsSync();
      final server = WebServerManager.getServer('phpmyadmin');
      _isPhpMyAdminRunning = server != null && server.isRunning;
      if (_isPhpMyAdminRunning) {
        _pmaPort = server!.port;
      }
    });
  }

  Future<void> _installPhpMyAdmin() async {
    setState(() {
      _isDownloading = true;
      _status = 'Downloading phpMyAdmin...';
      _downloadProgress = 0;
    });

    try {
      // Get unique port
      _pmaPort = await ProjectManager.getUniquePort(startFrom: 8888);

      final request = http.Request('GET', Uri.parse('https://files.phpmyadmin.net/phpMyAdmin/5.2.1/phpMyAdmin-5.2.1-all-languages.zip'));
      final response = await http.Client().send(request);

      if (response.statusCode != 200) throw Exception('Download failed (HTTP ${response.statusCode})');

      List<int> bytes = [];
      int totalBytes = response.contentLength ?? 0;
      int receivedBytes = 0;

      await for (var chunk in response.stream) {
        bytes.addAll(chunk);
        receivedBytes += chunk.length;
        if (totalBytes > 0) {
          setState(() => _downloadProgress = receivedBytes / totalBytes);
        }
      }

      setState(() {
        _status = 'Extracting phpMyAdmin...';
        _downloadProgress = 0;
      });

      final archive = ZipDecoder().decodeBytes(bytes);
      final dir = Directory(_pmaPath);
      if (!dir.existsSync()) dir.createSync(recursive: true);

      int count = 0;
      for (final file in archive) {
        final filename = file.name;
        if (file.isFile) {
          // Strip first directory level (phpMyAdmin-5.2.1-all-languages/)
          final relative = filename.substring(filename.indexOf('/') + 1);
          if (relative.isEmpty) continue;
          final outFile = File('$_pmaPath/$relative');
          outFile.createSync(recursive: true);
          outFile.writeAsBytesSync(file.content as List<int>);
          count++;
          if (count % 100 == 0) {
            setState(() => _downloadProgress = count / archive.length);
          }
        } else {
          final relative = filename.substring(filename.indexOf('/') + 1);
          if (relative.isNotEmpty) Directory('$_pmaPath/$relative').createSync(recursive: true);
        }
      }

      // Register as a project
      await ProjectManager.createProject(
        name: 'phpMyAdmin',
        type: 'phpMyAdmin',
        port: _pmaPort,
      );

      // Auto-start phpMyAdmin web server
      await _startPhpMyAdmin();

      setState(() {
        _isDownloading = false;
        _isPhpMyAdminInstalled = true;
        _status = 'phpMyAdmin installed and running at http://127.0.0.1:$_pmaPort';
      });

    } catch (e) {
      setState(() {
        _isDownloading = false;
        _status = 'Error: $e';
      });
    }
  }

  Future<void> _startPhpMyAdmin() async {
    final server = await WebServerManager.startServer('phpmyadmin', _pmaPath, _pmaPort);
    await ProjectManager.updateProjectStatus('phpmyadmin', server.isRunning ? 'running' : 'stopped');
    setState(() {
      _isPhpMyAdminRunning = server.isRunning;
    });
  }

  Future<void> _stopPhpMyAdmin() async {
    await WebServerManager.stopServer('phpmyadmin');
    await ProjectManager.updateProjectStatus('phpmyadmin', 'stopped');
    setState(() {
      _isPhpMyAdminRunning = false;
    });
  }

  Future<void> _openPhpMyAdmin() async {
    final url = Uri.parse('http://127.0.0.1:$_pmaPort');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Open browser: $url')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Database Manager')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // phpMyAdmin Section
          Card(
            elevation: 3,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.dashboard, color: Colors.blue, size: 32),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('phpMyAdmin', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            Text('Web-based database manager', style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                      ),
                      if (_isPhpMyAdminInstalled)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: _isPhpMyAdminRunning ? Colors.green.withOpacity(0.2) : Colors.grey.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _isPhpMyAdminRunning ? '● Running' : '○ Stopped',
                            style: TextStyle(color: _isPhpMyAdminRunning ? Colors.green : Colors.grey, fontWeight: FontWeight.bold, fontSize: 12),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (_isDownloading) ...[
                    LinearProgressIndicator(value: _downloadProgress > 0 ? _downloadProgress : null),
                    const SizedBox(height: 8),
                    Text(_status, style: const TextStyle(fontWeight: FontWeight.bold)),
                  ] else if (!_isPhpMyAdminInstalled) ...[
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _installPhpMyAdmin,
                        icon: const Icon(Icons.download),
                        label: const Text('INSTALL PHPMYADMIN'),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.blue, foregroundColor: Colors.white),
                      ),
                    ),
                  ] else ...[
                    // Clickable URL
                    if (_isPhpMyAdminRunning) ...[
                      GestureDetector(
                        onTap: _openPhpMyAdmin,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.green.withOpacity(0.3)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.link, color: Colors.lightBlueAccent),
                              const SizedBox(width: 8),
                              Text(
                                'http://127.0.0.1:$_pmaPort',
                                style: const TextStyle(color: Colors.lightBlueAccent, fontWeight: FontWeight.bold, fontSize: 16, decoration: TextDecoration.underline),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _isPhpMyAdminRunning ? _openPhpMyAdmin : _startPhpMyAdmin,
                            icon: Icon(_isPhpMyAdminRunning ? Icons.open_in_browser : Icons.play_arrow),
                            label: Text(_isPhpMyAdminRunning ? 'OPEN' : 'START'),
                            style: ElevatedButton.styleFrom(backgroundColor: Colors.green, foregroundColor: Colors.white),
                          ),
                        ),
                        if (_isPhpMyAdminRunning) ...[
                          const SizedBox(width: 8),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _stopPhpMyAdmin,
                              icon: const Icon(Icons.stop),
                              label: const Text('STOP'),
                              style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                  if (_status.isNotEmpty && !_isDownloading)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(_status, style: const TextStyle(color: Colors.green)),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          const Text('Database Info', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Host: 127.0.0.1', style: TextStyle(fontFamily: 'monospace')),
                  SizedBox(height: 4),
                  Text('Port: 3306', style: TextStyle(fontFamily: 'monospace')),
                  SizedBox(height: 4),
                  Text('Username: root', style: TextStyle(fontFamily: 'monospace')),
                  SizedBox(height: 4),
                  Text('Password: (empty)', style: TextStyle(fontFamily: 'monospace')),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
