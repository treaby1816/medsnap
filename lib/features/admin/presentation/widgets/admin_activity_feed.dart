import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme.dart';
import '../../../../core/providers/admin_providers.dart';

/// Vertical activity feed showing recent support tickets.
/// Currently uses mock data; structured for Firestore stream.
class AdminActivityFeed extends ConsumerWidget {
  final VoidCallback? onViewAll;

  const AdminActivityFeed({super.key, this.onViewAll});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activityAsync = ref.watch(adminActivityProvider);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Activity',
                style: GoogleFonts.inter(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
              const Icon(Icons.history_rounded, size: 18, color: AppTheme.textTertiaryColor),
            ],
          ),
          const SizedBox(height: 16),
          
          activityAsync.when(
            data: (logs) => logs.isEmpty 
              ? _buildEmptyState()
              : Column(
                  children: logs.take(3).map((log) => Padding(
                    padding: const EdgeInsets.only(bottom: 14),
                    child: _buildActivityItem(
                      name: log['action'] ?? 'System',
                      role: log['type']?.toString().split('_').last ?? 'EVENT',
                      description: log['details'] ?? 'No details available',
                      timeAgo: _formatTimestamp(log['timestamp']),
                      avatarColor: _getColorForType(log['type']),
                    ),
                  )).toList(),
                ),
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
            error: (e, _) => Text('Error loading activity: $e', style: const TextStyle(fontSize: 11)),
          ),

          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: onViewAll,
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                side: const BorderSide(color: AppTheme.borderColor),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: Text(
                'View Detailed Audit',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
     return Padding(
       padding: const EdgeInsets.symmetric(vertical: 20),
       child: Center(
         child: Text(
           'No recent admin activity',
           style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textTertiaryColor),
         ),
       ),
     );
  }

  String _formatTimestamp(dynamic timestamp) {
    if (timestamp == null) return 'Just now';
    if (timestamp is Timestamp) {
      final dt = timestamp.toDate();
      final diff = DateTime.now().difference(dt);
      if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
      if (diff.inHours < 24) return '${diff.inHours}h ago';
      return '${diff.inDays}d ago';
    }
    return 'Recently';
  }

  Color _getColorForType(dynamic type) {
    switch (type?.toString()) {
      case 'PHARMACY_APPROVAL': return const Color(0xFF22C55E);
      case 'STAFF_INVITE': return const Color(0xFF3B82F6);
      case 'SYSTEM_CONFIG': return const Color(0xFFF59E0B);
      default: return AppTheme.primaryColor;
    }
  }

  Widget _buildActivityItem({
    required String name,
    required String role,
    required String description,
    required String timeAgo,
    required Color avatarColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CircleAvatar(
          radius: 18,
          backgroundColor: avatarColor.withValues(alpha: 0.15),
          child: Icon(Icons.person, size: 18, color: avatarColor),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    name,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.textPrimaryColor,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '($role)',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textSecondaryColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Text(
                description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppTheme.textSecondaryColor,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                timeAgo,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryColor,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
