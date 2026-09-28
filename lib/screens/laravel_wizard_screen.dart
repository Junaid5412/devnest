import 'package:flutter/material.dart';

class LaravelWizardScreen extends StatefulWidget {
  const LaravelWizardScreen({super.key});

  @override
  State<LaravelWizardScreen> createState() => _LaravelWizardScreenState();
}

class _LaravelWizardScreenState extends State<LaravelWizardScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create Laravel Project')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            const TextField(decoration: InputDecoration(labelText: 'Project Name', border: OutlineInputBorder())),
            const SizedBox(height: 16),
            const TextField(decoration: InputDecoration(labelText: 'PHP Version', hintText: 'Default (8.2)', border: OutlineInputBorder())),
            const SizedBox(height: 16),
            const TextField(decoration: InputDecoration(labelText: 'Database Name', border: OutlineInputBorder())),
            const SizedBox(height: 16),
            const TextField(decoration: InputDecoration(labelText: 'Port', hintText: '8000', border: OutlineInputBorder())),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Generating Laravel Project via Composer...')));
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(16)),
              child: const Text('CREATE LARAVEL PROJECT'),
            )
          ],
        ),
      ),
    );
  }
}
