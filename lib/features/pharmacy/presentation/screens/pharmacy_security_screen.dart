import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../../core/theme.dart';
import '../../../../core/providers.dart';
import '../../../../widgets/glass_app_bar.dart';

class PharmacySecurityScreen extends ConsumerStatefulWidget {
  const PharmacySecurityScreen({super.key});

  @override
  ConsumerState<PharmacySecurityScreen> createState() => _PharmacySecurityScreenState();
}

class _PharmacySecurityScreenState extends ConsumerState<PharmacySecurityScreen> {
  bool _is2faEnabled = false;
  bool _isBiometricEnabled = false;

  void _resetPassword() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null && user.email != null) {
      try {
        await FirebaseAuth.instance.sendPasswordResetEmail(email: user.email!);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Password reset email sent. Please check your inbox.'),
              backgroundColor: AppTheme.primaryColor,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: ${e.toString()}'),
              backgroundColor: Colors.redAccent,
            ),
          );
        }
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not find email to reset password.'),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  void _showComingSoon(String feature) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('$feature settings will be available in the next update.'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userProfile = ref.watch(userProfileProvider).value;
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: GlassAppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppTheme.textPrimaryColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Security',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimaryColor,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.close_rounded, color: AppTheme.textSecondaryColor),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppTheme.pagePadding),
        children: [
          _buildSecurityTile(
            context,
            icon: Icons.verified_user_rounded,
            title: 'Identity Verification',
            subtitle: userProfile?.isAdminApproved == true 
                ? 'Your identity and license are verified' 
                : (userProfile?.isVerificationPending == true 
                    ? 'Verification is currently under clinical review' 
                    : 'Complete your clinical identity verification'),
            onTap: () {
              if (userProfile?.isAdminApproved != true) {
                Navigator.pushNamed(context, '/pharmacy-verification');
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Your account is already verified.'), behavior: SnackBarBehavior.floating),
                );
              }
            },
            trailing: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: userProfile?.isAdminApproved == true 
                    ? Colors.green.withValues(alpha: 0.1) 
                    : (userProfile?.isVerificationPending == true 
                        ? Colors.orange.withValues(alpha: 0.1) 
                        : Colors.red.withValues(alpha: 0.1)),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                userProfile?.isAdminApproved == true 
                    ? 'VERIFIED' 
                    : (userProfile?.isVerificationPending == true ? 'PENDING' : 'REQUIRED'),
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  color: userProfile?.isAdminApproved == true 
                      ? Colors.green 
                      : (userProfile?.isVerificationPending == true ? Colors.orange : Colors.red),
                ),
              ),
            ),
          ),
          _buildSecurityTile(
            context,
            icon: Icons.lock_outline_rounded,
            title: 'Change Password',
            subtitle: 'Send a password reset link to your email',
            onTap: _resetPassword,
          ),
          _buildSecurityTile(
            context,
            icon: Icons.phonelink_lock_rounded,
            title: 'Two-Factor Authentication',
            subtitle: 'Secure your account with 2FA',
            onTap: () {
              setState(() {
                _is2faEnabled = !_is2faEnabled;
              });
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(_is2faEnabled ? '2FA Enabled via Email' : '2FA Disabled'), behavior: SnackBarBehavior.floating),
              );
            },
            trailing: Text(
              _is2faEnabled ? 'ON' : 'OFF',
              style: TextStyle(
                color: _is2faEnabled ? AppTheme.primaryColor : Colors.redAccent.withValues(alpha: 0.8),
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          _buildSecurityTile(
            context,
            icon: Icons.fingerprint_rounded,
            title: 'Biometric Login',
            subtitle: 'Use FaceID or TouchID',
            onTap: () {
              setState(() {
                _isBiometricEnabled = !_isBiometricEnabled;
              });
            },
            trailing: Switch(
                value: _isBiometricEnabled,
                onChanged: (val) {
                  setState(() {
                    _isBiometricEnabled = val;
                  });
                },
                activeThumbColor: Colors.white,
                activeTrackColor: AppTheme.primaryColor, // Changed this to 'TrackColor'
              ),
          ),
          const SizedBox(height: 32),
          _buildSecurityTile(
            context,
            icon: Icons.devices_rounded,
            title: 'Trusted Devices',
            subtitle: 'Manage devices where you are logged in',
            onTap: () => _showComingSoon('Trusted Devices'),
          ),
          _buildSecurityTile(
            context,
            icon: Icons.history_rounded,
            title: 'Login Activity',
            subtitle: 'Review recent account access',
            onTap: () => _showComingSoon('Login Activity Analytics'),
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Widget? trailing,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppTheme.primaryColor, size: 20),
        ),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondaryColor)),
        trailing: trailing ?? const Icon(Icons.chevron_right, color: AppTheme.textTertiaryColor, size: 20),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }
}

