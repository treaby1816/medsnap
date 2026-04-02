import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme.dart';
import '../../../../core/constants/enums.dart';
import '../../../../widgets/glass_app_bar.dart';
import '../../../../core/providers.dart';
import 'success_screen.dart';

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

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
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
        final userType = role == 'pharmacy' ? UserType.pharmacy : UserType.patient;
        
        setState(() => _isLoading = false); // Hide loader before navigation
        
        navigator.pushReplacement(
          MaterialPageRoute(
            builder: (_) => SuccessScreen(userType: userType),
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      if (e.code == 'email-already-in-use') {
        _showExistingUserPrompt(messenger);
      } else {
        messenger.showSnackBar(
          SnackBar(content: Text('Registration failed: ${e.message ?? e.code}')),
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
        final profile = await authService.getUserProfile(authResult.user!.uid);
        if (profile != null) {
          ref.read(userRoleProvider.notifier).setRole(profile.role);
          final route = profile.role == 'pharmacy' ? '/pharmacy-dashboard' : '/main';
          
          setState(() => _isLoading = false); // Hide loader before navigation
          
          navigator.pushNamedAndRemoveUntil(route, (r) => false);
        }
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
          icon: const Icon(Icons.arrow_back,
              color: AppTheme.textPrimaryColor, size: 22),
          onPressed: () {
            ref.read(onboardingStageProvider.notifier).state = 'welcome';
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
                // Health Icon
                Center(
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.primaryColor.withValues(alpha: 0.1),
                      boxShadow: [
                        BoxShadow(
                          color:
                              AppTheme.primaryColor.withValues(alpha: 0.1),
                          blurRadius: 30,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.health_and_safety,
                      size: 40,
                      color: AppTheme.primaryColor,
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

                // Sign Up with Google (wired to AuthService)
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton.icon(
                    onPressed: _isLoading ? null : () async {
                      final messenger = ScaffoldMessenger.of(context);
                      final navigator = Navigator.of(context);
                      setState(() => _isLoading = true);
                      try {
                        final authResult = await ref.read(authServiceProvider).signInWithGoogle(role: widget.initialRole);
                        if (authResult.user != null) {
                          ref.read(userRoleProvider.notifier).setRole(widget.initialRole);
                          
                          setState(() => _isLoading = false); // Hide loader before navigation
                          
                          if (authResult.isNewUser) {
                            navigator.pushReplacementNamed('/success', arguments: widget.initialRole);
                          } else {
                            navigator.popUntil((route) => route.isFirst);
                          }
                        }
                      } catch (e) {
                        messenger.showSnackBar(
                          SnackBar(
                            content: Text(e.toString().replaceAll('Exception: ', '')),
                            backgroundColor: Colors.redAccent,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      } finally {
                        if (mounted) setState(() => _isLoading = false);
                      }
                    },
                    icon: const Text(
                      'G',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF4285F4),
                      ),
                    ),
                    label: Text(
                      'Sign Up with Google',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimaryColor,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // OR Divider
                Row(
                  children: [
                    const Expanded(
                      child: Divider(color: AppTheme.borderColor),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'or register with email',
                        style: textTheme.bodySmall,
                      ),
                    ),
                    const Expanded(
                      child: Divider(color: AppTheme.borderColor),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

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

                // HIPAA Footer
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.enhanced_encryption,
                        size: 16, color: AppTheme.textTertiaryColor),
                    const SizedBox(width: 8),
                    Text(
                      'HIPAA Compliant & Secure',
                      style: GoogleFonts.inter(
                        color: AppTheme.textTertiaryColor,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
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
