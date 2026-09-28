import 'package:flutter/material.dart';

class SslManagerScreen extends StatelessWidget {
  const SslManagerScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('SSL / HTTPS Manager')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Card(
              color: Colors.amber,
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Text(
                  'Warning: Locally generated self-signed certificates are for development and may not be automatically trusted by browsers.',
                  style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.security),
              title: const Text('Generate Development Certificate'),
              subtitle: const Text('Create a self-signed cert for localhost'),
              trailing: ElevatedButton(
                onPressed: () {},
                child: const Text('GENERATE'),
              ),
            ),
            const Divider(),
            SwitchListTile(
              title: const Text('Enable HTTPS'),
              subtitle: const Text('Force project traffic over port 443 (Requires valid cert)'),
              value: false,
              onChanged: (val) {},
            ),
          ],
        ),
      ),
    );
  }
}
