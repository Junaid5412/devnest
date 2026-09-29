import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

/// Manages project metadata on disk as JSON.
/// Each project gets a guaranteed unique port.
class ProjectManager {
  static Future<String> get _projectsDir async {
    final docDir = await getApplicationDocumentsDirectory();
    final dir = Directory('${docDir.path}/projects');
    if (!dir.existsSync()) dir.createSync(recursive: true);
    return dir.path;
  }

  static Future<String> get _configFile async {
    final docDir = await getApplicationDocumentsDirectory();
    return '${docDir.path}/devnest_projects.json';
  }

  static Future<List<Map<String, dynamic>>> loadProjects() async {
    final file = File(await _configFile);
    if (!file.existsSync()) return [];
    try {
      final content = await file.readAsString();
      final List<dynamic> data = jsonDecode(content);
      return data.cast<Map<String, dynamic>>();
    } catch (e) {
      return [];
    }
  }

  static Future<void> saveProjects(List<Map<String, dynamic>> projects) async {
    final file = File(await _configFile);
    await file.writeAsString(jsonEncode(projects));
  }

  /// Returns a unique port that no existing project uses.
  static Future<int> getUniquePort({int startFrom = 8080}) async {
    final projects = await loadProjects();
    final usedPorts = projects.map((p) => p['port'] as int).toSet();
    int port = startFrom;
    while (usedPorts.contains(port)) {
      port++;
    }
    return port;
  }

  static Future<Map<String, dynamic>> createProject({
    required String name,
    required String type,
    required int port,
    String? phpVersion,
  }) async {
    final basePath = await _projectsDir;
    final safeName = name.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_').toLowerCase();
    final projectPath = '$basePath/$safeName';

    final dir = Directory(projectPath);
    if (!dir.existsSync()) dir.createSync(recursive: true);

    // Create default index.html
    final indexFile = File('$projectPath/index.html');
    if (!indexFile.existsSync()) {
      indexFile.writeAsStringSync(_defaultIndexHtml(name, type, port, projectPath));
    }

    final project = {
      'name': name,
      'safeName': safeName,
      'type': type,
      'port': port,
      'path': projectPath,
      'phpVersion': phpVersion ?? '8.2',
      'status': 'stopped',
      'createdAt': DateTime.now().toIso8601String(),
    };

    final projects = await loadProjects();
    // Remove existing project with same safeName if any
    projects.removeWhere((p) => p['safeName'] == safeName);
    projects.add(project);
    await saveProjects(projects);

    return project;
  }

  static Future<void> deleteProject(String safeName) async {
    final projects = await loadProjects();
    projects.removeWhere((p) => p['safeName'] == safeName);
    await saveProjects(projects);

    final basePath = await _projectsDir;
    final dir = Directory('$basePath/$safeName');
    if (dir.existsSync()) dir.deleteSync(recursive: true);
  }

  static Future<void> updateProjectStatus(String safeName, String status) async {
    final projects = await loadProjects();
    for (var p in projects) {
      if (p['safeName'] == safeName) {
        p['status'] = status;
      }
    }
    await saveProjects(projects);
  }

  static String _defaultIndexHtml(String name, String type, int port, String projectPath) {
    return '''
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>$name - DevNest</title>
  <style>
    * { margin: 0; padding: 0; box-sizing: border-box; }
    body { font-family: 'Segoe UI', sans-serif; background: linear-gradient(135deg, #0f0f23 0%, #1a1a3e 100%);
           color: #e0e0e0; display: flex; justify-content: center; align-items: center; min-height: 100vh; }
    .container { text-align: center; background: rgba(26,26,62,0.9); padding: 60px 40px; border-radius: 20px;
                 box-shadow: 0 20px 60px rgba(0,0,0,0.5); max-width: 600px; backdrop-filter: blur(10px); }
    h1 { font-size: 2.5em; background: linear-gradient(90deg, #4fc3f7, #00e676); -webkit-background-clip: text;
         -webkit-text-fill-color: transparent; margin-bottom: 10px; }
    .badge { display: inline-block; background: #4fc3f7; color: #000; padding: 4px 16px;
             border-radius: 20px; font-size: 0.9em; font-weight: bold; margin-bottom: 20px; }
    p { color: #aaa; line-height: 1.8; }
    .info { background: #0a0a1a; border-radius: 10px; padding: 20px; margin-top: 20px; text-align: left; }
    .info p { margin: 5px 0; font-size: 0.95em; }
    code { background: #222; padding: 2px 8px; border-radius: 4px; color: #4fc3f7; font-size: 0.9em; }
    .success { color: #00e676; font-weight: bold; margin-top: 20px; font-size: 1.1em; }
  </style>
</head>
<body>
  <div class="container">
    <h1>🚀 $name</h1>
    <span class="badge">$type</span>
    <p class="success">✅ Your website is live on DevNest!</p>
    <div class="info">
      <p>🌐 URL: <code>http://127.0.0.1:$port</code></p>
      <p>📁 Root: <code>$projectPath</code></p>
      <p>🛠 Type: <code>$type</code></p>
      <p>📝 Edit <code>index.html</code> in the DevNest File Manager to customize this page.</p>
    </div>
  </div>
</body>
</html>
''';
  }
}
