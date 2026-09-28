import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

class ProjectsScreen extends StatefulWidget {
  const ProjectsScreen({super.key});

  @override
  State<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends State<ProjectsScreen> {
  List<Map<String, String>> _projects = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProjects();
  }

  Future<void> _loadProjects() async {
    setState(() => _isLoading = true);
    try {
      final docDir = await getApplicationDocumentsDirectory();
      final projectsDir = Directory('${docDir.path}/projects');
      
      if (!projectsDir.existsSync()) {
        projectsDir.createSync(recursive: true);
      }

      final List<Map<String, String>> loadedProjects = [];
      
      final entities = projectsDir.listSync();
      for (final entity in entities) {
        if (entity is Directory) {
          final name = entity.path.split(Platform.pathSeparator).last;
          String type = 'Custom PHP';
          
          if (File('${entity.path}/artisan').existsSync()) {
            type = 'Laravel';
          } else if (File('${entity.path}/wp-config.php').existsSync() || File('${entity.path}/wp-login.php').existsSync()) {
            type = 'WordPress';
          } else if (File('${entity.path}/package.json').existsSync()) {
            type = 'Node.js';
          }

          loadedProjects.add({
            'name': name,
            'type': type,
            'path': entity.path,
            'status': 'Stopped', // Real status tracking would go here
          });
        }
      }

      setState(() {
        _projects = loadedProjects;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _startProject(String path, String type) async {
    final appSupportDir = await getApplicationSupportDirectory();
    final phpBin = '${appSupportDir.path}/bin/php';
    final nodeBin = '${appSupportDir.path}/bin/node';
    
    try {
      if (type == 'Laravel') {
        Process.run(phpBin, ['artisan', 'serve', '--host=127.0.0.1', '--port=8000'], workingDirectory: path);
      } else if (type == 'Node.js') {
        Process.run(nodeBin, ['npm', 'start'], workingDirectory: path);
      } else {
        Process.run(phpBin, ['-S', '127.0.0.1:8080'], workingDirectory: path);
      }
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Project Started')));
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to start: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Projects'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadProjects)
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator()) 
        : _projects.isEmpty 
          ? const Center(child: Text('No projects found. Create one from the Dashboard.'))
          : ListView.builder(
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
                      project['type'] == 'Laravel' ? Icons.api :
                      project['type'] == 'Node.js' ? Icons.javascript : Icons.folder,
                      size: 32,
                    ),
                    title: Text(project['name']!, style: const TextStyle(fontWeight: FontWeight.bold)),
                    subtitle: Text('${project['type']}'),
                    trailing: Icon(isRunning ? Icons.play_circle : Icons.stop_circle, 
                      color: isRunning ? Colors.green : Colors.grey),
                    children: [
                      ButtonBar(
                        alignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          TextButton.icon(
                            icon: const Icon(Icons.play_arrow), 
                            label: const Text('Start'), 
                            onPressed: () => _startProject(project['path']!, project['type']!)
                          ),
                          TextButton.icon(icon: const Icon(Icons.stop), label: const Text('Stop'), onPressed: () {}),
                          TextButton.icon(icon: const Icon(Icons.delete, color: Colors.red), label: const Text('Delete', style: TextStyle(color: Colors.red)), 
                            onPressed: () {
                               Directory(project['path']!).deleteSync(recursive: true);
                               _loadProjects();
                            }
                          ),
                        ],
                      )
                    ],
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _loadProjects,
        icon: const Icon(Icons.sync),
        label: const Text('REFRESH'),
      ),
    );
  }
}
