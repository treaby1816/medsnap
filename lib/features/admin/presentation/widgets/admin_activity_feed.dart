import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme.dart';

/// Vertical activity feed showing recent support tickets.
/// Currently uses mock data; structured for Firestore stream.
class AdminActivityFeed extends StatelessWidget {
  final VoidCallback? onViewAll;

  const AdminActivityFeed({super.key, this.onViewAll});

  @override
  Widget build(BuildContext context) {
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
          Text(
            'Support Activity',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 16),
          _buildActivityItem(
            name: 'Sarah Jenkins',
            role: 'Pharmacist',
            description: 'Inquiry regarding batch verification for Schedule II...',
            timeAgo: '2 mins ago',
            avatarColor: const Color(0xFF3B82F6),
          ),
          const SizedBox(height: 14),
          _buildActivityItem(
            name: 'Unknown Patient',
            role: 'Patient',
            description: 'App crashing on prescription upload screen...',
            timeAgo: '14 mins ago',
            avatarColor: const Color(0xFF94A3B8),
          ),
          const SizedBox(height: 14),
          _buildActivityItem(
            name: 'David Miller',
            role: 'Admin',
            description: 'New pharmacy registration request: Alpine Wellness Center',
            timeAgo: '1 hour ago',
            avatarColor: AppTheme.primaryColor,
          ),
          const SizedBox(height: 20),
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
                'View All Tickets',
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
