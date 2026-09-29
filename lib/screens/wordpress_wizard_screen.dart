import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:archive/archive.dart';
import 'package:path_provider/path_provider.dart';
import '../services/project_manager.dart';
import '../services/web_server.dart';

class WordPressWizardScreen extends StatefulWidget {
  const WordPressWizardScreen({super.key});

  @override
  State<WordPressWizardScreen> createState() => _WordPressWizardScreenState();
}

class _WordPressWizardScreenState extends State<WordPressWizardScreen> {
  final _siteNameController = TextEditingController();
  final _dbNameController = TextEditingController();
  int _port = 8081;

  bool _isInstalling = false;
  double _progress = 0;
  String _status = '';

  @override
  void initState() {
    super.initState();
    _assignPort();
  }

  Future<void> _assignPort() async {
    final port = await ProjectManager.getUniquePort(startFrom: 8081);
    setState(() => _port = port);
  }

  Future<void> _installWordPress() async {
    if (_siteNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a site name.')));
      return;
    }

    setState(() {
      _isInstalling = true;
      _status = 'Downloading WordPress (this may take a minute)...';
      _progress = 0;
    });

    try {
      // Create project entry
      final project = await ProjectManager.createProject(
        name: _siteNameController.text.trim(),
        type: 'WordPress',
        port: _port,
      );

      final projectDir = project['path'] as String;

      // Download WordPress
      final request = http.Request('GET', Uri.parse('https://wordpress.org/latest.zip'));
      final response = await http.Client().send(request);
      
      if (response.statusCode != 200) throw Exception('Failed to download WordPress (HTTP ${response.statusCode})');

      List<int> bytes = [];
      int totalBytes = response.contentLength ?? 0;
      int receivedBytes = 0;

      await for (var chunk in response.stream) {
        bytes.addAll(chunk);
        receivedBytes += chunk.length;
        if (totalBytes > 0) {
          setState(() => _progress = receivedBytes / totalBytes);
        }
      }

      setState(() {
        _status = 'Extracting WordPress files...';
        _progress = 0;
      });

      final archive = ZipDecoder().decodeBytes(bytes);
      int fileCount = 0;
      for (final file in archive) {
        final filename = file.name;
        if (file.isFile) {
          final data = file.content as List<int>;
          final relativePath = filename.replaceFirst(RegExp(r'^wordpress/'), '');
          if (relativePath.isEmpty) continue;

          final outFile = File('$projectDir/$relativePath');
          outFile.createSync(recursive: true);
          outFile.writeAsBytesSync(data);
          fileCount++;
          if (fileCount % 50 == 0) {
            setState(() => _progress = fileCount / archive.length);
          }
        } else {
          final relativePath = filename.replaceFirst(RegExp(r'^wordpress/'), '');
          if (relativePath.isNotEmpty) {
            Directory('$projectDir/$relativePath').createSync(recursive: true);
          }
        }
      }

      setState(() => _status = 'Configuring WordPress...');

      // Configure wp-config.php
      final sampleConfig = File('$projectDir/wp-config-sample.php');
      if (sampleConfig.existsSync()) {
        String configContent = sampleConfig.readAsStringSync();
        final dbName = _dbNameController.text.isNotEmpty ? _dbNameController.text : 'wordpress';
        configContent = configContent.replaceAll('database_name_here', dbName);
        configContent = configContent.replaceAll('username_here', 'root');
        configContent = configContent.replaceAll('password_here', '');
        configContent = configContent.replaceAll('localhost', '127.0.0.1');
        File('$projectDir/wp-config.php').writeAsStringSync(configContent);
      }

      // Auto-start the web server for this project
      final server = await WebServerManager.startServer(
        project['safeName'],
        projectDir,
        _port,
      );
      await ProjectManager.updateProjectStatus(project['safeName'], server.isRunning ? 'running' : 'stopped');

      setState(() {
        _isInstalling = false;
        _status = server.isRunning
            ? 'WordPress installed and running at ${server.url}'
            : 'WordPress installed! Start it from the Projects tab.';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('WordPress ready at http://127.0.0.1:$_port')),
        );
      }
    } catch (e) {
      setState(() {
        _isInstalling = false;
        _status = 'Error: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Install WordPress')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            TextField(
              controller: _siteNameController,
              decoration: const InputDecoration(labelText: 'Site Name', hintText: 'My WordPress Site', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _dbNameController,
              decoration: const InputDecoration(labelText: 'Database Name (optional)', hintText: 'wordpress', border: OutlineInputBorder()),
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(labelText: 'Port', border: const OutlineInputBorder()),
              keyboardType: TextInputType.number,
              controller: TextEditingController(text: '$_port'),
              onChanged: (val) => _port = int.tryParse(val) ?? _port,
            ),
            const SizedBox(height: 8),
            Text(
              'Your site will be at: http://127.0.0.1:$_port',
              style: const TextStyle(color: Colors.lightBlueAccent, fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 32),
            if (_isInstalling) ...[
              LinearProgressIndicator(value: _progress > 0 ? _progress : null),
              const SizedBox(height: 16),
              Center(child: Text(_status, style: const TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
            ] else ...[
              ElevatedButton.icon(
                onPressed: _installWordPress,
                icon: const Icon(Icons.download),
                label: const Text('DOWNLOAD & INSTALL WORDPRESS'),
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(16), backgroundColor: Colors.blue.shade700, foregroundColor: Colors.white),
              ),
              if (_status.isNotEmpty) ...[
                const SizedBox(height: 16),
                Center(child: Text(_status, style: const TextStyle(color: Colors.green), textAlign: TextAlign.center)),
              ]
            ]
          ],
        ),
      ),
    );
  }
}
