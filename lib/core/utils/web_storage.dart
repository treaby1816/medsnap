// lib/core/utils/web_storage.dart

import 'web_storage_stub.dart'
    if (dart.library.html) 'web_storage_web.dart';

abstract class WebStorage {
  static void savePendingRole(String role) {
    WebStorageImpl.savePendingRole(role);
  }

  static String? getPendingRole() {
    return WebStorageImpl.getPendingRole();
  }

  static void clearPendingRole() {
    WebStorageImpl.clearPendingRole();
  }
}
