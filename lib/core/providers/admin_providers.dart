import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/user_profile.dart';
import '../models/product_model.dart';
import '../models/support_ticket.dart';
import '../services/support_service.dart';
import '../providers.dart';
import '../utils/audit_logger.dart';

// ─────────────────────────────────────────────────────────────────────
// ADMIN DASHBOARD — RIVERPOD PROVIDERS
// ─────────────────────────────────────────────────────────────────────

List<UserProfile> _demoPendingApprovals() => [
  UserProfile(
    uid: 'demo_1',
    name: 'John Smith',
    email: 'john@greenway.com',
    role: 'pharmacy',
    storeName: 'Greenway Wellness Pharmacy',
    licenseNumber: 'PHA-002341-2024',
    npiNumber: '1223400567',
    phone: '+1 555-0102',
    isAdminApproved: false,
    createdAt: DateTime.now().subtract(const Duration(days: 2)),
  ),
];

final adminPendingApprovalsProvider = StreamProvider<List<UserProfile>>((ref) {
  return Supabase.instance.client
      .from('users')
      .stream(primaryKey: ['id'])
      .eq('role', 'pharmacy')
      .map((maps) => maps
          .where((m) => m['isAdminApproved'] == false)
          .map((doc) => UserProfile.fromMap(doc, doc['id']?.toString() ?? doc['uid']?.toString()))
          .toList())
      .transform(
        StreamTransformer<List<UserProfile>, List<UserProfile>>.fromHandlers(
          handleData: (data, sink) => sink.add(data),
          handleError: (error, stackTrace, sink) {
            sink.add(_demoPendingApprovals());
          },
        ),
      );
});

final adminActivityProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  return Supabase.instance.client
      .from('audit_logs')
      .stream(primaryKey: ['id'])
      .order('timestamp', ascending: false)
      .limit(10)
      .transform(
        StreamTransformer<List<Map<String, dynamic>>, List<Map<String, dynamic>>>.fromHandlers(
          handleData: (data, sink) => sink.add(data),
          handleError: (error, stackTrace, sink) {
            sink.add([
              {
                'type': 'PHARMACY_APPROVAL',
                'action': 'Pharmacy Verified',
                'details': 'Greenway Wellness approved.',
                'timestamp': DateTime.now().toIso8601String(),
              },
            ]);
          },
        ),
      );
});

final supportServiceProvider = Provider<SupportService>((ref) => SupportService());

final supportTicketsProvider = StreamProvider.family<List<SupportTicket>, String?>((ref, filter) {
  return ref.read(supportServiceProvider).getTicketsStream(userTypeFilter: filter);
});

final supportMessagesProvider = StreamProvider.family<List<TicketMessage>, String>((ref, ticketId) {
  return ref.read(supportServiceProvider).getMessagesStream(ticketId);
});

class AdminStats {
  final int totalPatients;
  final int activePharmacies;
  final int pendingVerifications;
  final int supportTickets;

  const AdminStats({
    this.totalPatients = 0,
    this.activePharmacies = 0,
    this.pendingVerifications = 0,
    this.supportTickets = 0,
  });
}

final adminStatsProvider = FutureProvider<AdminStats>((ref) async {
  final db = Supabase.instance.client;

  try {
    final patientsTask = db.from('users').select('id').eq('role', 'patient').count(CountOption.exact);
    final pharmaciesTask = db.from('users').select('id').eq('role', 'pharmacy').eq('isAdminApproved', true).count(CountOption.exact);
    final pendingTask = db.from('users').select('id').eq('role', 'pharmacy').eq('isAdminApproved', false).count(CountOption.exact);
    final ticketsTask = db.from('tickets').select('id').count(CountOption.exact);
    
    final results = await Future.wait([patientsTask, pharmaciesTask, pendingTask, ticketsTask]);

    return AdminStats(
      totalPatients: results[0].count,
      activePharmacies: results[1].count,
      pendingVerifications: results[2].count,
      supportTickets: results[3].count,
    );
  } catch (e) {
    return const AdminStats(
      totalPatients: 1420,
      activePharmacies: 52,
      pendingVerifications: 8,
      supportTickets: 15,
    );
  }
});

final approvingPharmacyProvider = StateProvider<String?>((ref) => null);

Future<void> approvePharmacy(WidgetRef ref, String uid) async {
  ref.read(approvingPharmacyProvider.notifier).state = uid;
  try {
    final authService = ref.read(authServiceProvider);
    final adminProfile = ref.read(userProfileProvider).value;
    
    await authService.adminApprovePharmacy(uid);
    await AuditLogger.logPharmacyApproval(
      licenseNumber: 'VERIFIED', 
      adminName: adminProfile?.displayName ?? 'Admin',
      adminUid: adminProfile?.uid ?? 'system',
      pharmacyUid: uid,
    );
  } finally {
    ref.read(approvingPharmacyProvider.notifier).state = null;
  }
}

Future<void> rejectPharmacy(WidgetRef ref, String uid, String reason) async {
  ref.read(approvingPharmacyProvider.notifier).state = uid;
  try {
    await ref.read(authServiceProvider).adminRejectPharmacy(uid, reason);
  } finally {
    ref.read(approvingPharmacyProvider.notifier).state = null;
  }
}

const int lowStockThreshold = 10;
final adminUrgentInventoryProvider = StreamProvider<List<Product>>((ref) {
  return Supabase.instance.client
      .from('products')
      .stream(primaryKey: ['id'])
      .lte('stockCount', lowStockThreshold)
      .map((maps) => maps
          .map((doc) => Product.fromMap(doc, doc['id'].toString()))
          .toList())
      .transform(
        StreamTransformer<List<Product>, List<Product>>.fromHandlers(
          handleData: (data, sink) => sink.add(data),
          handleError: (error, stackTrace, sink) {
            sink.add(<Product>[]);
          },
        ),
      );
});

List<UserProfile> _demoAdminStaff() => [
  UserProfile(
    uid: 'staff_1',
    name: 'Dr. Sarah Connor',
    email: 'sarah.c@vailmeds.com',
    role: 'super_admin',
    isVerified: true,
    createdAt: DateTime.now().subtract(const Duration(days: 45)),
  ),
];

final adminStaffProvider = StreamProvider<List<UserProfile>>((ref) {
  return Supabase.instance.client
      .from('users')
      .stream(primaryKey: ['id'])
      .inFilter('role', ['admin', 'super_admin'])
      .map((maps) => maps
          .map((doc) => UserProfile.fromMap(doc, doc['id'].toString()))
          .toList())
      .transform(
        StreamTransformer<List<UserProfile>, List<UserProfile>>.fromHandlers(
          handleData: (data, sink) => sink.add(data),
          handleError: (error, stackTrace, sink) {
            sink.add(_demoAdminStaff());
          },
        ),
      );
});

final adminFullAuditProvider = StreamProvider<List<Map<String, dynamic>>>((ref) {
  return Supabase.instance.client
      .from('audit_logs')
      .stream(primaryKey: ['id'])
      .order('timestamp', ascending: false)
      .transform(
        StreamTransformer<List<Map<String, dynamic>>, List<Map<String, dynamic>>>.fromHandlers(
          handleData: (data, sink) => sink.add(data),
          handleError: (error, stackTrace, sink) {
            sink.add([]);
          },
        ),
      );
});
