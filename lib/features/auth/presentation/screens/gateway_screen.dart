import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme.dart';
import '../../../../widgets/glass_app_bar.dart';
import '../../../../core/providers.dart';
import '../../../../core/models/user_profile.dart';
import '../../../../widgets/hover_card.dart';
import '../../../../widgets/hover_social_button.dart';

class GatewayScreen extends ConsumerStatefulWidget {
  const GatewayScreen({super.key});

  @override
  ConsumerState<GatewayScreen> createState() => _GatewayScreenState();
}

class _GatewayScreenState extends ConsumerState<GatewayScreen> {
  bool _isLoading = false;
  bool _agreedToTerms = false;

  Future<void> _handleGoogleSignIn(String role) async {
    if (!_agreedToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please agree to the Terms of Use and Privacy Policy to continue.')),
      );
      return;
    }
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
    final isDesktop = MediaQuery.of(context).size.width >= 600;

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



                  // Responsive Portal Cards
                  Builder(
                    builder: (context) {
                      final pharmacyCard = _PortalCard(
                        icon: Icons.medication,
                        iconLabel: 'Pharmacy',
                        title: 'Pharmacy Portal',
                        description: 'Manage inventory, verify prescriptions, and connect with patients.',
                        buttonLabel: 'Enter Pharmacy Portal',
                        onPortalPressed: () {
                          if (!_agreedToTerms) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please agree to the Terms of Use and Privacy Policy to continue.')));
                            return;
                          }
                          Navigator.of(context).pushNamed('/registration', arguments: 'pharmacy');
                        },
                        onGooglePressed: () => _handleGoogleSignIn('pharmacy'),
                      );

                      final patientCard = _PortalCard(
                        icon: Icons.person,
                        iconLabel: 'Patient',
                        title: 'Patient Portal',
                        description: 'Access prescriptions, find nearby pharmacies, and manage your health profile.',
                        buttonLabel: 'Enter Patient Portal',
                        onPortalPressed: () {
                          if (!_agreedToTerms) {
                            ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please agree to the Terms of Use and Privacy Policy to continue.')));
                            return;
                          }
                          Navigator.of(context).pushNamed('/registration', arguments: 'patient');
                        },
                        onGooglePressed: () => _handleGoogleSignIn('patient'),
                      );

                      if (isDesktop) {
                        return IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(child: pharmacyCard),
                              const SizedBox(width: 20),
                              Expanded(child: patientCard),
                            ],
                          ),
                        );
                      } else {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            pharmacyCard,
                            const SizedBox(height: 20),
                            patientCard,
                          ],
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 24),

                  // Global Terms Checkbox below Portals
                  Center(
                    child: GestureDetector(
                      onTap: () {
                        setState(() {
                          _agreedToTerms = !_agreedToTerms;
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: _agreedToTerms
                              ? AppTheme.primaryColor.withValues(alpha: 0.05)
                              : AppTheme.backgroundColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _agreedToTerms ? AppTheme.primaryColor : Colors.grey,
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Checkbox(
                              value: _agreedToTerms,
                              onChanged: (val) {
                                setState(() {
                                  _agreedToTerms = val ?? false;
                                });
                              },
                              activeColor: AppTheme.primaryColor,
                              side: BorderSide(
                                color: _agreedToTerms ? AppTheme.primaryColor : Colors.grey,
                                width: 2,
                              ),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                            ),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                'I agree to the Terms of Use and Privacy Policy',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: _agreedToTerms
                                      ? AppTheme.primaryColor
                                      : AppTheme.textSecondaryColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
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
              HoverSocialButton(
                iconWidget: const Text(
                  'G',
                  style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF4285F4)),
                ),
                label: 'Google',
                hoverColor: const Color(0xFF4285F4),
                onTap: onGooglePressed,
              ),
              const SizedBox(width: 20),
              HoverSocialButton(
                iconWidget: const Icon(Icons.apple, size: 30, color: AppTheme.textPrimaryColor),
                label: 'Apple',
                tagText: 'Soon',
                hoverColor: const Color(0xFF0F172A),
                onTap: null,
              ),
            ],
          ),
        ],
      ),
    );
  }


}
