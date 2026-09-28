import 'package:flutter/material.dart';

class DatabaseManagerScreen extends StatefulWidget {
  const DatabaseManagerScreen({super.key});

  @override
  State<DatabaseManagerScreen> createState() => _DatabaseManagerScreenState();
}

class _DatabaseManagerScreenState extends State<DatabaseManagerScreen> {
  final List<String> _databases = ['information_schema', 'mysql', 'performance_schema', 'wordpress_db', 'laravel_db'];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('MariaDB Manager')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              leading: const Icon(Icons.install_desktop, color: Colors.blue),
              title: const Text('phpMyAdmin'),
              subtitle: const Text('Not installed'),
              trailing: ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Downloading phpMyAdmin...')));
                },
                child: const Text('INSTALL'),
              ),
            ),
          ),
          const SizedBox(height: 16),
          const Text('Databases', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ..._databases.map((db) => ListTile(
            leading: const Icon(Icons.data_usage),
            title: Text(db),
            trailing: IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              onPressed: () {},
            ),
          )),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          _showCreateDbDialog(context);
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  void _showCreateDbDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Database'),
        content: const TextField(decoration: InputDecoration(hintText: 'Database Name')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
          ElevatedButton(onPressed: () => Navigator.pop(context), child: const Text('CREATE')),
        ],
      ),
    );
  }
}
