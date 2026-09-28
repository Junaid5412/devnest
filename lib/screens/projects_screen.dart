import 'package:flutter/material.dart';

class ProjectsScreen extends StatefulWidget {
  const ProjectsScreen({super.key});

  @override
  State<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends State<ProjectsScreen> {
  final List<Map<String, String>> _projects = [
    {'name': 'WordPress Test', 'type': 'WordPress', 'port': '8080', 'status': 'Running'},
    {'name': 'Laravel API', 'type': 'Laravel', 'port': '8000', 'status': 'Stopped'},
    {'name': 'Node Backend', 'type': 'Node.js', 'port': '3000', 'status': 'Stopped'},
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Projects')),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _projects.length,
        itemBuilder: (context, index) {
          final project = _projects[index];
          final isRunning = project['status'] == 'Running';
          return Card(
            elevation: 2,
            margin: const EdgeInsets.only(bottom: 12),
            child: ExpansionTile(
              leading: Icon(
                project['type'] == 'WordPress' ? Icons.language :
                project['type'] == 'Laravel' ? Icons.api : Icons.javascript,
                size: 32,
              ),
              title: Text(project['name']!, style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('${project['type']} • Port ${project['port']}'),
              trailing: Icon(isRunning ? Icons.play_circle : Icons.stop_circle, 
                color: isRunning ? Colors.green : Colors.grey),
              children: [
                ButtonBar(
                  alignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    TextButton.icon(icon: const Icon(Icons.play_arrow), label: const Text('Start'), onPressed: () {}),
                    TextButton.icon(icon: const Icon(Icons.stop), label: const Text('Stop'), onPressed: () {}),
                    TextButton.icon(icon: const Icon(Icons.settings), label: const Text('Config'), onPressed: () {}),
                    TextButton.icon(icon: const Icon(Icons.folder), label: const Text('Files'), onPressed: () {}),
                  ],
                )
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // TODO: Open New Project Wizard
        },
        icon: const Icon(Icons.add),
        label: const Text('NEW PROJECT'),
      ),
    );
  }
}
