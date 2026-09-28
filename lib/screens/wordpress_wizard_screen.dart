import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:archive/archive.dart';
import 'package:path_provider/path_provider.dart';
import '../services/nginx_config_manager.dart';

class WordPressWizardScreen extends StatefulWidget {
  const WordPressWizardScreen({super.key});

  @override
  State<WordPressWizardScreen> createState() => _WordPressWizardScreenState();
}

class _WordPressWizardScreenState extends State<WordPressWizardScreen> {
  final _siteNameController = TextEditingController();
  final _dbNameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  
  bool _isInstalling = false;
  String _status = '';

  Future<void> _installWordPress() async {
    setState(() {
      _isInstalling = true;
      _status = 'Downloading WordPress...';
    });

    try {
      final docDir = await getApplicationDocumentsDirectory();
      final projectDir = Directory('${docDir.path}/projects/${_siteNameController.text.replaceAll(' ', '_').toLowerCase()}');
      
      if (projectDir.existsSync()) {
        throw Exception('Project directory already exists!');
      }

      // Download WordPress
      final response = await http.get(Uri.parse('https://wordpress.org/latest.zip'));
      if (response.statusCode != 200) throw Exception('Failed to download WordPress');

      setState(() => _status = 'Extracting files...');
      
      // Extract Archive
      final archive = ZipDecoder().decodeBytes(response.bodyBytes);
      for (final file in archive) {
        final filename = file.name;
        if (file.isFile) {
          final data = file.content as List<int>;
          // WordPress zip contains a 'wordpress/' folder at root, we strip it out
          final relativePath = filename.replaceFirst(RegExp(r'^wordpress/'), '');
          if (relativePath.isEmpty) continue;
          
          final outFile = File('${projectDir.path}/$relativePath');
          outFile.createSync(recursive: true);
          outFile.writeAsBytesSync(data);
        } else {
           final relativePath = filename.replaceFirst(RegExp(r'^wordpress/'), '');
           if (relativePath.isNotEmpty) {
             Directory('${projectDir.path}/$relativePath').createSync(recursive: true);
           }
        }
      }

      setState(() => _status = 'Configuring Database & wp-config.php...');

      // 1. Create Database via local mysql binary
      final appSupportDir = await getApplicationSupportDirectory();
      final mysqlBin = '${appSupportDir.path}/bin/mysql';
      
      if (File(mysqlBin).existsSync()) {
        await Process.run(mysqlBin, ['-u', 'root', '-e', 'CREATE DATABASE IF NOT EXISTS `${_dbNameController.text}`;']);
      }

      // 2. Create wp-config.php
      final sampleConfig = File('${projectDir.path}/wp-config-sample.php');
      if (sampleConfig.existsSync()) {
        String configContent = sampleConfig.readAsStringSync();
        configContent = configContent.replaceAll('database_name_here', _dbNameController.text);
        configContent = configContent.replaceAll('username_here', 'root');
        configContent = configContent.replaceAll('password_here', '');
        configContent = configContent.replaceAll('localhost', '127.0.0.1');
        
        File('${projectDir.path}/wp-config.php').writeAsStringSync(configContent);
      }

      // 3. Configure Nginx Virtual Host
      await NginxConfigManager.addVirtualHost(
        projectName: _siteNameController.text,
        port: int.tryParse('8080') ?? 8080,
        documentRoot: projectDir.path,
        isPhp: true,
      );

      setState(() {
        _isInstalling = false;
        _status = 'Installation Complete! You can now start the server.';
      });

    } catch (e) {
      setState(() {
        _isInstalling = false;
        _status = 'Error: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Install WordPress')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            TextField(controller: _siteNameController, decoration: const InputDecoration(labelText: 'Site Folder Name', border: OutlineInputBorder())),
            const SizedBox(height: 16),
            TextField(controller: _usernameController, decoration: const InputDecoration(labelText: 'Admin Username', border: OutlineInputBorder())),
            const SizedBox(height: 16),
            TextField(controller: _passwordController, obscureText: true, decoration: const InputDecoration(labelText: 'Admin Password', border: OutlineInputBorder())),
            const SizedBox(height: 16),
            TextField(controller: _dbNameController, decoration: const InputDecoration(labelText: 'Database Name', border: OutlineInputBorder())),
            const SizedBox(height: 32),
            if (_isInstalling) ...[
              const Center(child: CircularProgressIndicator()),
              const SizedBox(height: 16),
              Center(child: Text(_status, style: const TextStyle(fontWeight: FontWeight.bold))),
            ] else ...[
              ElevatedButton(
                onPressed: _installWordPress,
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.all(16)),
                child: const Text('INSTALL WORDPRESS'),
              ),
              if (_status.isNotEmpty) ...[
                const SizedBox(height: 16),
                Center(child: Text(_status, style: const TextStyle(color: Colors.green))),
              ]
            ]
          ],
        ),
      ),
    );
  }
}
