import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme.dart';

/// Glassmorphism header bar for the admin dashboard.
class AdminHeader extends StatefulWidget {
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
  State<AdminHeader> createState() => _AdminHeaderState();
}

class _AdminHeaderState extends State<AdminHeader> {
  bool _isSearchFocused = false;

  @override
  Widget build(BuildContext context) {
    return ClipRect(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          height: 72,
          padding: const EdgeInsets.symmetric(horizontal: 32),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.7),
            border: Border(
              bottom: BorderSide(
                color: AppTheme.borderColor.withValues(alpha: 0.4),
              ),
            ),
          ),
          child: Row(
            children: [
              // ── Search Bar ──
              if (MediaQuery.of(context).size.width >= 600)
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: _isSearchFocused ? 400 : 320,
                  height: 44,
                  decoration: BoxDecoration(
                    color: _isSearchFocused ? Colors.white : AppTheme.backgroundColor.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _isSearchFocused ? AppTheme.primaryColor : AppTheme.borderColor,
                      width: _isSearchFocused ? 1.5 : 1,
                    ),
                    boxShadow: [
                      if (_isSearchFocused)
                        BoxShadow(
                          color: AppTheme.primaryColor.withValues(alpha: 0.1),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                    ],
                  ),
                  child: Row(
                    children: [
                      const SizedBox(width: 14),
                      Icon(
                        Icons.search_rounded, 
                        size: 20, 
                        color: _isSearchFocused ? AppTheme.primaryColor : AppTheme.textTertiaryColor
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Focus(
                          onFocusChange: (focused) => setState(() => _isSearchFocused = focused),
                          child: TextField(
                            style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500),
                            decoration: InputDecoration(
                              hintText: 'Search patients, pharmacies, or logs...',
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
                      ),
                    ],
                  ),
                ),

              const Spacer(),

              // ── Icons ──
              _buildIconButton(Icons.notifications_none_rounded, widget.onNotificationsTap),
              const SizedBox(width: 8),
              _buildIconButton(Icons.settings_outlined, widget.onSettingsTap),
              const SizedBox(width: 20),

              // ── Profile Chip ──
              InkWell(
                onTap: widget.onProfileTap,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.borderColor),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.02),
                        blurRadius: 10,
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            widget.adminName,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.textPrimaryColor,
                            ),
                          ),
                          Text(
                            widget.adminRole,
                            style: GoogleFonts.inter(
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: AppTheme.primaryColor,
                              letterSpacing: 0.8,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 12),
                      CircleAvatar(
                        radius: 16,
                        backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                        child: const Icon(Icons.person_rounded, size: 18, color: AppTheme.primaryColor),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(width: 12),
              _buildIconButton(Icons.power_settings_new_rounded, () {
                Navigator.of(context).pushNamedAndRemoveUntil('/gateway', (route) => false);
              }, color: Colors.redAccent.withValues(alpha: 0.8)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIconButton(IconData icon, VoidCallback? onTap, {Color? color}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.borderColor.withValues(alpha: 0.5)),
          ),
          child: Icon(icon, size: 20, color: color ?? AppTheme.textSecondaryColor),
        ),
      ),
    );
  }
}
