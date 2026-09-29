import 'package:flutter/material.dart';
import '../services/project_manager.dart';
import '../services/web_server.dart';

class CreateWebsiteScreen extends StatefulWidget {
  const CreateWebsiteScreen({super.key});

  @override
  State<CreateWebsiteScreen> createState() => _CreateWebsiteScreenState();
}

class _CreateWebsiteScreenState extends State<CreateWebsiteScreen> {
  final _nameController = TextEditingController();
  String _selectedType = 'Static HTML';
  int _port = 8080;
  bool _isCreating = false;

  final List<Map<String, dynamic>> _projectTypes = [
    {'name': 'Static HTML', 'icon': Icons.web, 'color': Colors.orange, 'desc': 'HTML, CSS, JS website'},
    {'name': 'PHP Website', 'icon': Icons.code, 'color': Colors.purple, 'desc': 'PHP website with index.php'},
    {'name': 'WordPress', 'icon': Icons.language, 'color': Colors.blue, 'desc': 'WordPress CMS installation'},
    {'name': 'Laravel', 'icon': Icons.api, 'color': Colors.red, 'desc': 'Laravel PHP framework'},
    {'name': 'Node.js', 'icon': Icons.javascript, 'color': Colors.green, 'desc': 'Node.js application'},
    {'name': 'Custom', 'icon': Icons.folder, 'color': Colors.teal, 'desc': 'Empty project folder'},
  ];

  @override
  void initState() {
    super.initState();
    _findAvailablePort();
  }

  void _findAvailablePort() {
    _port = WebServerManager.findAvailablePort(startFrom: 8080);
  }

  Future<void> _createProject() async {
    if (_nameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a project name.')),
      );
      return;
    }

    setState(() => _isCreating = true);

    try {
      final project = await ProjectManager.createProject(
        name: _nameController.text.trim(),
        type: _selectedType,
        port: _port,
      );

      // Auto-start the server
      final server = await WebServerManager.startServer(
        project['safeName'],
        project['path'],
        project['port'],
      );
      await ProjectManager.updateProjectStatus(project['safeName'], server.isRunning ? 'running' : 'stopped');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${project['name']} created and running at ${server.url}')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
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
            ...(_projectTypes.map((type) => RadioListTile<String>(
              value: type['name'],
              groupValue: _selectedType,
              title: Row(
                children: [
                  Icon(type['icon'], color: type['color']),
                  const SizedBox(width: 12),
                  Text(type['name']),
                ],
              ),
              subtitle: Text(type['desc']),
              onChanged: (val) {
                setState(() => _selectedType = val!);
              },
            ))),
            const SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(
                labelText: 'Port',
                hintText: '$_port',
                border: const OutlineInputBorder(),
                prefixIcon: const Icon(Icons.router),
              ),
              keyboardType: TextInputType.number,
              onChanged: (val) {
                _port = int.tryParse(val) ?? _port;
              },
              controller: TextEditingController(text: '$_port'),
            ),
            const SizedBox(height: 8),
            Text(
              'Your website will be available at: http://127.0.0.1:$_port',
              style: const TextStyle(color: Colors.lightBlueAccent, fontStyle: FontStyle.italic),
            ),
            const SizedBox(height: 32),
            ElevatedButton.icon(
              onPressed: _isCreating ? null : _createProject,
              icon: _isCreating ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.rocket_launch),
              label: Text(_isCreating ? 'Creating...' : 'CREATE & START WEBSITE'),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.all(16),
                backgroundColor: Colors.green.shade700,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
