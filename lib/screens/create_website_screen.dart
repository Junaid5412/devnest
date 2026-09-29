import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import '../services/project_manager.dart';
import '../services/web_server.dart';

class CreateWebsiteScreen extends StatefulWidget {
  const CreateWebsiteScreen({super.key});

  @override
  State<CreateWebsiteScreen> createState() => _CreateWebsiteScreenState();
}

class _CreateWebsiteScreenState extends State<CreateWebsiteScreen> {
  final _nameController = TextEditingController();
  final _portController = TextEditingController();
  String _selectedType = 'Static HTML';
  int _port = 8080;
  bool _isCreating = false;

  final List<Map<String, dynamic>> _projectTypes = [
    {'name': 'Static HTML', 'icon': Icons.web, 'color': Colors.orange, 'desc': 'HTML, CSS, JS website'},
    {'name': 'PHP Website', 'icon': Icons.code, 'color': Colors.purple, 'desc': 'PHP website with index.php'},
    {'name': 'Node.js', 'icon': Icons.javascript, 'color': Colors.green, 'desc': 'Node.js application (serves static + JS)'},
    {'name': 'Custom', 'icon': Icons.folder, 'color': Colors.teal, 'desc': 'Empty project folder'},
  ];

  @override
  void initState() {
    super.initState();
    _assignPort();
  }

  Future<void> _assignPort() async {
    final port = await ProjectManager.getUniquePort(startFrom: 8080);
    setState(() {
      _port = port;
      _portController.text = '$port';
    });
  }

  Future<void> _createProject() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter a project name.')));
      return;
    }

    setState(() => _isCreating = true);

    try {
      final project = await ProjectManager.createProject(
        name: name,
        type: _selectedType,
        port: _port,
      );

      final projectPath = project['path'] as String;

      // Create type-specific files
      if (_selectedType == 'PHP Website') {
        File('$projectPath/index.php').writeAsStringSync('''
<!DOCTYPE html>
<html><head><title>$name</title>
<style>body{font-family:sans-serif;background:#1a1a2e;color:#e0e0e0;padding:40px;text-align:center;}
h1{color:#a855f7;}.info{background:#16213e;border-radius:12px;padding:20px;margin:20px auto;max-width:500px;}
code{background:#222;padding:2px 8px;border-radius:4px;color:#4fc3f7;}</style></head>
<body><h1>$name</h1><span style="background:#a855f7;color:#fff;padding:4px 12px;border-radius:12px;">PHP</span>
<div class="info"><p>🌐 Running at <code>http://127.0.0.1:$_port</code></p>
<p>📝 Edit this file in the DevNest File Manager</p></div></body></html>
''');
      } else if (_selectedType == 'Node.js') {
        // Create a Node.js project with package.json and a simple index.html
        File('$projectPath/package.json').writeAsStringSync('''
{
  "name": "${name.toLowerCase().replaceAll(' ', '-')}",
  "version": "1.0.0",
  "description": "$name - Created by DevNest",
  "main": "index.js",
  "scripts": {
    "start": "node index.js"
  }
}
''');
        File('$projectPath/index.js').writeAsStringSync('''
// $name - Node.js Project
// Created by DevNest
console.log("$name is running!");

// You can use this file for your Node.js application logic.
// The DevNest web server serves static files from this directory.
''');
        // Also create an index.html for the web server
        File('$projectPath/index.html').writeAsStringSync('''
<!DOCTYPE html>
<html><head><title>$name</title>
<style>body{font-family:sans-serif;background:#1a1a2e;color:#e0e0e0;padding:40px;text-align:center;}
h1{color:#00e676;}.info{background:#16213e;border-radius:12px;padding:20px;margin:20px auto;max-width:500px;}
code{background:#222;padding:2px 8px;border-radius:4px;color:#4fc3f7;}</style></head>
<body><h1>$name</h1><span style="background:#00e676;color:#000;padding:4px 12px;border-radius:12px;">Node.js</span>
<div class="info"><p>🌐 Running at <code>http://127.0.0.1:$_port</code></p>
<p>📦 package.json and index.js created</p>
<p>📝 Edit files in the DevNest File Manager</p></div></body></html>
''');
      }

      // Auto-start the web server
      final server = await WebServerManager.startServer(
        project['safeName'],
        projectPath,
        _port,
      );
      await ProjectManager.updateProjectStatus(project['safeName'], server.isRunning ? 'running' : 'stopped');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('✅ ${project['name']} is live at http://127.0.0.1:$_port'),
            duration: const Duration(seconds: 4),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    }
    setState(() => _isCreating = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create New Website')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Website Name',
                hintText: 'My Awesome Website',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.edit),
              ),
            ),
            const SizedBox(height: 24),
            const Text('Project Type', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            ...(_projectTypes.map((type) => Card(
              color: _selectedType == type['name'] ? Theme.of(context).colorScheme.primaryContainer : null,
              child: RadioListTile<String>(
                value: type['name'],
                groupValue: _selectedType,
                title: Row(
                  children: [
                    Icon(type['icon'] as IconData, color: type['color'] as Color),
                    const SizedBox(width: 12),
                    Text(type['name'] as String, style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
                subtitle: Text(type['desc'] as String),
                onChanged: (val) {
                  setState(() => _selectedType = val!);
                },
              ),
            ))),
            const SizedBox(height: 16),
            TextField(
              controller: _portController,
              decoration: const InputDecoration(
                labelText: 'Port',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.router),
              ),
              keyboardType: TextInputType.number,
              onChanged: (val) {
                _port = int.tryParse(val) ?? _port;
              },
            ),
            const SizedBox(height: 12),
            Card(
              color: Colors.blue.shade900,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    const Icon(Icons.link, color: Colors.lightBlueAccent),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Your website URL: http://127.0.0.1:$_port',
                        style: const TextStyle(color: Colors.lightBlueAccent, fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              height: 56,
              child: ElevatedButton.icon(
                onPressed: _isCreating ? null : _createProject,
                icon: _isCreating
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.rocket_launch),
                label: Text(_isCreating ? 'Creating...' : 'CREATE & START WEBSITE', style: const TextStyle(fontSize: 16)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green.shade700,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
