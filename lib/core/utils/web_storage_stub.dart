// lib/core/utils/web_storage_stub.dart

class WebStorageImpl {
  static void savePendingRole(String role) {
    // No-op on native platforms.
  }

  static String? getPendingRole() {
    return null;
  }

  static void clearPendingRole() {
    // No-op on native platforms.
  }
}
