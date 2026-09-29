import 'dart:io';
import 'dart:convert';
import 'package:mime/mime.dart';

/// A real HTTP file server that runs natively on Android using dart:io.
/// Each project gets its own HttpServer instance on a unique port.
class DevNestWebServer {
  HttpServer? _server;
  final String documentRoot;
  final int port;
  final String projectName;
  bool _isRunning = false;

  DevNestWebServer({required this.documentRoot, required this.port, required this.projectName});

  bool get isRunning => _isRunning;
  String get url => 'http://127.0.0.1:$port';

  Future<bool> start() async {
    if (_isRunning) return true;
    try {
      _server = await HttpServer.bind('127.0.0.1', port, shared: true);
      _isRunning = true;

      _server!.listen((HttpRequest request) async {
        try {
          await _handleRequest(request);
        } catch (e) {
          request.response.statusCode = HttpStatus.internalServerError;
          request.response.headers.contentType = ContentType.html;
          request.response.write('''
<!DOCTYPE html><html><head><title>500 Error</title>
<style>body{font-family:sans-serif;background:#1a1a2e;color:#e0e0e0;padding:40px;text-align:center;}
h1{color:#e94560;}</style></head><body>
<h1>500 Internal Server Error</h1><p>$e</p></body></html>''');
          await request.response.close();
        }
      });
      return true;
    } catch (e) {
      _isRunning = false;
      return false;
    }
  }

  Future<void> stop() async {
    if (_server != null) {
      await _server!.close(force: true);
      _server = null;
      _isRunning = false;
    }
  }

  Future<void> _handleRequest(HttpRequest request) async {
    String path = Uri.decodeFull(request.uri.path);
    if (path == '/') path = '/index.html';

    // Try the exact path first
    File file = File('$documentRoot$path');

    // If not found, try common index files
    if (!file.existsSync()) {
      final dir = Directory('$documentRoot$path');
      if (dir.existsSync()) {
        for (final indexName in ['index.html', 'index.htm', 'index.php', 'default.html']) {
          final indexFile = File('$documentRoot$path/$indexName');
          if (indexFile.existsSync()) {
            file = indexFile;
            break;
          }
        }
      }
    }

    // Try without extension
    if (!file.existsSync()) {
      final htmlFile = File('$documentRoot$path.html');
      if (htmlFile.existsSync()) file = htmlFile;
    }

    // Also try index.php at root if nothing else matched
    if (!file.existsSync() && path == '/index.html') {
      final phpIndex = File('$documentRoot/index.php');
      if (phpIndex.existsSync()) file = phpIndex;
    }

    if (file.existsSync()) {
      final mimeType = lookupMimeType(file.path) ?? 'application/octet-stream';

      if (file.path.endsWith('.php')) {
        // Serve PHP files: strip PHP tags and render HTML parts
        request.response.headers.contentType = ContentType.html;
        final phpContent = await file.readAsString();
        String rendered = phpContent;
        rendered = rendered.replaceAll(RegExp(r'<\?php.*?\?>', dotAll: true), '');

        if (rendered.trim().isEmpty) {
          request.response.write(_phpInfoPage(file.path));
        } else {
          request.response.write(rendered);
        }
      } else {
        request.response.headers.contentType = ContentType.parse(mimeType);
        await request.response.addStream(file.openRead());
      }
    } else {
      // Directory listing if the path is a directory
      final dir = Directory('$documentRoot$path');
      if (dir.existsSync()) {
        request.response.headers.contentType = ContentType.html;
        request.response.write(await _directoryListing(path, dir));
      } else {
        // 404
        request.response.statusCode = HttpStatus.notFound;
        request.response.headers.contentType = ContentType.html;
        request.response.write('''
<!DOCTYPE html><html><head><title>404 - DevNest</title>
<style>body{font-family:sans-serif;background:#1a1a2e;color:#e0e0e0;padding:40px;text-align:center;}
h1{color:#e94560;}code{background:#222;padding:2px 8px;border-radius:4px;color:#4fc3f7;}</style>
</head><body>
<h1>404 Not Found</h1>
<p>The file <code>$path</code> was not found.</p>
<p>Document Root: <code>$documentRoot</code></p>
<p><a href="/" style="color:#4fc3f7;">← Go Home</a></p>
</body></html>''');
      }
    }
    await request.response.close();
  }

