import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme.dart';
import '../../../../widgets/glass_app_bar.dart';
import '../../../../widgets/hover_social_button.dart';
import '../../../../core/providers.dart';

class RegistrationScreen extends ConsumerStatefulWidget {
  final String initialRole;
  const RegistrationScreen({super.key, this.initialRole = 'patient'});

  @override
  ConsumerState<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends ConsumerState<RegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  bool _agreedToTerms = false;
  bool _agreedToPrivacy = false;

  void _showAgreementWarning() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Please agree to both the Terms of Use and Privacy Policy to continue.'),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    final isConsented = ref.read(agreedToTermsProvider) && ref.read(agreedToPrivacyProvider);
    if (!isConsented && (!_agreedToTerms || !_agreedToPrivacy)) {
      _showAgreementWarning();
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    setState(() => _isLoading = true);
    try {
      final authService = ref.read(authServiceProvider);
      final role = widget.initialRole; 
      
      final authResult = await authService.registerWithEmail(
        _emailController.text.trim(),
        _passwordController.text.trim(),
        _nameController.text.trim(),
        _phoneController.text.trim(),
        role,
      );

      if (authResult.user != null) {
        ref.read(userRoleProvider.notifier).setRole(role);
        
        setState(() => _isLoading = false); // Hide loader before navigation
        
        navigator.pushReplacementNamed('/success', arguments: {
          'role': role,
          'isReturningUser': false,
        });
      }
    } on AuthException catch (e) {
      if (e.message.toLowerCase().contains('already registered')) {
        _showExistingUserPrompt(messenger);
      } else {
        messenger.showSnackBar(
          SnackBar(content: Text('Registration failed: ${e.message}')),
        );
      }
    } catch (e) {
      String errorMessage = e.toString().replaceAll('Exception: ', '');
      if (errorMessage.contains('configuration-not-found')) {
        errorMessage = 'Email/Password sign-in is not enabled in Firebase Console.';
      }
      messenger.showSnackBar(
        SnackBar(content: Text('Registration failed: $errorMessage')),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showExistingUserPrompt(ScaffoldMessengerState messenger) {
    messenger.showSnackBar(
      SnackBar(
        content: const Text('This email is already registered.'),
        duration: const Duration(seconds: 8),
        action: SnackBarAction(
          label: 'SIGN IN NOW',
          textColor: AppTheme.primaryColor,
          onPressed: _handleExistingUserSignIn,
        ),
      ),
    );
  }

  Future<void> _handleExistingUserSignIn() async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    setState(() => _isLoading = true);
    try {
      final authService = ref.read(authServiceProvider);
      final authResult = await authService.signInWithEmail(
        _emailController.text.trim(),
        _passwordController.text.trim(),
      );

      if (authResult.user != null) {
        // Fetch role to ensure proper routing
        final profile = await authService.getUserProfile(authResult.user!.id);
        if (profile != null) {
          ref.read(userRoleProvider.notifier).setRole(profile.role);
          final route = profile.role == 'pharmacy' ? '/pharmacy-dashboard' : '/main';
          
          setState(() => _isLoading = false); // Hide loader before navigation
          
          navigator.pushNamedAndRemoveUntil(route, (r) => false);
        }
      }
    } on AuthException catch (e) {
      if (e.message.toLowerCase().contains('invalid login credentials')) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Incorrect password. Please try again.')),
        );
      } else {
        messenger.showSnackBar(
          SnackBar(content: Text('Sign in failed: ${e.message}')),
        );
      }
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('Sign in failed: ${e.toString().replaceAll('Exception: ', '')}')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
        title: RichText(
          text: TextSpan(
            children: [
              TextSpan(
                text: 'Vail',
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
              TextSpan(
                text: 'Meds',
                style: GoogleFonts.inter(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryColor,
                ),
              ),
            ],
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTheme.pagePadding,
            vertical: 20.0,
          ),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Health Icon (Logo)
                Center(
                  child: Image.asset(
                    'assets/images/logo2.png',
                    width: 72,
                    height: 72,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: 72,
                      height: 72,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Center(
                        child: Text(
                          'V',
                          style: GoogleFonts.inter(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  widget.initialRole == 'pharmacy' ? 'Pharmacy Registration' : 'Create Your Account',
                  style: textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  widget.initialRole == 'pharmacy' ? 'Register your pharmacy branch securely.' : 'Join VailMeds to manage your health journey.',
                  style: textTheme.bodyMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 28),



                // Form Fields
                _buildField('Full Name', Icons.person_outline,
                    _nameController),
                const SizedBox(height: 14),
                _buildField('Email Address', Icons.email_outlined,
                    _emailController,
                    keyboardType: TextInputType.emailAddress),
                const SizedBox(height: 14),
                _buildField('Phone Number', Icons.phone_outlined,
                    _phoneController,
                    keyboardType: TextInputType.phone),
                const SizedBox(height: 14),

                // Password with toggle
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  enabled: !_isLoading,
                  decoration: InputDecoration(
                    hintText: 'Password',
                    prefixIcon: const Icon(Icons.lock_outline,
                        color: AppTheme.textTertiaryColor, size: 20),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePassword
                            ? Icons.visibility_off_outlined
                            : Icons.visibility_outlined,
                        color: AppTheme.textTertiaryColor,
                        size: 20,
                      ),
                      onPressed: () => setState(
                          () => _obscurePassword = !_obscurePassword),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Please enter a password';
                    }
                    if (value.length < 8) {
                      return 'Password must be at least 8 characters';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 28),

                // --- BEFORE YOU CONTINUE BLOCK ---
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppTheme.borderColor, width: 1.5),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      GestureDetector(
                        onTap: () {
                          final newVal = !_agreedToTerms;
                          setState(() => _agreedToTerms = newVal);
                          ref.read(agreedToTermsProvider.notifier).state = newVal;
                        },
                        child: Row(
                          children: [
                            SizedBox(
                              width: 24, height: 24,
                              child: Checkbox(
                                value: _agreedToTerms,
                                onChanged: (val) {
                                  final newVal = val ?? false;
                                  setState(() => _agreedToTerms = newVal);
                                  ref.read(agreedToTermsProvider.notifier).state = newVal;
                                },
                                activeColor: AppTheme.primaryColor,
                                side: const BorderSide(color: Colors.grey, width: 2), // explicitly visible border
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: RichText(
                                text: TextSpan(
                                  text: 'I agree to the ',
                                  style: GoogleFonts.inter(color: AppTheme.textSecondaryColor, fontSize: 13),
                                  children: [
                                    TextSpan(
                                      text: 'Terms of Use',
                                      style: GoogleFonts.inter(color: AppTheme.primaryColor, fontWeight: FontWeight.bold, decoration: TextDecoration.underline),
                                      // Note: Tap gesture recognizer normally needed here if we want just the text to route, 
                                      // but we're letting the whole row check the box now. If user clicks text, it checks the box.
                                      // Added a separate button for terms if needed.
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      GestureDetector(
                        onTap: () {
                          final newVal = !_agreedToPrivacy;
                          setState(() => _agreedToPrivacy = newVal);
                          ref.read(agreedToPrivacyProvider.notifier).state = newVal;
                        },
                        child: Row(
                          children: [
                            SizedBox(
                              width: 24, height: 24,
                              child: Checkbox(
                                value: _agreedToPrivacy,
                                onChanged: (val) {
                                  final newVal = val ?? false;
                                  setState(() => _agreedToPrivacy = newVal);
                                  ref.read(agreedToPrivacyProvider.notifier).state = newVal;
                                },
                                activeColor: AppTheme.primaryColor,
                                side: const BorderSide(color: Colors.grey, width: 2), // explicitly visible border
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: RichText(
                                text: TextSpan(
                                  text: 'I agree to the ',
                                  style: GoogleFonts.inter(color: AppTheme.textSecondaryColor, fontSize: 13),
                                  children: [
                                    TextSpan(
                                      text: 'Privacy Policy',
                                      style: GoogleFonts.inter(color: AppTheme.primaryColor, fontWeight: FontWeight.bold, decoration: TextDecoration.underline),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Create Secure Account Button
                SizedBox(
                  width: double.infinity,
                  height: AppTheme.buttonHeight,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleRegister,
                    style: ElevatedButton.styleFrom(
                      disabledBackgroundColor:
                          AppTheme.primaryColor.withValues(alpha: 0.7),
                      elevation: 2,
                      shadowColor:
                          AppTheme.primaryColor.withValues(alpha: 0.3),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2),
                          )
                        : const Text('Create Secure Account'),
                  ),
                ),
                const SizedBox(height: 24),

                // OR Divider
                Row(
                  children: [
                    const Expanded(child: Divider(color: AppTheme.borderColor)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text('or sign in with', style: textTheme.bodySmall),
                    ),
                    const Expanded(child: Divider(color: AppTheme.borderColor)),
                  ],
                ),
                const SizedBox(height: 20),

                // --- SOCIAL LOGIN GRID ---
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
                      onTap: _isLoading ? null : () async {
                        final isConsented = ref.read(agreedToTermsProvider) && ref.read(agreedToPrivacyProvider);
                        if (!isConsented && (!_agreedToTerms || !_agreedToPrivacy)) {
                          _showAgreementWarning();
                          return;
                        }
                        final messenger = ScaffoldMessenger.of(context);
                        final navigator = Navigator.of(context);
                        setState(() => _isLoading = true);
                        try {
                          final authResult = await ref.read(authServiceProvider).signInWithGoogle(role: widget.initialRole);
                          if (authResult.user != null) {
                            ref.read(userRoleProvider.notifier).setRole(widget.initialRole);
                            setState(() => _isLoading = false);
                            navigator.pushReplacementNamed('/success', arguments: {
                              'role': widget.initialRole,
                              'isReturningUser': !authResult.isNewUser,
                            });
                          }
                        } catch (e) {
                          messenger.showSnackBar(SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))));
                        } finally {
                          if (mounted) setState(() => _isLoading = false);
                        }
                      },
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
                const SizedBox(height: 24),

                // Back to Login Link
                TextButton(
                  onPressed: () => Navigator.pushReplacementNamed(context, '/login', arguments: widget.initialRole),
                  child: RichText(
                    text: TextSpan(
                      text: 'Already have an account? ',
                      style: GoogleFonts.inter(color: AppTheme.textSecondaryColor),
                      children: [
                        TextSpan(
                          text: 'Sign In',
                          style: GoogleFonts.inter(
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                // DEBUG ONLY: Bypass registration for testing
                if (const bool.fromEnvironment('DEBUG', defaultValue: true))
                Center(
                  child: TextButton(
                    onPressed: () {
                      Navigator.pushReplacementNamed(context, '/success', arguments: {
                        'role': widget.initialRole,
                        'isReturningUser': false,
                      });
                    },
                    child: Text(
                      '(Debug) Bypass to Success Screen',
                      style: GoogleFonts.inter(
                        color: Colors.grey.withValues(alpha: 0.5),
                        fontSize: 12,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // HIPAA Footer
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.enhanced_encryption,
                        size: 16, color: AppTheme.textTertiaryColor),
                    const SizedBox(width: 8),
                    Flexible(
                      child: Text(
                        'HIPAA Compliant & Secure',
                        style: GoogleFonts.inter(
                          color: AppTheme.textTertiaryColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppTheme.pagePadding),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField(
    String label,
    IconData icon,
    TextEditingController controller, {
    TextInputType keyboardType = TextInputType.text,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      enabled: !_isLoading,
      decoration: InputDecoration(
        hintText: label,
        prefixIcon:
            Icon(icon, color: AppTheme.textTertiaryColor, size: 20),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter your $label';
        }
        return null;
      },
    );
  }


}
