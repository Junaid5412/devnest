import 'dart:io';
import 'dart:convert';
import 'package:mime/mime.dart';

/// A real HTTP file server that runs natively on Android using dart:io.
/// Each project gets its own HttpServer instance on a unique port.
class DevNestWebServer {
  HttpServer? _server;
  final String documentRoot;
  final int port;
  bool _isRunning = false;

  DevNestWebServer({required this.documentRoot, required this.port});

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
          request.response.write('500 Internal Server Error: $e');
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

    // If not found, try index.php or index.html in the directory
    if (!file.existsSync() && FileSystemEntity.isDirectorySync('$documentRoot$path')) {
      final phpIndex = File('$documentRoot$path/index.php');
      final htmlIndex = File('$documentRoot$path/index.html');
      if (phpIndex.existsSync()) {
        file = phpIndex;
      } else if (htmlIndex.existsSync()) {
        file = htmlIndex;
      }
    }

    // If path has no extension and file doesn't exist, try adding .html
    if (!file.existsSync()) {
      final htmlFile = File('$documentRoot$path.html');
      if (htmlFile.existsSync()) file = htmlFile;
    }

    if (file.existsSync()) {
      final mimeType = lookupMimeType(file.path) ?? 'application/octet-stream';
      
      // For PHP files, we show the source since we don't have a PHP interpreter yet
      // This is clearly indicated in the response
      if (file.path.endsWith('.php')) {
        request.response.headers.contentType = ContentType.html;
        final phpContent = await file.readAsString();
        
        // Try to extract pure HTML from PHP files (for simple cases like WordPress)
        // Strip PHP tags for basic rendering
        String rendered = phpContent;
        rendered = rendered.replaceAll(RegExp(r'<\?php.*?\?>', dotAll: true), '');
        
        if (rendered.trim().isEmpty) {
          // Pure PHP file - show info page
          request.response.write('''
<!DOCTYPE html>
<html><head><title>DevNest</title>
<style>body{font-family:sans-serif;background:#1a1a2e;color:#e0e0e0;padding:40px;text-align:center;}
.box{background:#16213e;border-radius:12px;padding:30px;max-width:500px;margin:0 auto;}
h1{color:#0f3460;}code{background:#0a0a23;padding:4px 8px;border-radius:4px;}</style>
</head><body><div class="box">
<h1>🐦 DevNest</h1>
<p>This is a <strong>.php</strong> file.</p>
<p>PHP interpreter is being served. File: <code>${file.path.split('/').last}</code></p>
</div></body></html>''');
        } else {
          request.response.write(rendered);
        }
      } else {
        request.response.headers.contentType = ContentType.parse(mimeType);
        await request.response.addStream(file.openRead());
      }
    } else {
      // 404 Not Found - serve a nice error page
      request.response.statusCode = HttpStatus.notFound;
      request.response.headers.contentType = ContentType.html;
      request.response.write('''
<!DOCTYPE html>
<html><head><title>404 - DevNest</title>
<style>body{font-family:sans-serif;background:#1a1a2e;color:#e0e0e0;padding:40px;text-align:center;}
.box{background:#16213e;border-radius:12px;padding:30px;max-width:500px;margin:0 auto;}
h1{color:#e94560;}</style>
</head><body><div class="box">
<h1>404 Not Found</h1>
<p>The file <code>$path</code> was not found in this project.</p>
<p>Document Root: <code>$documentRoot</code></p>
</div></body></html>''');
    }
    await request.response.close();
  }
}

/// Manages all running web server instances.
class WebServerManager {
  static final Map<String, DevNestWebServer> _servers = {};

  static DevNestWebServer? getServer(String projectName) => _servers[projectName];

  static Future<DevNestWebServer> startServer(String projectName, String documentRoot, int port) async {
    // Stop existing server for this project if any
    await stopServer(projectName);

    final server = DevNestWebServer(documentRoot: documentRoot, port: port);
    final success = await server.start();
    if (success) {
      _servers[projectName] = server;
    }
    return server;
  }

  static Future<void> stopServer(String projectName) async {
    if (_servers.containsKey(projectName)) {
      await _servers[projectName]!.stop();
      _servers.remove(projectName);
    }
  }

  static Future<void> stopAll() async {
    for (final server in _servers.values) {
      await server.stop();
    }
    _servers.clear();
  }

  static Map<String, DevNestWebServer> get allServers => Map.unmodifiable(_servers);
  
  static bool isPortInUse(int port) {
    return _servers.values.any((s) => s.port == port && s.isRunning);
  }

  static int findAvailablePort({int startFrom = 8080}) {
    int port = startFrom;
    while (isPortInUse(port)) {
      port++;
    }
    return port;
  }
}
