import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

// ─────────────────────────────────────────────────────────────────────
// SECURITY LOGGING — Logs unauthorized access attempts to Supabase
// ─────────────────────────────────────────────────────────────────────

class SecurityLogger {
  static final _supabase = Supabase.instance.client;

  /// Logs an unauthorized access attempt to /security_logs.
  static Future<void> logUnauthorizedAccess({
    required String attemptedAction,
    String? details,
  }) async {
    try {
      final user = _supabase.auth.currentUser;
      await _supabase.from('security_logs').insert({
        'uid': user?.id ?? 'anonymous',
        'email': user?.email ?? 'unknown',
        'attempted_action': attemptedAction,
        'details': details,
        'platform': kIsWeb ? 'web' : 'mobile',
      });
      debugPrint('Security Event: $attemptedAction by ${user?.id}');
    } catch (e) {
      debugPrint('Failed to log security event: $e');
    }
  }

  /// Checks if the current user is an admin from Supabase.
  /// Returns false if no user or not admin.
  static Future<bool> verifyAdminAccess() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return false;

    try {
      final doc = await _supabase.from('users').select('role').eq('id', user.id).maybeSingle();
      if (doc == null) return false;

      final role = doc['role'] ?? 'patient';
      return role == 'admin' || role == 'super_admin';
    } catch (e) {
      debugPrint('Admin verification failed: $e');
      return false;
    }
  }

  /// Guard: Verifies admin access and logs unauthorized attempts.
  /// Returns true if access is granted, false if denied.
  static Future<bool> guardAdminAction(String actionName) async {
    final isAdmin = await verifyAdminAccess();
    if (!isAdmin) {
      await logUnauthorizedAccess(
        attemptedAction: actionName,
        details: 'Non-admin user attempted to access restricted functionality.',
      );
      return false;
    }
    return true;
  }
}
