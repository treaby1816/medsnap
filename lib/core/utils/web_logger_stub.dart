// lib/core/utils/web_logger_stub.dart

import 'dart:developer' as developer;

class WebLoggerImpl {
  static void log(String message) {
    developer.log(message, name: 'BOOT');
  }

  static void dispatchStartEvent() {
    // No-op on native platforms.
  }
}
