import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme.dart';

/// Glassmorphism header bar for the admin dashboard.
/// Contains global search, notifications, settings, and profile chip.
class AdminHeader extends StatelessWidget {
  final String adminName;
  final String adminRole;
  final VoidCallback? onProfileTap;
  final VoidCallback? onSettingsTap;
  final VoidCallback? onNotificationsTap;

  const AdminHeader({
    super.key,
    this.adminName = 'Dr. Alistair Vail',
    this.adminRole = 'SUPER ADMIN',
    this.onProfileTap,
    this.onSettingsTap,
    this.onNotificationsTap,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          height: 64,
          padding: const EdgeInsets.symmetric(horizontal: 24),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.82),
            border: Border(
              bottom: BorderSide(
                color: AppTheme.primaryColor.withValues(alpha: 0.08),
              ),
            ),
          ),
          child: Row(
            children: [
              // ── Search Bar ──
              Expanded(
                flex: 3,
                child: Container(
                  height: 40,
                  decoration: BoxDecoration(
                    color: AppTheme.backgroundColor,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppTheme.borderColor),
                  ),
                  child: Row(
                    children: [
                      const SizedBox(width: 12),
                      const Icon(Icons.search_rounded, size: 20, color: AppTheme.textTertiaryColor),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          style: GoogleFonts.inter(fontSize: 13),
                          decoration: InputDecoration(
                            hintText: 'Search medical records, pharmacies...',
                            hintStyle: GoogleFonts.inter(
                              fontSize: 13,
                              color: AppTheme.textTertiaryColor,
                            ),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const Spacer(flex: 2),

              // ── Notification Bell ──
              _buildIconButton(Icons.notifications_none_rounded, onNotificationsTap),
              const SizedBox(width: 4),

              // ── Settings ──
              _buildIconButton(Icons.settings_outlined, onSettingsTap),
              const SizedBox(width: 16),

              // ── Profile Chip ──
              InkWell(
                onTap: onProfileTap,
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  child: Row(
                    children: [
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            adminName,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimaryColor,
                            ),
                          ),
                          Text(
                            adminRole,
                            style: GoogleFonts.inter(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.primaryColor,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 10),
                      CircleAvatar(
                        radius: 18,
                        backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.15),
                        child: const Icon(Icons.person_rounded, size: 20, color: AppTheme.primaryColor),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIconButton(IconData icon, VoidCallback? onTap) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, size: 22, color: AppTheme.textSecondaryColor),
        ),
      ),
    );
  }
}
