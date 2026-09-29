import 'dart:io';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/web_server.dart';
import '../services/project_manager.dart';
import 'create_website_screen.dart';

class ProjectsScreen extends StatefulWidget {
  const ProjectsScreen({super.key});

  @override
  State<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends State<ProjectsScreen> {
  List<Map<String, dynamic>> _projects = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProjects();
  }

  Future<void> _loadProjects() async {
    setState(() => _isLoading = true);
    final projects = await ProjectManager.loadProjects();
    
    // Sync running status with WebServerManager
    for (var p in projects) {
      final server = WebServerManager.getServer(p['safeName']);
      p['status'] = (server != null && server.isRunning) ? 'running' : 'stopped';
    }
    
    setState(() {
      _projects = projects;
      _isLoading = false;
    });
  }

  Future<void> _startProject(Map<String, dynamic> project) async {
    final server = await WebServerManager.startServer(
      project['safeName'],
      project['path'],
      project['port'],
    );

    if (server.isRunning) {
      await ProjectManager.updateProjectStatus(project['safeName'], 'running');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${project['name']} started at ${server.url}')),
        );
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to start ${project['name']}. Port ${project['port']} may be in use.')),
        );
      }
    }
    _loadProjects();
  }

  Future<void> _stopProject(Map<String, dynamic> project) async {
    await WebServerManager.stopServer(project['safeName']);
    await ProjectManager.updateProjectStatus(project['safeName'], 'stopped');
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${project['name']} stopped.')),
      );
    }
    _loadProjects();
  }

  Future<void> _openInBrowser(Map<String, dynamic> project) async {
    final url = Uri.parse('http://127.0.0.1:${project['port']}');
    if (await canLaunchUrl(url)) {
      await launchUrl(url, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Cannot open browser. URL: $url')),
        );
      }
    }
  }

  Future<void> _deleteProject(Map<String, dynamic> project) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Project'),
        content: Text('Are you sure you want to delete "${project['name']}"? All files will be permanently removed.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('CANCEL')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('DELETE'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await WebServerManager.stopServer(project['safeName']);
      await ProjectManager.deleteProject(project['safeName']);
      _loadProjects();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Projects'),
        actions: [
          IconButton(icon: const Icon(Icons.refresh), onPressed: _loadProjects),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _projects.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.folder_open, size: 80, color: Colors.grey),
                      const SizedBox(height: 16),
                      const Text('No projects yet', style: TextStyle(fontSize: 20, color: Colors.grey)),
                      const SizedBox(height: 8),
                      const Text('Tap + to create your first website', style: TextStyle(color: Colors.grey)),
                    ],
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _projects.length,
                  itemBuilder: (context, index) => _buildProjectCard(_projects[index]),
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreateWebsiteScreen()),
          );
          _loadProjects();
        },
        icon: const Icon(Icons.add),
        label: const Text('NEW WEBSITE'),
      ),
    );
  }

  Widget _buildProjectCard(Map<String, dynamic> project) {
    final isRunning = project['status'] == 'running';
    final projectUrl = 'http://127.0.0.1:${project['port']}';

    IconData typeIcon;
    Color typeColor;
    switch (project['type']) {
      case 'WordPress': typeIcon = Icons.language; typeColor = Colors.blue;
      case 'Laravel': typeIcon = Icons.api; typeColor = Colors.red;
      case 'Node.js': typeIcon = Icons.javascript; typeColor = Colors.green;
      case 'Static HTML': typeIcon = Icons.web; typeColor = Colors.orange;
      default: typeIcon = Icons.code; typeColor = Colors.purple;
    }

    return Card(
      elevation: 3,
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        children: [
          ListTile(
            leading: CircleAvatar(
              backgroundColor: typeColor.withOpacity(0.2),
              child: Icon(typeIcon, color: typeColor),
            ),
            title: Text(project['name'], style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
            subtitle: Text('${project['type']} • Port ${project['port']}'),
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isRunning ? Colors.green.withOpacity(0.2) : Colors.grey.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                isRunning ? '● Running' : '○ Stopped',
                style: TextStyle(color: isRunning ? Colors.green : Colors.grey, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          if (isRunning)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: Colors.green.withOpacity(0.1),
              child: Row(
                children: [
                  const Icon(Icons.link, size: 16, color: Colors.green),
                  const SizedBox(width: 8),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _openInBrowser(project),
                      child: Text(
                        projectUrl,
                        style: const TextStyle(
                          color: Colors.lightBlueAccent,
                          decoration: TextDecoration.underline,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.open_in_browser, color: Colors.lightBlueAccent),
                    onPressed: () => _openInBrowser(project),
                    tooltip: 'Open in Browser',
                  ),
                ],
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                if (!isRunning)
                  TextButton.icon(
                    icon: const Icon(Icons.play_arrow, color: Colors.green),
                    label: const Text('Start', style: TextStyle(color: Colors.green)),
                    onPressed: () => _startProject(project),
                  )
                else
                  TextButton.icon(
                    icon: const Icon(Icons.stop, color: Colors.red),
                    label: const Text('Stop', style: TextStyle(color: Colors.red)),
                    onPressed: () => _stopProject(project),
                  ),
                if (isRunning)
                  TextButton.icon(
                    icon: const Icon(Icons.open_in_browser, color: Colors.blue),
                    label: const Text('Open', style: TextStyle(color: Colors.blue)),
                    onPressed: () => _openInBrowser(project),
                  ),
                TextButton.icon(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  label: const Text('Delete', style: TextStyle(color: Colors.red)),
                  onPressed: () => _deleteProject(project),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
