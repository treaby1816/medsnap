// lib/core/utils/web_logger_web.dart

import 'dart:js_interop';
import 'package:web/web.dart' as web;

class WebLoggerImpl {
  static void log(String message) {
    // In dart:js_interop, strings must be explicitly converted to JSString
    try {
      web.console.log('WEB BOOT: $message'.toJS);
    } catch (e) {
      // Fallback if js_interop is not fully available during early bootstrap
    }
  }

  static void dispatchStartEvent() {
    web.window.dispatchEvent(web.CustomEvent('flutter-engine-started'));
  }
}
