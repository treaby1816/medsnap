import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme.dart';
import '../../../../widgets/glass_app_bar.dart';
import '../../../../core/providers.dart';
import '../../../../core/models/user_profile.dart';
import '../../../../widgets/hover_card.dart';

class GatewayScreen extends ConsumerStatefulWidget {
  const GatewayScreen({super.key});

  @override
  ConsumerState<GatewayScreen> createState() => _GatewayScreenState();
}

class _GatewayScreenState extends ConsumerState<GatewayScreen> {
  bool _isLoading = false;

  Future<void> _handleGoogleSignIn(String role) async {
    setState(() => _isLoading = true);
    try {
      final authService = ref.read(authServiceProvider);
      final authResult = await authService.signInWithGoogle(role: role);

      if (authResult.user != null && mounted) {
        // Find existing profile
        UserProfile? profile = await authService.getUserProfile(authResult.user!.id);
        
        if (profile == null) {
          // Fallback if sync failed internally
          profile = UserProfile(
            uid: authResult.user!.id,
            email: authResult.user!.email ?? '',
            name: (authResult.user!.userMetadata?['full_name'] ?? authResult.user!.userMetadata?['name']) ?? 'New User',
            role: role,
            isVerified: false,
          );
          await authService.createUserProfile(profile);
        }

        if (mounted) {
          ref.read(userRoleProvider.notifier).setRole(profile.role);
          
          // ALWAYS show Success screen as requested by the user.
          // The SuccessScreen handles individual role routing (e.g., to Verification for pharmacies).
          Navigator.of(context).pushReplacementNamed('/success', arguments: {
            'role': profile.role,
            'isReturningUser': !authResult.isNewUser,
          });
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: GlassAppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppTheme.textPrimaryColor, size: 20),
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              ref.read(onboardingStageProvider.notifier).state = 'welcome';
            }
          },
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              'assets/images/logo2.png',
              width: 32,
              height: 32,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: Text('V', style: TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'VailMeds',
              style: GoogleFonts.inter(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.help_outline,
                color: AppTheme.textSecondaryColor, size: 24),
          ),
        ],
      ),
      body: Stack(
        children: [
          // Decorative blur: bottom-left
          Positioned(
            bottom: -30,
            left: -30,
            child: _buildDecorativeBlur(),
          ),
          // Decorative blur: top-right
          Positioned(
            top: -30,
            right: -30,
            child: _buildDecorativeBlur(),
          ),

          SafeArea(
            top: false,
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppTheme.pagePadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 28),

                  // Title
                  Text(
                    'Choose Your Portal',
                    style: textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Select how you\'d like to access VailMeds.',
                    style: textTheme.bodyLarge?.copyWith(
                        color: AppTheme.textSecondaryColor),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 20),



                  // Patient Portal Card
                  _PortalCard(
                    icon: Icons.person,
                    iconLabel: 'Patient',
                    title: 'Patient Portal',
                    description:
                        'Access prescriptions, find nearby pharmacies, and manage your health profile.',
                    buttonLabel: 'Enter Patient Portal',
                    onPortalPressed: () {
                      Navigator.of(context).pushNamed('/registration');
                    },
                    onGooglePressed: () => _handleGoogleSignIn('patient'),
                  ),
                  const SizedBox(height: 20),

                  _PortalCard(
                    icon: Icons.medication,
                    iconLabel: 'Pharmacy',
                    title: 'Pharmacy Portal',
                    description:
                        'Manage inventory, verify prescriptions, and connect with patients.',
                    buttonLabel: 'Enter Pharmacy Portal',
                    onPortalPressed: () {
                      Navigator.of(context).pushNamed('/registration', arguments: 'pharmacy');
                    },
                    onGooglePressed: () => _handleGoogleSignIn('pharmacy'),
                  ),
                  const SizedBox(height: 36),

                  // Security Footer
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.lock_outline,
                          size: 14, color: AppTheme.textTertiaryColor),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          'Secure 256-bit encrypted connection. Your health data is protected.',
                          style: textTheme.bodySmall,
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Privacy Links
                  Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    spacing: 4.0,
                    children: [
                      _buildLink('Privacy Policy', '/privacy'),
                      _buildDot(),
                      _buildLink('Terms of Service', '/terms'),
                      _buildDot(),
                      _buildLink('Contact Support', '/support'),
                    ],
                  ),
                  const SizedBox(height: AppTheme.pagePadding),
                ],
              ),
            ),
          ),
          if (_isLoading)
            Container(
              color: Colors.black.withValues(alpha: 0.3),
              child: const Center(
                child: CircularProgressIndicator(
                  color: AppTheme.primaryColor,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildDecorativeBlur() {
    return Container(
      width: 96,
      height: 96,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppTheme.primaryColor.withValues(alpha: 0.05),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 48, sigmaY: 48),
        child: Container(color: Colors.transparent),
      ),
    );
  }

  Widget _buildLink(String text, String route) {
    return GestureDetector(
      onTap: () => Navigator.of(context).pushNamed(route),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 12,
          color: AppTheme.primaryColor,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  Widget _buildDot() {
    return const Padding(
      padding: EdgeInsets.symmetric(horizontal: 8),
      child: Text('·',
          style:
              TextStyle(color: AppTheme.textTertiaryColor, fontSize: 16)),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
class _PortalCard extends StatelessWidget {
  final IconData icon;
  final String iconLabel;
  final String title;
  final String description;
  final String buttonLabel;
  final VoidCallback onPortalPressed;
  final VoidCallback onGooglePressed;

  const _PortalCard({
    required this.icon,
    required this.iconLabel,
    required this.title,
    required this.description,
    required this.buttonLabel,
    required this.onPortalPressed,
    required this.onGooglePressed,
  });

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return HoverCard(
      borderRadius: BorderRadius.circular(AppTheme.cardRadius),
      padding: const EdgeInsets.all(AppTheme.pagePadding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Bare Icon (Standard & Professional Appearance)
          Icon(icon, color: AppTheme.primaryColor, size: 36),
          const SizedBox(height: 16),
          Text(
            title,
            style: textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),

          // Enter Portal Button
          SizedBox(
            width: double.infinity,
            height: AppTheme.buttonHeight,
            child: ElevatedButton(
              onPressed: onPortalPressed,
              child: Text(buttonLabel),
            ),
          ),
          const SizedBox(height: 12),

          // --- SOCIAL LOGIN GRID (Dubai LifeOS Style) ---
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildSquareSocialBtn(
                iconWidget: const Text(
                  'G',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF4285F4)),
                ),
                label: 'Google',
                onTap: onGooglePressed,
              ),
              const SizedBox(width: 20),
              _buildSquareSocialBtn(
                iconWidget: const Icon(Icons.apple, size: 30, color: AppTheme.textPrimaryColor),
                label: 'Apple',
                tagText: 'Soon',
                onTap: null,
              ),
            ],
          ),
          const SizedBox(height: 16),
          Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Text(
                'By continuing, you agree to our Terms of Use and Privacy Policy.',
                style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textTertiaryColor),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSquareSocialBtn({
    required Widget iconWidget,
    required String label,
    required VoidCallback? onTap,
    String? tagText,
  }) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            width: 100,
            height: 90,
            decoration: BoxDecoration(
              color: onTap == null ? AppTheme.backgroundColor : Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.borderColor, width: 1.5),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                iconWidget,
                const SizedBox(height: 8),
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: onTap == null ? AppTheme.textTertiaryColor : AppTheme.textPrimaryColor,
                  ),
                ),
              ],
            ),
          ),
        ),
        if (tagText != null)
          Positioned(
            top: -8,
            right: -8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFEAB308),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                tagText,
                style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.black),
              ),
            ),
          ),
      ],
    );
  }
}
