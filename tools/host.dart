import 'dart:io';
import 'package:path/path.dart' as p; // Add 'path: ^1.9.0' to pubspec.yaml
import 'dart:developer' as developer;

void main() async {
  const port = 61725;
  const root = 'build/web';
  
  if (!Directory(root).existsSync()) {
    developer.log('❌ Error: $root directory not found. Please run "flutter build web" first.', name: 'HostServer');
    exit(1);
  }

  // Bind to anyIPv4 so it can be accessed across a local network or Docker container
  final server = await HttpServer.bind(InternetAddress.anyIPv4, port);
  developer.log('🚀 Dubai LifeOS Live on: http://localhost:$port', name: 'HostServer');
  
  await for (HttpRequest request in server) {
    try {
      // 1. Security: Normalize path to prevent Directory Traversal Attacks (e.g., ../../etc/passwd)
      final normalizedPath = p.normalize(request.uri.path);
      final path = (normalizedPath == '/' || normalizedPath == '.') ? '/index.html' : normalizedPath;
      
      // Construct the absolute file path safely
      final filePath = p.join(root, path.startsWith('/') ? path.substring(1) : path);
      final file = File(filePath);
      
      if (await file.exists()) {
        final contentType = _getContentType(filePath);
        request.response.headers.contentType = contentType;
        
        // 2. Performance: Add basic caching for static assets (CanvasKit, JS, images)
        if (contentType.mimeType != 'text/html') {
          request.response.headers.add('Cache-Control', 'max-age=3600');
        }
        
        await file.openRead().pipe(request.response);
      } else {
        // SPA Fallback: Route everything else to index.html for Flutter Router
        final index = File(p.join(root, 'index.html'));
        if (await index.exists()) {
          request.response.headers.contentType = ContentType.html;
          // Ensure we don't cache the index.html so updates load immediately
          request.response.headers.add('Cache-Control', 'no-cache'); 
          await index.openRead().pipe(request.response);
        } else {
          request.response.statusCode = HttpStatus.notFound;
          request.response.write('404 - index.html missing');
          await request.response.close();
        }
      }
    } catch (e) {
      // 3. Stability: Catch dropped connections so the server doesn't crash
      developer.log('⚠️ Request error: $e', name: 'HostServer');
      try {
        request.response.statusCode = HttpStatus.internalServerError;
        await request.response.close();
      } catch (_) {
        // Ignore errors if the socket is already closed
      }
    }
  }
}

ContentType _getContentType(String path) {
  final ext = p.extension(path).toLowerCase();
  switch (ext) {
    case '.html': return ContentType.html;
    case '.js': return ContentType.parse('application/javascript');
    case '.css': return ContentType.parse('text/css');
    case '.png': return ContentType.parse('image/png');
    case '.jpg': 
    case '.jpeg': return ContentType.parse('image/jpeg');
    case '.svg': return ContentType.parse('image/svg+xml');
    case '.json': return ContentType.json;
    // 4. Compatibility: Critical for modern Flutter Web (CanvasKit/WASM rendering)
    case '.wasm': return ContentType.parse('application/wasm'); 
    default: return ContentType.binary;
  }
}