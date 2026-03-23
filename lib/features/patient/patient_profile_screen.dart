import 'dart:ui'; // Add this line
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme.dart';
import '../../core/app_router.dart';

class UserModel {
  final String name;
  final String email;
  final String bloodType;
  final String height;
  final String weight;
  final String photoUrl;

  const UserModel({
    required this.name,
    required this.email,
    required this.bloodType,
    required this.height,
    required this.weight,
    required this.photoUrl,
  });

  UserModel copyWith({
    String? name,
    String? email,
    String? bloodType,
    String? height,
    String? weight,
    String? photoUrl,
  }) {
    return UserModel(
      name: name ?? this.name,
      email: email ?? this.email,
      bloodType: bloodType ?? this.bloodType,
      height: height ?? this.height,
      weight: weight ?? this.weight,
      photoUrl: photoUrl ?? this.photoUrl,
    );
  }
}

// --- RIVERPOD STATE PROVIDER ---
// Serves as the global source of truth for the active patient profile data.
final userProvider = StateProvider<UserModel>((ref) {
  return const UserModel(
    name: 'Sarah Jenkins',
    email: 'sarah.jenkins@example.com',
    bloodType: 'O+',
    height: "5'8\"",
    weight: '145',
    photoUrl: 'https://lh3.googleusercontent.com/aida-public/AB6AXuA_RRPWMSGJ3B_a7Y4s4f1Qi9OilrZWcPR8aSsddJOpkZ4Nyuxri8J1UI-C0QRj5htl6D7aabdyl1otrWRWuAs9TtrffXbfLRVqAkbpyP-gOzCLc2Gq2bsKtkdL0o5b2IykvTt-vMVSdlTz3_x4V-JHryNtcf1JsuaaBPIpC223KyeoVKYyzB4ZyHgXAUrQFcDTGnJiOmTaNBvFwbJb-pNT4G_bolWXDd8hUBWkVmEYW-fpgS836BzTGCQH_rtFgIiJHYoYA4_tcrU',
  );
});

