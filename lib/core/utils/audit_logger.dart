import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

class AuditLogger {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  static Future<void> logPharmacyApproval({
    required String licenseNumber,
    required String adminName,
    required String adminUid,
    required String pharmacyUid,
  }) async {
    try {
      await _firestore.collection('audit_logs').add({
        'type': 'PHARMACY_APPROVAL',
        'status': 'SUCCESS',
        'action': 'VERIFIED',
        'details': 'License $licenseNumber verified by $adminName',
        'adminId': adminUid,
        'pharmacyId': pharmacyUid,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error writing to manual audit log: $e');
    }
  }
}
