import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme.dart';
import '../../../../core/constants/enums.dart';
import '../../../../widgets/glass_app_bar.dart';
import '../../../../core/providers.dart';
import '../../../auth/presentation/screens/success_screen.dart';

class PharmacyVerificationScreen extends ConsumerStatefulWidget {
  const PharmacyVerificationScreen({super.key});

  @override
  ConsumerState<PharmacyVerificationScreen> createState() =>
      _PharmacyVerificationScreenState();
}

class _PharmacyVerificationScreenState
    extends ConsumerState<PharmacyVerificationScreen> {
  final _licenseController = TextEditingController();
  final _emailController = TextEditingController();
  final List<TextEditingController> _tokenControllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _tokenFocusNodes =
      List.generate(6, (_) => FocusNode());
  bool _isLoading = false;

  @override
  void dispose() {
    _licenseController.dispose();
    _emailController.dispose();
    for (var c in _tokenControllers) { c.dispose(); }
    for (var f in _tokenFocusNodes) { f.dispose(); }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: GlassAppBar(
        title: Text('Pharmacy Verification',
          style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600, color: AppTheme.textPrimaryColor)),
      ),
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.pagePadding, vertical: 20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),
              Text('Registered Email Address', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: AppTheme.textPrimaryColor)),
              const SizedBox(height: 8),
              TextFormField(controller: _emailController, decoration: const InputDecoration(hintText: 'Enter pharmacy email')),
              const SizedBox(height: 24),
              Text('License Number', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: AppTheme.textPrimaryColor)),
              const SizedBox(height: 8),
              TextFormField(controller: _licenseController, decoration: const InputDecoration(hintText: 'Enter pharmacy license number')),
              const SizedBox(height: 32),
              Text('Security Access Code', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: AppTheme.textPrimaryColor)),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: List.generate(6, (i) => SizedBox(
                  width: 48, height: 56,
                  child: TextField(
                    controller: _tokenControllers[i], focusNode: _tokenFocusNodes[i],
                    textAlign: TextAlign.center, keyboardType: TextInputType.number, maxLength: 1,
                    style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 20, color: AppTheme.textPrimaryColor),
                    decoration: const InputDecoration(counterText: '', contentPadding: EdgeInsets.symmetric(vertical: 12)),
                    onChanged: (v) {
                      if (v.isNotEmpty && i < 5) {
                        _tokenFocusNodes[i + 1].requestFocus();
                      } else if (v.isEmpty && i > 0) {
                        _tokenFocusNodes[i - 1].requestFocus();
                      }
                    },
                  ),
                )),
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: _isLoading ? null : _handleVerify,
                child: _isLoading
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text('Verify & Access Dashboard', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _handleVerify() async {
    final email = _emailController.text.trim();
    final license = _licenseController.text.trim();
    final token = _tokenControllers.map((c) => c.text).join();

    if (email.isEmpty || license.isEmpty || token.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields and enter a 6-digit token.')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final user = ref.read(authProvider);
      if (user != null) {
        // Actual verification logic with Firestore
        await ref.read(authServiceProvider).updateVerificationStatus(
          user.uid,
          license,
          token,
        );
        
        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => const SuccessScreen(userType: UserType.pharmacy),
            ),
          );
        }
      } else {
        throw Exception('User session not found. Please sign in again.');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Verification failed: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}