class PatientProfileScreen extends ConsumerWidget {
  const PatientProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Reactively watch the global user state
    final user = ref.watch(userProvider);
    final canPop = Navigator.of(context).canPop();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F6F6),
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(56.0),
        child: ClipRRect(
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: AppBar(
              backgroundColor: Colors.white.withValues(alpha: 0.8),
              elevation: 0,
              centerTitle: true,
              leading: canPop
                  ? IconButton(
                      icon: const Icon(Icons.arrow_back, color: AppTheme.primaryColor),
                      onPressed: () => Navigator.pop(context),
                    )
                  : const SizedBox(), 
              title: Text(
                'Profile',
                style: GoogleFonts.inter(
                  color: const Color(0xFF0F172A),
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                  letterSpacing: -0.5,
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.settings, color: AppTheme.primaryColor),
                  onPressed: () {},
                ),
              ],
            ),
          ),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.only(top: 100.0, bottom: 120.0, left: 16.0, right: 16.0),
        child: Column(
          children: [
            // Profile Avatar
            Center(
              child: Stack(
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 4),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                      image: DecorationImage(
                        image: NetworkImage(user.photoUrl),
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: () {
                        HapticFeedback.lightImpact();
                      },
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                          boxShadow: [
                            BoxShadow(
                              color: AppTheme.primaryColor.withValues(alpha: 0.3),
                              blurRadius: 8,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: const Icon(Icons.edit, color: Colors.white, size: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              user.name,
              style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0F172A),
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              user.email,
              style: GoogleFonts.inter(
                fontSize: 14,
                color: const Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 32),

            // Bento Health Summary
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.05)),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'HEALTH SUMMARY',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primaryColor,
                          letterSpacing: 1.0,
                        ),
                      ),
                      Text(
                        'UPDATED 2H AGO',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: _HealthMetric(
                          label: 'BLOOD TYPE',
                          value: user.bloodType,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _HealthMetric(
                          label: 'HEIGHT',
                          value: user.height,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _HealthMetric(
                          label: 'WEIGHT',
                          value: '${user.weight} lbs', // Subscript logic handled in component
                          isWeight: true,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Health Records
            const _SectionHeader(title: 'Health Records'),
            _SectionGroup(
              children: [
                _ProfileSectionItem(
                  icon: Icons.person_outline,
                  title: 'Personal Information',
                  trailing: Text('EDIT', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: AppTheme.primaryColor)),
                  onTap: () {},
                ),
                _ProfileSectionItem(
                  icon: Icons.history_edu,
                  title: 'Medical Records & History',
                  onTap: () {},
                ),
                _ProfileSectionItem(
                  icon: Icons.devices,
                  title: 'Connected Devices',
                  trailing: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _DeviceIcon(iconText: 'ios'),
                      SizedBox(width: 4),
                      _DeviceIcon(iconText: 'fit'),
                    ],
                  ),
                  onTap: () {},
                ),
                _ProfileSectionItem(
                  icon: Icons.verified_user_outlined,
                  title: 'Insurance Details',
                  isLast: true,
                  onTap: () {},
                ),
              ],
            ),
            const SizedBox(height: 24),

            // App Settings
            const _SectionHeader(title: 'App Settings'),
            _SectionGroup(
              children: [
                _ProfileSectionItem(
                  icon: Icons.notifications_none,
                  title: 'Notification Preferences',
                  onTap: () {},
                ),
                _ProfileSectionItem(
                  icon: Icons.security,
                  title: 'Privacy & Security',
                  onTap: () {},
                ),
                _ProfileSectionItem(
                  icon: Icons.language,
                  title: 'Language',
                  trailing: Text('English (US)', style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF64748B))),
                  isLast: true,
                  onTap: () {},
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Support & Legal
            const _SectionHeader(title: 'Support & Legal'),
            _SectionGroup(
              children: [
                _ProfileSectionItem(
                  icon: Icons.help_outline,
                  title: 'Help Center',
                  onTap: () {},
                ),
                _ProfileSectionItem(
                  icon: Icons.description_outlined,
                  title: 'Terms of Service',
                  isLast: true,
                  onTap: () {},
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Logout Button
            SizedBox(
              width: double.infinity,
              child: TextButton.icon(
                onPressed: () {
                  HapticFeedback.lightImpact();
                  Navigator.pushReplacementNamed(context, AppRouter.welcome);
                },
                icon: const Icon(Icons.logout, color: Colors.red),
                label: Text(
                  'Logout',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.red,
                  ),
                ),
                style: TextButton.styleFrom(
                  backgroundColor: Colors.red.withValues(alpha: 0.05),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: Colors.red.withValues(alpha: 0.1)),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 32),
            
            // Version
            Text(
              'VAILMEDS CLINICAL V4.2.1',
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF94A3B8),
                letterSpacing: 2.0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HealthMetric extends StatelessWidget {
  final String label;
  final String value;
  final bool isWeight;

  const _HealthMetric({required this.label, required this.value, this.isWeight = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.05)),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF64748B),
              letterSpacing: -0.2,
            ),
          ),
          const SizedBox(height: 4),
          if (isWeight)
            RichText(
              text: TextSpan(
                text: value.replaceAll(' lbs', ''),
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primaryColor,
                ),
                children: [
                  TextSpan(
                    text: ' lbs',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w400,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ],
              ),
            )
          else
            Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppTheme.primaryColor,
              ),
            ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(
          title.toUpperCase(),
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF94A3B8),
            letterSpacing: 1.0,
          ),
        ),
      ),
    );
  }
}

class _SectionGroup extends StatelessWidget {
  final List<Widget> children;

  const _SectionGroup({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.05)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        children: children,
      ),
    );
  }
}

class _ProfileSectionItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget? trailing;
  final bool isLast;
  final VoidCallback onTap;

  const _ProfileSectionItem({
    required this.icon,
    required this.title,
    this.trailing,
    this.isLast = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          border: isLast ? null : Border(bottom: BorderSide(color: Colors.grey.withValues(alpha: 0.1))),
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF64748B), size: 22),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF334155),
                ),
              ),
            ),
            if (trailing != null) trailing!
            else const Icon(Icons.chevron_right, color: Color(0xFF94A3B8), size: 20),
          ],
        ),
      ),
    );
  }
}

class _DeviceIcon extends StatelessWidget {
  final String iconText;

  const _DeviceIcon({required this.iconText});

  @override
  Widget build(BuildContext context) {
    IconData ic = Icons.apple;
    if (iconText == 'fit') ic = Icons.watch;
    
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: const BoxDecoration(
        color: Color(0xFFF1F5F9),
        shape: BoxShape.circle,
      ),
      child: Icon(ic, size: 12, color: const Color(0xFF0F172A)),
    );
  }
}