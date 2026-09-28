import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

class GitManagerScreen extends StatefulWidget {
  const GitManagerScreen({super.key});

  @override
  State<GitManagerScreen> createState() => _GitManagerScreenState();
}

class _GitManagerScreenState extends State<GitManagerScreen> {
  Future<void> _runGitCommand(List<String> args, String workingDir, BuildContext context) async {
    final appSupportDir = await getApplicationSupportDirectory();
    final gitBin = '${appSupportDir.path}/bin/git';
    
    if (!File(gitBin).existsSync()) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Git binary not found. Please download it via Setup.')));
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const AlertDialog(content: Row(children: [CircularProgressIndicator(), SizedBox(width: 16), Text("Running Git command...")])),
    );

    try {
      final result = await Process.run(gitBin, args, workingDirectory: workingDir);
      Navigator.pop(context); // close loading
      
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(result.exitCode == 0 ? 'Success' : 'Error'),
          content: SingleChildScrollView(child: Text(result.stdout.toString() + '\n' + result.stderr.toString())),
          actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('OK'))],
        )
      );
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed: $e')));
    }
  }

  void _showCloneDialog() async {
    final docDir = await getApplicationDocumentsDirectory();
    final _urlCtrl = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Clone Repository'),
        content: TextField(controller: _urlCtrl, decoration: const InputDecoration(hintText: 'https://github.com/user/repo.git')),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('CANCEL')),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _runGitCommand(['clone', _urlCtrl.text], '${docDir.path}/projects', context);
            },
            child: const Text('CLONE')
          ),
        ]
      )
    );
  }

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
              onTap: _showCloneDialog,
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.create_new_folder),
              title: const Text('Initialize Repository'),
              subtitle: const Text('Run git init in a project'),
              onTap: () async {
                 final docDir = await getApplicationDocumentsDirectory();
                 _runGitCommand(['init'], '${docDir.path}/projects', context);
              },
            ),
          ),
        ],
      ),
    );
  }
}
