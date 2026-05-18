import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vail_meds_v2/core/theme.dart';
import 'package:vail_meds_v2/core/constants/enums.dart';
import 'package:vail_meds_v2/core/providers.dart';
import 'package:vail_meds_v2/core/providers/loading_provider.dart';
import 'package:vail_meds_v2/core/widgets/responsive_wrapper.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscureText = true;
  int _tapCount = 0;
  DateTime _lastTapTime = DateTime.now();
  bool _isShortcutChecked = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isShortcutChecked) {
      _isShortcutChecked = true;
      final args = ModalRoute.of(context)?.settings.arguments;
      if (args is Map && args['isAdminShortcut'] == true) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _showAuditorGate();
        });
      }
    }
  }

  void _handleVersionTap() {
    final profile = ref.read(userProfileProvider).value;
    if (profile != null && profile.isAdminApproved) return;

    final now = DateTime.now();
    if (now.difference(_lastTapTime).inSeconds > 2) {
      _tapCount = 1;
    } else {
      _tapCount++;
    }
    _lastTapTime = now;

    if (_tapCount >= 5) {
      _tapCount = 0;
      HapticFeedback.vibrate();
      _showAuditorGate();
    }
  }

  void _showAuditorGate() {
    final pinController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.shield_outlined, color: Color(0xFFEC5B13)),
            const SizedBox(width: 12),
            Text(
              'Admin Bypass',
              style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: const Color(0xFF0F172A)),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Enter the master access token to bypass standard authentication and enter the Admin Dashboard.',
              style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textSecondaryColor),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: pinController,
              obscureText: true,
              decoration: InputDecoration(
                hintText: 'Enter Token',
                prefixIcon: const Icon(Icons.vpn_key_outlined, size: 18),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFEC5B13), width: 2),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppTheme.borderColor),
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              style: GoogleFonts.inter(fontWeight: FontWeight.bold, letterSpacing: 4),
              autofocus: true,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: Text('CANCEL', style: GoogleFonts.inter(color: Colors.grey, fontWeight: FontWeight.bold)),
          ),
          ElevatedButton(
            onPressed: () async {
              final inputCode = pinController.text.trim();
              if (inputCode.isEmpty) return;
              
              // 1. Capture services before the async gap to satisfy the linter
              final navigator = Navigator.of(context);
              final messenger = ScaffoldMessenger.of(context);
              
              // 2. Fetch Dynamic Key from Firestore
              final authService = ref.read(authServiceProvider);
              final masterKey = await authService.getAdminMasterKey();

              // 3. Direct Verification
              if (masterKey != null && inputCode.trim() == masterKey.trim()) {
                // 2. Set Admin Role in Session
                ref.read(userRoleProvider.notifier).setRole('admin');
                
                // 3. Immediate Direct Navigation (With Mount Check)
                if (!mounted) return;
                
                navigator.pop(); // Close dialog
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text('Access Granted. Routing to Admin Center...'),
                    backgroundColor: Color(0xFFEC5B13),
                    behavior: SnackBarBehavior.floating,
                  ),
                );
                navigator.pushNamedAndRemoveUntil('/admin-dashboard', (route) => false);
              } else {
                HapticFeedback.heavyImpact();
                if (!mounted) return;
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text('Invalid Master Token or Connection Error.'),
                    backgroundColor: Colors.redAccent,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEC5B13),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text('LAUNCH ADMIN', style: GoogleFonts.inter(fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }

  Future<void> _handleLogin(UserType role) async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    if (email.isEmpty || password.isEmpty) {
      _showErrorSnackBar('Please enter email and password');
      return;
    }
    ref.read(loadingProvider.notifier).show();
    try {
      final authResult = await ref.read(authServiceProvider).signInWithEmail(email, password);
      if (authResult.user != null) {
        final profile = await ref.read(authServiceProvider).getUserProfile(authResult.user!.id);
        if (profile != null) {
          final targetRole = role == UserType.pharmacy ? 'pharmacy' : 'patient';
          if (profile.role != targetRole) {
            await ref.read(authServiceProvider).signOut();
            throw Exception('Account Role Mismatch. Please use the ${profile.role} portal.');
          }
          ref.read(userRoleProvider.notifier).setRole(profile.role);
          if (mounted) {
            // Route through Success screen which handles per-role navigation
            Navigator.pushNamedAndRemoveUntil(context, '/success', (_) => false, arguments: {
              'role': profile.role,
              'isReturningUser': true,
            });
          }
        }
      }
    } catch (e) {
      _showErrorSnackBar(e.toString().replaceAll('Exception: ', ''));
    } finally {
      ref.read(loadingProvider.notifier).hide();
    }
  }

  Future<void> _handleGoogleSignIn() async {
    // 1. Capture route arguments early (before async gaps)
    final args = ModalRoute.of(context)?.settings.arguments;
    final targetRole = (args == 'pharmacy' || (args is Map && args['role'] == 'pharmacy')) ? 'pharmacy' : 'patient';

    ref.read(loadingProvider.notifier).show();
    try {
      final authResult = await ref.read(authServiceProvider).signInWithGoogle();
      if (authResult.user != null) {
        final profile = await ref.read(authServiceProvider).getUserProfile(authResult.user!.id);
        
        if (profile != null && profile.role != targetRole) {
          await ref.read(authServiceProvider).signOut();
          throw Exception('Google Account Mismatch. Use the ${profile.role} portal.');
        }
        
        if (!mounted) return;
        Navigator.pushReplacementNamed(context, '/success', arguments: {
          'role': targetRole,
          'isReturningUser': !authResult.isNewUser,
        });
      }
    } catch (e) {
      _showErrorSnackBar(e.toString().replaceAll('Exception: ', ''));
    } finally {
      ref.read(loadingProvider.notifier).hide();
    }
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(message),
      backgroundColor: Colors.redAccent,
      behavior: SnackBarBehavior.floating,
    ));
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bool currentLoading = ref.watch(loadingProvider);
    final args = ModalRoute.of(context)?.settings.arguments;
    final String roleArg = (args == 'pharmacy' || (args is Map && args['role'] == 'pharmacy')) ? 'pharmacy' : 'patient';

    return VailMedsScaffold(
      showAppBar: true,
      title: '', // Empty title
      leading: IconButton(
        icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppTheme.textPrimaryColor, size: 20),
        onPressed: () {
          if (Navigator.of(context).canPop()) {
            Navigator.of(context).pop();
          } else {
            Navigator.of(context).pushReplacementNamed('/gateway');
          }
        },
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const SizedBox(height: 20),
            Center(
              child: Container(
                width: 80, height: 80,
                decoration: const BoxDecoration(
                  color: Color(0xFFEC5B13), 
                  shape: BoxShape.circle,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12.0), 
                  child: Image.asset('assets/images/logo2.png', fit: BoxFit.contain),
                ),
              ),
            ),
            const SizedBox(height: 32),
            Text(
              roleArg == 'pharmacy' ? 'Pharmacy Portal' : 'Welcome Back',
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
              roleArg == 'pharmacy' ? 'Admin Access & Order Management' : 'Sign in to your VailMeds account',
              style: GoogleFonts.inter(fontSize: 16, color: AppTheme.textSecondaryColor),
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
                    enabled: !currentLoading,
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
                    enabled: !currentLoading,
                    onSuffixTap: () => setState(() => _obscureText = !_obscureText),
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: currentLoading ? null : () {},
                      child: Text(
                        'Forgot Password?', 
                        style: GoogleFonts.inter(color: AppTheme.primaryColor, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildButton(
                    text: roleArg == 'pharmacy' ? 'Sign In as Pharmacy' : 'Sign In as Patient',
                    isPrimary: true, 
                    isLoading: currentLoading,
                    onPressed: () => _handleLogin(roleArg == 'pharmacy' ? UserType.pharmacy : UserType.patient),
                  ),
                  if (roleArg != 'pharmacy') ...[
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        _buildSquareSocialBtn(
                          iconWidget: const Text(
                            'G', 
                            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: Color(0xFF4285F4)),
                          ),
                          label: 'Google', 
                          onTap: currentLoading ? null : _handleGoogleSignIn,
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
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),
            Center(
              child: Column(
                children: [
                  if (roleArg == 'pharmacy')
                    TextButton(
                      onPressed: currentLoading ? null : () => Navigator.pushNamed(context, '/registration', arguments: 'pharmacy'),
                      child: Text(
                        'Register as Pharmacy Executive', 
                        style: GoogleFonts.inter(color: AppTheme.primaryColor, fontSize: 15, fontWeight: FontWeight.bold),
                      ),
                    )
                  else ...[
                    TextButton(
                      onPressed: currentLoading ? null : () => _handleLogin(UserType.pharmacy),
                      child: Text(
                        'Sign In as Pharmacy Executive', 
                        style: GoogleFonts.inter(color: const Color(0xFF64748B), fontWeight: FontWeight.w600),
                      ),
                    ),
                    TextButton(
                      onPressed: currentLoading ? null : () => Navigator.pushNamed(context, '/registration', arguments: 'pharmacy'),
                      child: Text(
                        'Register as Pharmacy Executive', 
                        style: GoogleFonts.inter(color: AppTheme.primaryColor, fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              alignment: WrapAlignment.center, 
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Text("Patient? ", style: GoogleFonts.inter(color: Colors.grey[600])),
                TextButton(
                  onPressed: currentLoading ? null : () => Navigator.pushNamed(context, '/registration', arguments: 'patient'),
                  child: const Text(
                    'Create Account', 
                    style: TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            Center(
              child: GestureDetector(
                onTap: _handleVersionTap,
                child: Text(
                  'v2.0.1+${DateTime.now().year}', 
                  style: GoogleFonts.inter(fontSize: 12, color: Colors.grey[400], fontWeight: FontWeight.w600),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text, 
      style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: const Color(0xFF0F172A)),
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
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12), 
          borderSide: const BorderSide(color: AppTheme.primaryColor, width: 1.5),
        ),
        prefixIcon: Icon(icon, color: Colors.grey),
        suffixIcon: isPassword 
            ? IconButton(
                icon: Icon(obscureText ? Icons.visibility_off : Icons.visibility, color: Colors.grey), 
                onPressed: onSuffixTap,
              ) 
            : null,
      ),
    );
  }

  Widget _buildButton({
    required String text, 
    required VoidCallback onPressed, 
    bool isPrimary = true, 
    bool isLoading = false,
  }) {
    return SizedBox(
      width: double.infinity, height: 56,
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
            ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : Text(text, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700)),
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
            width: 100, height: 90,
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
            top: -8, right: -8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(color: const Color(0xFFEAB308), borderRadius: BorderRadius.circular(12)),
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
