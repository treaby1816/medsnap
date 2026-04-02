import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

// ─────────────────────────────────────────────────────────────────────
// SECURITY LOGGING — Logs unauthorized access attempts to Firestore
// ─────────────────────────────────────────────────────────────────────

class SecurityLogger {
  static final _firestore = FirebaseFirestore.instance;

  /// Logs an unauthorized access attempt to /security_logs.
  static Future<void> logUnauthorizedAccess({
    required String attemptedAction,
    String? details,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      await _firestore.collection('security_logs').add({
        'uid': user?.uid ?? 'anonymous',
        'email': user?.email ?? 'unknown',
        'attemptedAction': attemptedAction,
        'details': details,
        'timestamp': FieldValue.serverTimestamp(),
        'platform': kIsWeb ? 'web' : 'mobile',
      });
      debugPrint('Security Event: $attemptedAction by ${user?.uid}');
    } catch (e) {
      debugPrint('Failed to log security event: $e');
    }
  }

  /// Checks if the current user is an admin from Firestore.
  /// Returns false if no user or not admin.
  static Future<bool> verifyAdminAccess() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    try {
      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (!doc.exists) return false;

      final role = doc.data()?['role'] ?? 'patient';
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
