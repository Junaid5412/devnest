import 'dart:io';
import 'package:path_provider/path_provider.dart';

class NginxConfigManager {
  static Future<void> addVirtualHost({
    required String projectName,
    required int port,
    required String documentRoot,
    bool isPhp = true,
  }) async {
    final appSupportDir = await getApplicationSupportDirectory();
    final configPath = '${appSupportDir.path}/config/nginx.conf';
    
    final file = File(configPath);
    if (!file.existsSync()) {
      file.createSync(recursive: true);
      file.writeAsStringSync('events { worker_connections 1024; }\nhttp {\n  include mime.types;\n  default_type application/octet-stream;\n}\n');
    }

    String content = await file.readAsString();

    final serverBlock = '''
  server {
      listen $port;
      server_name localhost;
      root $documentRoot;
      index index.php index.html index.htm;

      location / {
          try_files \$uri \$uri/ /index.php?\$query_string;
      }
      
      ${isPhp ? '''
      location ~ \\.php\$ {
          fastcgi_pass 127.0.0.1:9000;
          fastcgi_index index.php;
          fastcgi_param SCRIPT_FILENAME \$documentRoot\$fastcgi_script_name;
          include fastcgi_params;
      }
      ''' : ''}
  }
''';

    // Insert server block before the last closing brace of http {}
    final int lastBrace = content.lastIndexOf('}');
    if (lastBrace != -1) {
      content = content.substring(0, lastBrace) + serverBlock + content.substring(lastBrace);
      await file.writeAsString(content);
    }
  }
}
