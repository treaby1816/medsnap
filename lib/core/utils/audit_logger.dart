import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart';

class AuditLogger {
  static final _supabase = Supabase.instance.client;

  static Future<void> logEvent(String event, {Map<String, dynamic>? metadata}) async {
    try {
      await _supabase.from('audit_logs').insert({
        'type': event,
        'metadata': metadata,
      });
    } catch (e) {
      debugPrint('Error logging event: $e');
    }
  }

  static Future<void> logPharmacyApproval({
    required String licenseNumber,
    required String adminName,
    required String adminUid,
    required String pharmacyUid,
  }) async {
    try {
      await _supabase.from('audit_logs').insert({
        'type': 'PHARMACY_APPROVAL',
        'status': 'SUCCESS',
        'action': 'VERIFIED',
        'details': 'License $licenseNumber verified by $adminName',
        'adminId': adminUid,
        'pharmacyId': pharmacyUid,
      });
    } catch (e) {
      debugPrint('Error writing to manual audit log: $e');
    }
  }
}
