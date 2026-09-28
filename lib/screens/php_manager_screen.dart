import 'package:flutter/material.dart';

class PhpManagerScreen extends StatefulWidget {
  const PhpManagerScreen({super.key});

  @override
  State<PhpManagerScreen> createState() => _PhpManagerScreenState();
}

class _PhpManagerScreenState extends State<PhpManagerScreen> {
  final Map<String, bool> _extensions = {
    'mysqli': true,
    'pdo_mysql': true,
    'curl': true,
    'openssl': true,
    'mbstring': true,
    'gd': false,
    'zip': true,
    'dom': true,
    'bcmath': false,
    'sodium': true,
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('PHP Manager')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const ListTile(
            title: Text('PHP Version'),
            subtitle: Text('8.2.0 (ARM64)'),
            trailing: Icon(Icons.arrow_forward_ios),
          ),
          const Divider(),
          const ListTile(
            title: Text('Edit php.ini'),
            subtitle: Text('Advanced configuration'),
            trailing: Icon(Icons.edit),
          ),
          const Divider(),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 8.0),
            child: Text('PHP Extensions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ),
          ..._extensions.entries.map((e) => SwitchListTile(
            title: Text(e.key),
            value: e.value,
            onChanged: (val) {
              setState(() {
                _extensions[e.key] = val;
              });
            },
          )),
        ],
      ),
    );
  }
}
