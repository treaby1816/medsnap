// lib/core/utils/web_logger.dart

import 'web_logger_stub.dart'
    if (dart.library.html) 'web_logger_web.dart';

abstract class WebLogger {
  static void log(String message) {
    WebLoggerImpl.log(message);
  }

  static void dispatchStartEvent() {
    WebLoggerImpl.dispatchStartEvent();
  }
}
