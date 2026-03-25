import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme.dart';
import '../../../../widgets/glass_app_bar.dart';

import '../../../../core/providers.dart';
import '../../../../core/models/user_profile.dart';

class PharmacyProfileScreen extends ConsumerWidget {
  const PharmacyProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userProfileAsync = ref.watch(userProfileProvider);
    
    return userProfileAsync.when(
      data: (profile) => _buildContent(context, ref, profile!),
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, s) => Scaffold(body: Center(child: Text('Error: $e'))),
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref, UserProfile profile) {
    final displayName = profile.displayName ?? profile.email.split('@')[0];
    
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: GlassAppBar(
        title: Text(
          'Profile',
          style: GoogleFonts.inter(
            color: AppTheme.textPrimaryColor,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.dark_mode_outlined,
                color: AppTheme.textPrimaryColor),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.pagePadding),
        child: Column(
          children: [
            // Profile Header
            Center(
              child: Column(
                children: [
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor:
                            AppTheme.primaryColor.withValues(alpha: 0.1),
                        backgroundImage: profile.photoUrl != null 
                            ? NetworkImage(profile.photoUrl!) 
                            : null,
                        child: profile.photoUrl == null 
                            ? const Icon(Icons.person, size: 50, color: AppTheme.primaryColor)
                            : null,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    displayName,
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimaryColor,
                    ),
                  ),
                  Text(
                    'Chief Pharmacist',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: AppTheme.textSecondaryColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Account Settings
            _buildOptionGroup(
              title: 'Account Settings',
              items: [
                _buildProfileOption(
                  icon: Icons.person_outline,
                  title: 'Personal Information',
                  onTap: () {},
                ),
                _buildProfileOption(
                  icon: Icons.notifications_none_rounded,
                  title: 'Notifications',
                  onTap: () {},
                ),
                _buildProfileOption(
                  icon: Icons.shield_outlined,
                  title: 'Security',
                  onTap: () {},
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Pharmacy Details
            _buildOptionGroup(
              title: 'Pharmacy Details',
              items: [
                _buildProfileOption(
                  icon: Icons.storefront_outlined,
                  title: 'Pharmacy Information',
                  onTap: () {},
                ),
                _buildProfileOption(
                  icon: Icons.inventory_2_outlined,
                  title: 'Inventory Settings',
                  onTap: () {},
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Logout Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  await ref.read(authServiceProvider).signOut();
                  if (context.mounted) {
                    Navigator.of(context).pushNamedAndRemoveUntil(
                      '/gateway',
                      (route) => false,
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      const Color(0xFFEF4444).withValues(alpha: 0.1),
                  foregroundColor: const Color(0xFFEF4444),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(AppTheme.buttonRadius),
                  ),
                ),
                child: Text('Log Out',
                    style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionGroup(
      {required String title, required List<Widget> items}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppTheme.textSecondaryColor,
              letterSpacing: 0.5,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppTheme.cardRadius),
            boxShadow: AppTheme.floatingShadow,
          ),
          child: Column(children: items),
        ),
      ],
    );
  }

  Widget _buildProfileOption({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: AppTheme.textSecondaryColor),
      title: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: AppTheme.textPrimaryColor,
        ),
      ),
      trailing: const Icon(Icons.chevron_right,
          color: AppTheme.textTertiaryColor, size: 20),
    );
  }
}