  String _phpInfoPage(String filePath) {
    final fileName = filePath.split('/').last;
    return '''
<!DOCTYPE html><html><head><title>$fileName - DevNest</title>
<style>body{font-family:sans-serif;background:#1a1a2e;color:#e0e0e0;padding:40px;text-align:center;}
.box{background:#16213e;border-radius:12px;padding:30px;max-width:500px;margin:0 auto;}
h1{color:#4fc3f7;}code{background:#0a0a23;padding:4px 8px;border-radius:4px;}</style>
</head><body><div class="box">
<h1>🐦 DevNest PHP Server</h1>
<p>File: <code>$fileName</code></p>
<p>PHP files are being served. For full PHP execution, install the PHP runtime from Settings.</p>
<p>Port: <strong>$port</strong></p>
</div></body></html>''';
  }

  Future<String> _directoryListing(String urlPath, Directory dir) async {
    final entries = dir.listSync();
    final buffer = StringBuffer();
    buffer.write('''
<!DOCTYPE html><html><head><title>Index of $urlPath</title>
<style>body{font-family:sans-serif;background:#1a1a2e;color:#e0e0e0;padding:20px;}
a{color:#4fc3f7;text-decoration:none;}a:hover{text-decoration:underline;}
table{border-collapse:collapse;width:100%;}td,th{padding:8px 12px;text-align:left;border-bottom:1px solid #333;}</style>
</head><body>
<h2>Index of $urlPath</h2><table><tr><th>Name</th><th>Size</th></tr>''');
    if (urlPath != '/') {
      buffer.write('<tr><td><a href="..">..</a></td><td>-</td></tr>');
    }
    for (final entry in entries) {
      final name = entry.path.split(Platform.pathSeparator).last;
      final isDir = entry is Directory;
      final size = isDir ? '-' : '${(entry as File).lengthSync()} bytes';
      final href = '$urlPath${urlPath.endsWith('/') ? '' : '/'}$name${isDir ? '/' : ''}';
      buffer.write('<tr><td><a href="$href">${isDir ? '📁 ' : '📄 '}$name</a></td><td>$size</td></tr>');
    }
    buffer.write('</table></body></html>');
    return buffer.toString();
  }
}

/// Manages all running web server instances. Each project = one unique port.
class WebServerManager {
  static final Map<String, DevNestWebServer> _servers = {};
  static final Set<int> _usedPorts = {};

  static DevNestWebServer? getServer(String projectName) => _servers[projectName];

  static Future<DevNestWebServer> startServer(String projectName, String documentRoot, int port) async {
    // Stop existing server for this project if any
    await stopServer(projectName);

    final server = DevNestWebServer(documentRoot: documentRoot, port: port, projectName: projectName);
    final success = await server.start();
    if (success) {
      _servers[projectName] = server;
      _usedPorts.add(port);
    }
    return server;
  }

  static Future<void> stopServer(String projectName) async {
    if (_servers.containsKey(projectName)) {
      final server = _servers[projectName]!;
      _usedPorts.remove(server.port);
      await server.stop();
      _servers.remove(projectName);
    }
  }

  static Future<void> stopAll() async {
    for (final server in _servers.values) {
      await server.stop();
    }
    _servers.clear();
    _usedPorts.clear();
  }

  static Map<String, DevNestWebServer> get allServers => Map.unmodifiable(_servers);

  static bool isPortInUse(int port) {
    return _usedPorts.contains(port);
  }

  /// Find the next available port starting from [startFrom].
  /// Each call returns a different port so multiple projects never collide.
  static int findAvailablePort({int startFrom = 8080}) {
    int port = startFrom;
    while (_usedPorts.contains(port)) {
      port++;
    }
    return port;
  }

  /// Get a summary of all running servers for the dashboard.
  static List<Map<String, dynamic>> getRunningServers() {
    return _servers.entries
        .where((e) => e.value.isRunning)
        .map((e) => {
              'name': e.key,
              'port': e.value.port,
              'url': e.value.url,
              'documentRoot': e.value.documentRoot,
            })
        .toList();
  }
}
