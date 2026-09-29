import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import '../services/project_manager.dart';
import '../services/web_server.dart';

class LaravelWizardScreen extends StatefulWidget {
  const LaravelWizardScreen({super.key});

  @override
  State<LaravelWizardScreen> createState() => _LaravelWizardScreenState();
}

class _LaravelWizardScreenState extends State<LaravelWizardScreen> {
  final _projectNameCtrl = TextEditingController();
  final _dbNameCtrl = TextEditingController();
  int _port = 8000;

  bool _isCreating = false;
  String _status = '';

  @override
  void initState() {
    super.initState();
    _assignPort();
  }

  Future<void> _assignPort() async {
    final port = await ProjectManager.getUniquePort(startFrom: 8000);
    setState(() => _port = port);
  }

  Future<void> _createLaravelProject() async {
    if (_projectNameCtrl.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a project name.')));
      return;
    }

    setState(() {
      _isCreating = true;
      _status = 'Creating Laravel project structure...';
    });

    try {
      final project = await ProjectManager.createProject(
        name: _projectNameCtrl.text.trim(),
        type: 'Laravel',
        port: _port,
      );

      final projectDir = project['path'] as String;

      // Create a basic Laravel-like directory structure
      Directory('$projectDir/public').createSync(recursive: true);
      Directory('$projectDir/resources/views').createSync(recursive: true);
      Directory('$projectDir/routes').createSync(recursive: true);
      Directory('$projectDir/storage/logs').createSync(recursive: true);

      // Create public/index.html with Laravel welcome page
      File('$projectDir/public/index.html').writeAsStringSync('''
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>${_projectNameCtrl.text} - Laravel</title>
  <style>
    * { margin: 0; padding: 0; box-sizing: border-box; }
    body { font-family: 'Segoe UI', sans-serif; background: #0f0f23; color: #e0e0e0;
           display: flex; justify-content: center; align-items: center; min-height: 100vh; }
    .container { text-align: center; background: #1a1a3e; padding: 60px 40px; border-radius: 20px;
                 box-shadow: 0 20px 60px rgba(0,0,0,0.5); max-width: 600px; }
    h1 { font-size: 2.5em; color: #ff2d20; margin-bottom: 10px; }
    .badge { display: inline-block; background: #ff2d20; color: #fff; padding: 4px 16px;
             border-radius: 20px; font-size: 0.9em; font-weight: bold; margin-bottom: 20px; }
    p { color: #aaa; line-height: 1.8; }
    .links a { color: #ff2d20; text-decoration: none; margin: 0 8px; }
  </style>
</head>
<body>
  <div class="container">
    <h1>${_projectNameCtrl.text}</h1>
    <span class="badge">Laravel</span>
    <p>Your Laravel project is running on <strong>DevNest</strong>!</p>
    <p>URL: <code>http://127.0.0.1:$_port</code></p>
    <div class="links" style="margin-top: 20px;">
      <p>Place your Laravel files in this project's directory and edit via the File Manager.</p>
    </div>
  </div>
</body>
</html>
''');

      // Create artisan marker file (so ProjectManager detects it as Laravel)
      File('$projectDir/artisan').writeAsStringSync('#!/usr/bin/env php\n<?php\n// DevNest Laravel marker\n');

      // Create .env
      final dbName = _dbNameCtrl.text.isNotEmpty ? _dbNameCtrl.text : 'laravel';
      File('$projectDir/.env').writeAsStringSync('''
APP_NAME=${_projectNameCtrl.text}
APP_ENV=local
APP_KEY=base64:DevNestGeneratedKey000000000000000000=
APP_DEBUG=true
APP_URL=http://127.0.0.1:$_port

DB_CONNECTION=mysql
DB_HOST=127.0.0.1
DB_PORT=3306
DB_DATABASE=$dbName
DB_USERNAME=root
DB_PASSWORD=
''');

      // Auto-start the server (serve from /public as Laravel does)
      final server = await WebServerManager.startServer(
        project['safeName'],
        '$projectDir/public',
        _port,
      );
      await ProjectManager.updateProjectStatus(project['safeName'], server.isRunning ? 'running' : 'stopped');

      setState(() {
        _isCreating = false;
        _status = server.isRunning
            ? 'Laravel project created and running at ${server.url}'
            : 'Laravel project created! Start it from the Projects tab.';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Laravel ready at http://127.0.0.1:$_port')),
        );
      }
    } catch (e) {
      setState(() {
        _isCreating = false;
        _status = 'Error: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Laravel Project')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            TextField(controller: _projectNameCtrl, decoration: const InputDecoration(labelText: 'Project Name', hintText: 'My Laravel API', border: OutlineInputBorder())),
            const SizedBox(height: 16),
            TextField(controller: _dbNameCtrl, decoration: const InputDecoration(labelText: 'Database Name (optional)', hintText: 'laravel', border: OutlineInputBorder())),
            const SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(labelText: 'Port', border: const OutlineInputBorder()),
              keyboardType: TextInputType.number,
              controller: TextEditingController(text: '$_port'),
              onChanged: (val) => _port = int.tryParse(val) ?? _port,
            ),
            const SizedBox(height: 8),
            Text(
              'Your project will be at: http://127.0.0.1:$_port',
              style: const TextStyle(color: Colors.lightBlueAccent, fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 32),
            if (_isCreating) ...[
              const Center(child: CircularProgressIndicator()),
              const SizedBox(height: 16),
              Center(child: Text(_status, style: const TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
            ] else ...[
              ElevatedButton.icon(
                onPressed: _createLaravelProject,
                icon: const Icon(Icons.rocket_launch),
                label: const Text('CREATE LARAVEL PROJECT'),
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(16), backgroundColor: Colors.red.shade700, foregroundColor: Colors.white),
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
