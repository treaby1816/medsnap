import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme.dart';
import '../../../../core/providers/admin_providers.dart';

/// Vertical activity feed showing recent audit logs and system events.
class AdminActivityFeed extends ConsumerWidget {
  final VoidCallback? onViewAll;

  const AdminActivityFeed({super.key, this.onViewAll});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activityAsync = ref.watch(adminActivityProvider);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.borderColor),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 15, offset: const Offset(0, 5))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Audit Telemetry',
                style: GoogleFonts.inter(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
              const Icon(Icons.hub_rounded, size: 20, color: AppTheme.primaryColor),
            ],
          ),
          const SizedBox(height: 20),
          
          activityAsync.when(
            data: (logs) => logs.isEmpty 
              ? _buildEmptyState()
              : Column(
                  children: logs.take(4).map((log) => Padding(
                    padding: const EdgeInsets.only(bottom: 18),
                    child: _buildActivityItem(
                      action: log['action'] ?? 'System Event',
                      type: log['type']?.toString() ?? 'SYSTEM',
                      details: log['details'] ?? 'Routine security check performed.',
                      timeAgo: _formatTimestamp(log['timestamp']),
                    ),
                  )).toList(),
                ),
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 30),
                child: CircularProgressIndicator(strokeWidth: 2, color: AppTheme.primaryColor),
              ),
            ),
            error: (e, _) => Text('Telemetry Link Error: $e', style: const TextStyle(fontSize: 12, color: Colors.red)),
          ),

          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: onViewAll,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Access Full Ledger',
                    style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w800, color: AppTheme.primaryColor),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward_rounded, size: 16, color: AppTheme.primaryColor),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
     return Container(
       padding: const EdgeInsets.symmetric(vertical: 30),
       width: double.infinity,
       child: Column(
         children: [
           Icon(Icons.layers_clear_rounded, size: 32, color: AppTheme.textTertiaryColor.withValues(alpha: 0.4)),
           const SizedBox(height: 12),
           Text(
             'No recent telemetry records found.',
             style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textTertiaryColor),
           ),
         ],
       ),
     );
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'REAL-TIME';
    if (timestamp is Timestamp) {
      final dt = timestamp.toDate();
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 60) return '${diff.inMinutes}M AGO';
      if (diff.inHours < 24) return '${diff.inHours}H AGO';
      return '${diff.inDays}D AGO';
    }
    return 'RECENT';
  }

  Widget _buildActivityItem({
    required String action,
    required String type,
    required String details,
    required String timeAgo,
  }) {
    final Color typeColor = _getColorStream(type);
    final IconData typeIcon = _getIconStream(type);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: typeColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(child: Icon(typeIcon, size: 18, color: typeColor)),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    action,
                    style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.textPrimaryColor),
                  ),
                  Text(
                    timeAgo,
                    style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w800, color: AppTheme.textTertiaryColor, letterSpacing: 0.5),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                details,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textSecondaryColor, height: 1.4),
              ),
            ],
          ),
        ),
      ],
    );
  }

  IconData _getIconStream(String type) {
    switch (type) {
      case 'PHARMACY_APPROVAL': return Icons.verified_user_rounded;
      case 'PHARMACY_REJECT': return Icons.gpp_bad_rounded;
      case 'STAFF_INVITE': return Icons.person_add_rounded;
      case 'SYSTEM_CONFIG': return Icons.settings_suggest_rounded;
      case 'SECURITY_ALERT': return Icons.security_rounded;
      default: return Icons.event_note_rounded;
    }
  }

  Color _getColorStream(String type) {
    switch (type) {
      case 'PHARMACY_APPROVAL': return const Color(0xFF22C55E);
      case 'PHARMACY_REJECT': return const Color(0xFFEF4444);
      case 'STAFF_INVITE': return const Color(0xFF3B82F6);
      case 'SYSTEM_CONFIG': return const Color(0xFFF59E0B);
      case 'SECURITY_ALERT': return const Color(0xFF7C3AED);
      default: return AppTheme.primaryColor;
    }
  }
}
