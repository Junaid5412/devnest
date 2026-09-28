import 'package:flutter/material.dart';

class GitManagerScreen extends StatelessWidget {
  const GitManagerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Git Integration')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              leading: const Icon(Icons.cloud_download),
              title: const Text('Clone Repository'),
              subtitle: const Text('Clone an existing repo via HTTPS or SSH'),
              onTap: () {},
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.create_new_folder),
              title: const Text('Initialize Repository'),
              subtitle: const Text('Run git init in a project'),
              onTap: () {},
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.sync),
              title: const Text('Pull & Push'),
              subtitle: const Text('Sync with remote branch'),
              onTap: () {},
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.account_tree),
              title: const Text('Branches'),
              subtitle: const Text('Checkout or merge branches'),
              onTap: () {},
            ),
          ),
        ],
      ),
    );
  }
}
