import 'dart:io';

void main() async {
  final port = 61725;
  final root = 'build/web';
  
  if (!Directory(root).existsSync()) {
    stdout.writeln('Error: $root directory not found. Build may have failed.');
    exit(1);
  }

  final server = await HttpServer.bind('127.0.0.1', port);
  stdout.writeln('>>> Dubai LifeOS Live on: http://127.0.0.1:$port');
  
  await for (HttpRequest request in server) {
    final path = request.uri.path == '/' ? '/index.html' : request.uri.path;
    final file = File('$root$path');
    
    if (await file.exists()) {
      final contentType = _getContentType(path);
      request.response.headers.contentType = contentType;
      await file.openRead().pipe(request.response);
    } else {
      // Fallback for SPA routing
      final index = File('$root/index.html');
      request.response.headers.contentType = ContentType.html;
      await index.openRead().pipe(request.response);
    }
  }
}

ContentType _getContentType(String path) {
  if (path.endsWith('.html')) return ContentType.html;
  if (path.endsWith('.js')) return ContentType.parse('application/javascript');
  if (path.endsWith('.css')) return ContentType.parse('text/css');
  if (path.endsWith('.png')) return ContentType.parse('image/png');
  if (path.endsWith('.jpg')) return ContentType.parse('image/jpeg');
  if (path.endsWith('.svg')) return ContentType.parse('image/svg+xml');
  return ContentType.binary;
}
