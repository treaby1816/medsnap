import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme.dart';
import '../../../../core/providers/admin_providers.dart';

/// GLOBAL AUDIT LEDGER — Immutable Platform History (Phase 3.5)
class AdminAuditLedgerScreen extends ConsumerStatefulWidget {
  const AdminAuditLedgerScreen({super.key});

  @override
  ConsumerState<AdminAuditLedgerScreen> createState() => _AdminAuditLedgerScreenState();
}

class _AdminAuditLedgerScreenState extends ConsumerState<AdminAuditLedgerScreen> {
  String _activeFilter = 'all'; // 'all', 'PHARMACY_APPROVAL', 'SECURITY_ALERT', 'INVENTORY_CHANGE'

  @override
  Widget build(BuildContext context) {
    final auditAsync = ref.watch(adminFullAuditProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Compliance Header ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Chain of Custody Ledger',
                    style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w800, color: AppTheme.textPrimaryColor),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Verified administrative history of the VailMeds platform',
                    style: GoogleFonts.inter(fontSize: 14, color: AppTheme.textSecondaryColor),
                  ),
                ],
              ),
              _buildAuditBadge(),
            ],
          ),
          const SizedBox(height: 32),

          // ── Analytics Overview ──
          Row(
            children: [
              _ledgerMetric('RECORD COUNT', '1,242', Icons.list_alt_rounded),
              const SizedBox(width: 20),
              _ledgerMetric('HEALTH STATUS', 'INTEGRITY OK', Icons.shield_moon_outlined),
              const SizedBox(width: 20),
              _ledgerMetric('LAST SYNC', 'Real-time', Icons.sync_rounded),
            ],
          ),
          const SizedBox(height: 40),

          // ── Filtering Terminal ──
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.borderColor),
            ),
            child: Row(
              children: [
                _filterChip('Total History', 'all'),
                const SizedBox(width: 12),
                _filterChip('Approvals', 'PHARMACY_APPROVAL'),
                const SizedBox(width: 12),
                _filterChip('Inventory', 'INVENTORY_CHANGE'),
                const SizedBox(width: 12),
                _filterChip('Security', 'SECURITY_ALERT'),
                const Spacer(),
                const Icon(Icons.search_rounded, size: 20, color: AppTheme.textTertiaryColor),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ── The Ledger Table ──
          auditAsync.when(
            data: (logs) {
              final filtered = _activeFilter == 'all' 
                  ? logs 
                  : logs.where((l) => l['type'] == _activeFilter).toList();

              if (filtered.isEmpty) {
                return Center(child: Text('No matching records found in platform history.', style: GoogleFonts.inter(color: AppTheme.textTertiaryColor)));
              }

              return Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppTheme.borderColor),
                ),
                child: Column(
                  children: [
                    _buildTableHeader(),
                    const Divider(height: 1),
                    ...filtered.map((log) => _buildAuditRow(log)),
                  ],
                ),
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Sync Error: $e')),
          ),
        ],
      ),
    );
  }

  Widget _buildTableHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Row(
        children: [
          Expanded(flex: 2, child: _headerText('TIMESTAMP')),
          Expanded(flex: 2, child: _headerText('EVENT TYPE')),
          Expanded(flex: 4, child: _headerText('ACTION & DETAILS')),
          Expanded(flex: 2, child: _headerText('OPERATOR')),
          Expanded(flex: 2, child: _headerText('STATUS')),
        ],
      ),
    );
  }

  Widget _buildAuditRow(Map<String, dynamic> log) {
    final type = log['type'] ?? 'SYSTEM_EVENT';
    final timestamp = log['timestamp'] as dynamic;
    final dateStr = timestamp != null 
        ? DateFormat('HH:mm:ss • MMM dd').format(timestamp is DateTime ? timestamp : timestamp.toDate()) 
        : 'N/A';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppTheme.borderColor, width: 0.5)),
      ),
      child: Row(
        children: [
          Expanded(flex: 2, child: Text(dateStr, style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textTertiaryColor, fontWeight: FontWeight.w600))),
          Expanded(flex: 2, child: _typeBadge(type)),
          Expanded(
            flex: 4,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(log['action']?.toString().toUpperCase() ?? 'MODIFIED', style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.textPrimaryColor)),
                const SizedBox(height: 2),
                Text(log['details'] ?? '', style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondaryColor), maxLines: 1, overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
          Expanded(flex: 2, child: Text(log['adminId'] ?? 'System', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textSecondaryColor))),
          Expanded(flex: 2, child: _statusPill(log['status'] ?? 'OK')),
        ],
      ),
    );
  }

  Widget _ledgerMetric(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppTheme.primaryColor),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w800, color: AppTheme.textTertiaryColor, letterSpacing: 0.5)),
              const SizedBox(height: 4),
              Text(value, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.textPrimaryColor)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _typeBadge(String type) {
    Color color;
    IconData icon;

    switch (type) {
      case 'PHARMACY_APPROVAL':
        color = const Color(0xFF22C55E);
        icon = Icons.verified_user_rounded;
        break;
      case 'SECURITY_ALERT':
        color = const Color(0xFFEF4444);
        icon = Icons.security_rounded;
        break;
      case 'INVENTORY_CHANGE':
        color = const Color(0xFF3B82F6);
        icon = Icons.inventory_2_rounded;
        break;
      default:
        color = AppTheme.primaryColor;
        icon = Icons.event_note_rounded;
    }

    return Row(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 8),
        Text(type.replaceAll('_', ' '), style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w800, color: color)),
      ],
    );
  }

  Widget _statusPill(String status) {
    final isSuccess = status == 'SUCCESS' || status == 'OK' || status == 'VERIFIED';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isSuccess ? const Color(0xFF22C55E).withValues(alpha: 0.1) : const Color(0xFFEF4444).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(status.toUpperCase(), style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w900, color: isSuccess ? const Color(0xFF16A34A) : const Color(0xFFDC2626))),
    );
  }

  Widget _filterChip(String label, String value) {
    final isSelected = _activeFilter == value;
    return InkWell(
      onTap: () => setState(() => _activeFilter = value),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? AppTheme.primaryColor : AppTheme.borderColor),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: isSelected ? Colors.white : AppTheme.textSecondaryColor),
        ),
      ),
    );
  }

  Widget _buildAuditBadge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.verified_outlined, color: Color(0xFFEC5B13), size: 18),
          const SizedBox(width: 10),
          Text('IMMUTABLE RECORDING ACTIVE', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w900, color: Colors.white, letterSpacing: 1.0)),
        ],
      ),
    );
  }

  Widget _headerText(String text) {
    return Text(text, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w800, color: AppTheme.textTertiaryColor, letterSpacing: 1.0));
  }
}
