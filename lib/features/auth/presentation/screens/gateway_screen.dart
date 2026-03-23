import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme.dart';
import '../../../../widgets/glass_app_bar.dart';
import '../../../../core/providers.dart';
import '../../../../core/models/user_profile.dart';

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
      final user = await authService.signInWithGoogle();

      if (user != null && mounted) {
        // 1. Fetch or create profile
        UserProfile? profile = await authService.getUserProfile(user.uid);
        
        if (profile == null) {
          profile = UserProfile(
            uid: user.uid,
            email: user.email ?? '',
            role: role,
            isVerified: false,
          );
          await authService.createUserProfile(profile);
        }

        // 2. Navigation logic
        if (mounted) {
          ref.read(userRoleProvider.notifier).setRole(profile.role);
          
          if (profile.role == 'pharmacy' && !profile.isVerified) {
            // Force verification for pharmacies
            Navigator.of(context).pushReplacementNamed('/pharmacy-verification');
          } else {
            Navigator.of(context).pushReplacementNamed('/success', arguments: profile.role);
          }
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
        leading: const SizedBox.shrink(),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.medical_services,
                  color: AppTheme.primaryColor, size: 20),
            ),
            const SizedBox(width: 10),
            Text(
              'VailMeds',
              style: GoogleFonts.inter(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryColor,
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
                  const SizedBox(height: 32),

                  // Patient Portal Card
                  _PortalCard(
                    icon: Icons.person,
                    iconLabel: 'Patient',
                    title: 'Patient Portal',
                    description:
                        'Access prescriptions, find nearby pharmacies, and manage your health profile.',
                    buttonLabel: 'Enter Patient Portal',
                    onPortalPressed: () =>
                        Navigator.of(context).pushNamed('/registration'),
                    onGooglePressed: () => _handleGoogleSignIn('patient'),
                  ),
                  const SizedBox(height: 20),

                  // Pharmacy Portal Card
                  _PortalCard(
                    icon: Icons.medication,
                    iconLabel: 'Pharmacy',
                    title: 'Pharmacy Portal',
                    description:
                        'Manage inventory, verify prescriptions, and connect with patients.',
                    buttonLabel: 'Enter Pharmacy Portal',
                    onPortalPressed: () => Navigator.of(context)
                        .pushNamed('/pharmacy-verification'),
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
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
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

    return Container(
      padding: const EdgeInsets.all(AppTheme.pagePadding),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        boxShadow: AppTheme.floatingShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon in circular primary/10 bg
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
            ),
            child: Icon(icon, color: AppTheme.primaryColor, size: 28),
          ),
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

          // Continue with Google button
          SizedBox(
            width: double.infinity,
            height: 48,
            child: OutlinedButton.icon(
              onPressed: onGooglePressed,
              icon: const Text(
                'G',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF4285F4),
                ),
              ),
              label: Text(
                'Continue with Google',
                style: GoogleFonts.inter(
                  color: AppTheme.textPrimaryColor,
                  fontWeight: FontWeight.w500,
                  fontSize: 15,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
