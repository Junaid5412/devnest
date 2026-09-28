import 'package:flutter/material.dart';

class WordPressWizardScreen extends StatefulWidget {
  const WordPressWizardScreen({super.key});

  @override
  State<WordPressWizardScreen> createState() => _WordPressWizardScreenState();
}

class _WordPressWizardScreenState extends State<WordPressWizardScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Install WordPress')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            const TextField(decoration: InputDecoration(labelText: 'Site Name', border: OutlineInputBorder())),
            const SizedBox(height: 16),
            const TextField(decoration: InputDecoration(labelText: 'Admin Username', border: OutlineInputBorder())),
            const SizedBox(height: 16),
            const TextField(decoration: InputDecoration(labelText: 'Admin Password', obscureText: true, border: OutlineInputBorder())),
            const SizedBox(height: 16),
            const TextField(decoration: InputDecoration(labelText: 'Admin Email', border: OutlineInputBorder())),
            const SizedBox(height: 16),
            const TextField(decoration: InputDecoration(labelText: 'Database Name', border: OutlineInputBorder())),
            const SizedBox(height: 16),
            const TextField(decoration: InputDecoration(labelText: 'Port', hintText: '8080', border: OutlineInputBorder())),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Downloading & Installing WordPress...')));
                Navigator.pop(context);
              },
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(16)),
              child: const Text('INSTALL WORDPRESS'),
            )
          ],
        ),
      ),
    );
  }
}
