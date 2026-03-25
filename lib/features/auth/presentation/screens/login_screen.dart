import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vail_meds_v2/core/theme.dart';
import 'package:vail_meds_v2/core/constants/enums.dart';
import 'package:vail_meds_v2/core/providers.dart';
import 'package:vail_meds_v2/core/providers/loading_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscureText = true;

  /// Handles standard Email and Password login
  Future<void> _handleLogin(UserType role) async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      _showErrorSnackBar('Please enter email and password');
      return;
    }

    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    HapticFeedback.lightImpact();
    ref.read(loadingProvider.notifier).show();

    try {
      final authService = ref.read(authServiceProvider);
      
      // Sequential Transaction: Await Auth result fully
      final authResult = await authService.signInWithEmail(email, password);

      if (authResult.user != null) {
        // Explicitly await the Firestore profile sync
        final profile = await authService.getUserProfile(authResult.user!.uid);
        
        if (profile != null) {
          final selectedRoleStr = role == UserType.patient ? 'patient' : 'pharmacy';
          
          if (profile.role != selectedRoleStr) {
            await authService.signOut();
            throw Exception('This account is a ${profile.role}, not a $selectedRoleStr.');
          }

          ref.read(userRoleProvider.notifier).setRole(profile.role);
          
          if (profile.role == 'pharmacy' && !profile.isVerified) {
            navigator.pushReplacementNamed('/pharmacy-verification');
          } else {
              // FIXED: Ensure proper dashboard redirection using valid AppRouter routes
              final route = profile.role == 'pharmacy' ? '/pharmacy-dashboard' : '/main';
              navigator.pushNamedAndRemoveUntil(route, (r) => false);
          }
        } else {
          await authService.signOut();
          throw Exception('User profile not found. Please register first.');
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
      if (mounted) ref.read(loadingProvider.notifier).hide();
    }
  }

  /// Handles the Google Sign-In process
  Future<void> _handleGoogleSignIn() async {
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);
    HapticFeedback.mediumImpact();
    ref.read(loadingProvider.notifier).show();
    
    try {
      final authService = ref.read(authServiceProvider);
      // Sequential Transaction: Await Google Auth and Firestore sync inside Service
      final authResult = await authService.signInWithGoogle();
      
      if (authResult.user != null) {
        if (authResult.isNewUser) {
          navigator.pushReplacementNamed('/success', arguments: 'patient');
        } else {
          // FIXED: Redirect existing Google users to correct patient dashboard route
          navigator.pushNamedAndRemoveUntil('/main', (r) => false);
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
      if (mounted) ref.read(loadingProvider.notifier).hide();
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.redAccent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = ref.watch(loadingProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF8F6F6),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),
                Center(
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.local_hospital_rounded,
                      size: 40,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  'Welcome Back',
                  style: GoogleFonts.inter(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF0F172A),
                    letterSpacing: -0.5,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'Sign in to your VailMeds account',
                  style: GoogleFonts.inter(
                    fontSize: 16,
                    color: AppTheme.textSecondaryColor,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),

                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryColor.withValues(alpha: 0.05),
                        blurRadius: 20,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel('Email Address'),
                      const SizedBox(height: 8),
                      _buildTextField(
                        controller: _emailController,
                        hint: 'Enter your email',
                        icon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        enabled: !isLoading,
                      ),
                      const SizedBox(height: 20),
                      _buildLabel('Password'),
                      const SizedBox(height: 8),
                      _buildTextField(
                        controller: _passwordController,
                        hint: 'Enter your password',
                        icon: Icons.lock_outline,
                        isPassword: true,
                        obscureText: _obscureText,
                        enabled: !isLoading,
                        onSuffixTap: () => setState(() => _obscureText = !_obscureText),
                      ),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton(
                          onPressed: isLoading ? null : () {},
                          child: Text(
                            'Forgot Password?',
                            style: GoogleFonts.inter(
                              color: AppTheme.primaryColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                      _buildButton(
                        text: 'Sign In as Patient',
                        isPrimary: true,
                        isLoading: isLoading,
                        onPressed: () => _handleLogin(UserType.patient),
                      ),
                      const SizedBox(height: 16),
                      _buildGoogleButton(isLoading: isLoading),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                
                Center(
                  child: TextButton(
                    onPressed: isLoading ? null : () => _handleLogin(UserType.pharmacy),
                    child: Text(
                      'Sign In as Pharmacy Executive',
                      style: GoogleFonts.inter(
                        color: const Color(0xFF64748B),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Don't have an account? ",
                      style: GoogleFonts.inter(color: Colors.grey[600]),
                    ),
                    TextButton(
                      onPressed: isLoading ? null : () => Navigator.pushNamed(context, '/register'),
                      child: const Text(
                        'Create Account',
                        style: TextStyle(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.inter(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: const Color(0xFF0F172A),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool isPassword = false,
    bool obscureText = false,
    bool enabled = true,
    TextInputType? keyboardType,
    VoidCallback? onSuffixTap,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      enabled: enabled,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.inter(color: Colors.grey.shade400),
        filled: true,
        fillColor: const Color(0xFFF8F9FA),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppTheme.primaryColor, width: 1.5),
        ),
        prefixIcon: Icon(icon, color: Colors.grey),
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  obscureText ? Icons.visibility_off : Icons.visibility,
                  color: Colors.grey,
                ),
                onPressed: onSuffixTap,
              )
            : null,
      ),
    );
  }

  Widget _buildButton({required String text, required VoidCallback onPressed, bool isPrimary = true, bool isLoading = false}) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: isPrimary ? AppTheme.primaryColor : Colors.white,
          foregroundColor: isPrimary ? Colors.white : const Color(0xFF1E293B),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: isPrimary ? BorderSide.none : const BorderSide(color: Color(0xFFE2E8F0)),
          ),
        ),
        child: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                // Local spinner removed in favor of Global Overlay, 
                // but kept disabled state for button consistency.
                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
              )
            : Text(
                text,
                style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700),
              ),
      ),
    );
  }

  Widget _buildGoogleButton({bool isLoading = false}) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: OutlinedButton(
        onPressed: isLoading ? null : _handleGoogleSignIn,
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Color(0xFFE2E8F0), width: 1.5),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.g_mobiledata, size: 30, color: Colors.red), 
            const SizedBox(width: 8),
            Text(
              'Continue with Google',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1E293B),
              ),
            ),
          ],
        ),
      ),
    );
  }
}