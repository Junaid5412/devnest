import 'package:flutter/material.dart';
import '../services/native_bridge.dart';
import 'projects_screen.dart';
import 'terminal_screen.dart';
import 'file_manager_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;
  bool _isServiceRunning = false;

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

// Extract Home Tab into its own widget to keep dashboard clean
class HomeTab extends StatefulWidget {
  const HomeTab({super.key});
  @override
  State<HomeTab> createState() => _HomeTabState();
}

class _HomeTabState extends State<HomeTab> {
  bool _isServiceRunning = false;

  void _toggleServices() async {
    bool result = false;
    if (_isServiceRunning) {
      result = await NativeBridge.stopServerService();
    } else {
      result = await NativeBridge.startServerService();
    }
    
    setState(() {
      _isServiceRunning = !_isServiceRunning;
    });
    
    if(mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_isServiceRunning ? 'Servers Started' : 'Servers Stopped')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('DevNest', style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          IconButton(icon: const Icon(Icons.settings), onPressed: () {}),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStatusHeader(),
            const SizedBox(height: 24),
            const Text('SERVICES', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey)),
            const SizedBox(height: 12),
            _buildServiceCards(),
            const SizedBox(height: 24),
            const Text('QUICK ACTIONS', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey)),
            const SizedBox(height: 12),
            ListTile(
              leading: const Icon(Icons.update),
              title: const Text('Update Components'),
              subtitle: const Text('Check for Nginx, PHP, MariaDB updates'),
              onTap: () {},
            ),
             ListTile(
              leading: const Icon(Icons.text_snippet),
              title: const Text('View Logs'),
              subtitle: const Text('View access and error logs'),
              onTap: () {},
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _toggleServices,
        icon: Icon(_isServiceRunning ? Icons.stop : Icons.play_arrow),
        label: Text(_isServiceRunning ? 'STOP ALL' : 'START ALL'),
        backgroundColor: _isServiceRunning ? Colors.red.shade700 : Colors.green.shade700,
        foregroundColor: Colors.white,
      ),
    );
  }

  Widget _buildStatusHeader() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildMetricItem(Icons.public, 'IP Address', '127.0.0.1'),
            _buildMetricItem(Icons.memory, 'RAM', '120 MB'),
            _buildMetricItem(Icons.storage, 'Storage', '1.2 GB'),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricItem(IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, size: 28, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildServiceCards() {
    return Column(
      children: [
        _buildServiceTile('Nginx', _isServiceRunning ? 'Running on port 8080' : 'Stopped', Icons.web, _isServiceRunning),
        _buildServiceTile('PHP-FPM', _isServiceRunning ? 'Running' : 'Stopped', Icons.code, _isServiceRunning),
        _buildServiceTile('MariaDB', _isServiceRunning ? 'Running on port 3306' : 'Stopped', Icons.data_usage, _isServiceRunning),
        _buildServiceTile('Node.js', 'Stopped', Icons.javascript, false),
      ],
    );
  }

  Widget _buildServiceTile(String name, String status, IconData icon, bool isRunning) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isRunning ? Colors.green.withOpacity(0.2) : Colors.grey.withOpacity(0.2),
          child: Icon(icon, color: isRunning ? Colors.green : Colors.grey),
        ),
        title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(status),
        trailing: Switch(
          value: isRunning,
          onChanged: (val) {},
        ),
      ),
    );
  }
}
