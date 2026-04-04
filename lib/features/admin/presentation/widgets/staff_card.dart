import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme.dart';
import '../../../../core/models/user_profile.dart';

/// Premium Staff Profile Card with Dubai LifeOS aesthetics.
class StaffCard extends StatelessWidget {
  final UserProfile staff;
  final VoidCallback? onEdit;
  final bool isActive;

  const StaffCard({
    super.key,
    required this.staff,
    this.onEdit,
    this.isActive = true,
  });

  @override
  Widget build(BuildContext context) {
    final roleColor = staff.role == 'super_admin' ? const Color(0xFFEC5B13) : const Color(0xFF0F172A);
    final statusColor = isActive ? const Color(0xFF22C55E) : AppTheme.textTertiaryColor;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header: Avatar & Status ──
          Row(
            children: [
              Stack(
                children: [
                  Container(
                    padding: const EdgeInsets.all(2),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: statusColor.withValues(alpha: 0.3), width: 2),
                    ),
                    child: CircleAvatar(
                      radius: 28,
                      backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                      backgroundImage: staff.photoUrl != null ? NetworkImage(staff.photoUrl!) : null,
                      child: staff.photoUrl == null 
                          ? Text(staff.name.substring(0, 1).toUpperCase(), style: GoogleFonts.inter(fontWeight: FontWeight.w800, color: AppTheme.primaryColor))
                          : null,
                    ),
                  ),
                  Positioned(
                    right: 2,
                    bottom: 2,
                    child: Container(
                      width: 12,
                      height: 12,
                      decoration: BoxDecoration(
                        color: statusColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      staff.displayName ?? staff.name,
                      style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.textPrimaryColor),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: roleColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        staff.role.toUpperCase().replaceAll('_', ' '),
                        style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w900, color: roleColor, letterSpacing: 0.5),
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.more_vert_rounded, size: 20, color: AppTheme.textTertiaryColor),
                onPressed: onEdit,
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ── Bio/Description ──
          Text(
            staff.bio ?? 'Administrative Command Officer',
            style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondaryColor, height: 1.5, fontStyle: FontStyle.italic),
          ),
          const SizedBox(height: 20),

          // ── Stats ──
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.backgroundColor.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildMiniStat('AUDITS', '142'),
                _buildDivider(),
                _buildMiniStat('SLA', '4.2m'),
                _buildDivider(),
                _buildMiniStat('RATING', '5.0'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniStat(String label, String value) {
    return Column(
      children: [
        Text(label, style: GoogleFonts.inter(fontSize: 8, fontWeight: FontWeight.w800, color: AppTheme.textTertiaryColor, letterSpacing: 0.5)),
        const SizedBox(height: 4),
        Text(value, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w800, color: AppTheme.textPrimaryColor)),
      ],
    );
  }

  Widget _buildDivider() {
    return Container(width: 1, height: 20, color: AppTheme.borderColor);
  }
}
