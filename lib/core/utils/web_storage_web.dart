// lib/core/utils/web_storage_web.dart

import 'package:web/web.dart' as web;

class WebStorageImpl {
  static void savePendingRole(String role) {
    try {
      web.window.localStorage.setItem('vailmeds_pending_role', role);
    } catch (_) {}
  }

  static String? getPendingRole() {
    try {
      return web.window.localStorage.getItem('vailmeds_pending_role');
    } catch (_) {
      return null;
    }
  }

  static void clearPendingRole() {
    try {
      web.window.localStorage.removeItem('vailmeds_pending_role');
    } catch (_) {}
  }
}
