import 'dart:io';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../services/web_server.dart';
import '../services/project_manager.dart';
import 'projects_screen.dart';
import 'terminal_screen.dart';
import 'file_manager_screen.dart';
import 'create_website_screen.dart';
import 'database_manager_screen.dart';
import 'php_manager_screen.dart';
import 'laravel_wizard_screen.dart';
import 'wordpress_wizard_screen.dart';
import 'git_manager_screen.dart';
import 'ssl_manager_screen.dart';
import 'logs_viewer_screen.dart';
import 'settings_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const HomeTab(),
    const ProjectsScreen(),
    const TerminalScreen(),
    const FileManagerScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard), label: 'Dashboard'),
          NavigationDestination(icon: Icon(Icons.folder), label: 'Projects'),
          NavigationDestination(icon: Icon(Icons.terminal), label: 'Terminal'),
          NavigationDestination(icon: Icon(Icons.file_copy), label: 'Files'),
        ],
      ),
    );
  }
}

class HomeTab extends StatefulWidget {
  const HomeTab({super.key});
  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  List<Map<String, dynamic>> _projects = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    final projects = await ProjectManager.loadProjects();
    for (var p in projects) {
      final server = WebServerManager.getServer(p['safeName']);
      p['status'] = (server != null && server.isRunning) ? 'running' : 'stopped';
    }
    setState(() {
      _projects = projects;
      _isLoading = false;
    });
  }

  Future<void> _startAllServers() async {
    for (var p in _projects) {
      await WebServerManager.startServer(p['safeName'], p['path'], p['port']);
      await ProjectManager.updateProjectStatus(p['safeName'], 'running');
    }
    await _loadData();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All servers started!')),
      );
    }
  }

  Future<void> _stopAllServers() async {
    await WebServerManager.stopAll();
    for (var p in _projects) {
      await ProjectManager.updateProjectStatus(p['safeName'], 'stopped');
    }
    await _loadData();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('All servers stopped.')),
      );
    }
  }

  Future<void> _openUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  int get _runningCount => _projects.where((p) => p['status'] == 'running').length;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('DevNest', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const SettingsScreen()));
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Server Status Banner
              Card(
                color: _runningCount > 0 ? Colors.green.shade900 : Colors.grey.shade800,
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      Icon(
                        _runningCount > 0 ? Icons.check_circle : Icons.cancel,
                        size: 40,
                        color: _runningCount > 0 ? Colors.greenAccent : Colors.grey,
                      ),
                      const SizedBox(width: 16),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _runningCount > 0 ? 'Server Running' : 'Server Stopped',
                            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '$_runningCount website(s) active • ${_projects.length} total',
                            style: TextStyle(color: Colors.grey.shade300),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Active Websites with clickable links
              if (_projects.isNotEmpty) ...[
                const Text('YOUR WEBSITES', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey)),
                const SizedBox(height: 8),
                ..._projects.map((p) {
                  final isRunning = p['status'] == 'running';
                  final url = 'http://127.0.0.1:${p['port']}';
                  return Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: Icon(
                        isRunning ? Icons.public : Icons.public_off,
                        color: isRunning ? Colors.green : Colors.grey,
                      ),
                      title: Text(p['name'], style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: isRunning
                          ? GestureDetector(
                              onTap: () => _openUrl(url),
                              child: Text(url, style: const TextStyle(color: Colors.lightBlueAccent, decoration: TextDecoration.underline)),
                            )
                          : Text('${p['type']} • Port ${p['port']}'),
                      trailing: isRunning
                          ? IconButton(
                              icon: const Icon(Icons.open_in_browser, color: Colors.lightBlueAccent),
                              onPressed: () => _openUrl(url),
                            )
                          : null,
                    ),
                  );
                }),
                const SizedBox(height: 16),
              ],

              // Quick Actions
              const Text('QUICK ACTIONS', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.grey)),
              const SizedBox(height: 8),
              _buildActionTile(context, Icons.add_circle, 'Create New Website', 'PHP, HTML, WordPress, Laravel, Node.js', const CreateWebsiteScreen()),
              _buildActionTile(context, Icons.install_desktop, 'Install WordPress', 'Download & auto-configure WordPress', const WordPressWizardScreen()),
              _buildActionTile(context, Icons.api, 'Create Laravel Project', 'Setup a Laravel environment', const LaravelWizardScreen()),
              _buildActionTile(context, Icons.data_usage, 'Database Manager', 'Manage MariaDB & phpMyAdmin', const DatabaseManagerScreen()),
              _buildActionTile(context, Icons.code, 'PHP Manager', 'PHP extensions & php.ini', const PhpManagerScreen()),
              _buildActionTile(context, Icons.integration_instructions, 'Git Integration', 'Clone & manage repositories', const GitManagerScreen()),
              _buildActionTile(context, Icons.security, 'SSL Manager', 'Local HTTPS certificates', const SslManagerScreen()),
              _buildActionTile(context, Icons.text_snippet, 'View Logs', 'Access & error logs', const LogsViewerScreen()),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _runningCount > 0 ? _stopAllServers : _startAllServers,
        icon: Icon(_runningCount > 0 ? Icons.stop : Icons.play_arrow),
        label: Text(_runningCount > 0 ? 'STOP ALL' : 'START ALL'),
        backgroundColor: _runningCount > 0 ? Colors.red.shade700 : Colors.green.shade700,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildActionTile(BuildContext context, IconData icon, String title, String subtitle, Widget destination) {
    return Card(
      margin: const EdgeInsets.only(bottom: 4),
      child: ListTile(
        leading: Icon(icon),
        title: Text(title),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12)),
        trailing: const Icon(Icons.chevron_right),
        onTap: () async {
          await Navigator.push(context, MaterialPageRoute(builder: (context) => destination));
          _loadData();
        },
      ),
    );
  }
}
