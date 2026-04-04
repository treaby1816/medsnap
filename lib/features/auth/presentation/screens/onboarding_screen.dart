import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme.dart';
import '../../../../widgets/glass_app_bar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers.dart';

class OnboardingScreen extends ConsumerWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
          // Decorative glow: bottom-left
          Positioned(
            bottom: -40,
            left: -40,
            child: _buildGlow(),
          ),
          // Decorative glow: top-right
          Positioned(
            top: -40,
            right: -40,
            child: _buildGlow(),
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
                    'Get Started',
                    style: textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Choose your portal to begin your health journey.',
                    style: textTheme.bodyLarge?.copyWith(
                        color: AppTheme.textSecondaryColor),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 32),

                  // Patient Portal Card
                  _PortalCard(
                    icon: Icons.person,
                    title: 'Patient Portal',
                    description:
                        'Access prescriptions, find nearby pharmacies, and manage your health profile.',
                    buttonLabel: 'Enter Patient Portal',
                    onPortalPressed: () =>
                        Navigator.of(context).pushNamed('/registration'),
                    onGooglePressed: () {
                      ref.read(authServiceProvider).signInWithGoogle(role: 'patient');
                    },
                  ),
                  const SizedBox(height: 20),

                  // Pharmacy Portal Card
                  _PortalCard(
                    icon: Icons.assignment,
                    title: 'Pharmacy Portal',
                    description:
                        'Manage inventory, verify prescriptions, and connect with patients.',
                    buttonLabel: 'Enter Pharmacy Portal',
                    onPortalPressed: () => Navigator.of(context)
                        .pushNamed('/pharmacy-verification'),
                    onGooglePressed: () {},
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
                  const SizedBox(height: AppTheme.pagePadding),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGlow() {
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
}

// ─────────────────────────────────────────────────────────────────────
class _PortalCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final String buttonLabel;
  final VoidCallback onPortalPressed;
  final VoidCallback onGooglePressed;

  const _PortalCard({
    required this.icon,
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
        border: Border.all(
          color: AppTheme.primaryColor.withValues(alpha: 0.08),
        ),
        boxShadow: AppTheme.floatingShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Icon in soft orange circle
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
          Text(title, style: textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(description, style: textTheme.bodyMedium),
          const SizedBox(height: 24),

          // Enter Portal button
          SizedBox(
            width: double.infinity,
            height: AppTheme.buttonHeight,
            child: ElevatedButton(
              onPressed: onPortalPressed,
              child: Text(buttonLabel),
            ),
          ),
          const SizedBox(height: 12),

          // Continue with Google
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
