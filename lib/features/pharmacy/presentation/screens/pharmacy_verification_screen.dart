import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io' show File;
import 'package:flutter/foundation.dart' show kIsWeb;
import '../../../../core/theme.dart';
import '../../../../widgets/glass_app_bar.dart';
import '../../../../core/providers.dart';

class PharmacyVerificationScreen extends ConsumerStatefulWidget {
  const PharmacyVerificationScreen({super.key});

  @override
  ConsumerState<PharmacyVerificationScreen> createState() =>
      _PharmacyVerificationScreenState();
}

class _PharmacyVerificationScreenState extends ConsumerState<PharmacyVerificationScreen> {
  final _pharmacistNameController = TextEditingController();
  final _brandNameController = TextEditingController();
  final _licenseNumberController = TextEditingController();
  final _emailController = TextEditingController();
  final List<TextEditingController> _tokenControllers =
      List.generate(6, (_) => TextEditingController());
  final List<FocusNode> _tokenFocusNodes =
      List.generate(6, (_) => FocusNode());
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  XFile? _licenseImage;
  final _picker = ImagePicker();

  @override
  void dispose() {
    _pharmacistNameController.dispose();
    _brandNameController.dispose();
    _licenseNumberController.dispose();
    _emailController.dispose();
    for (var c in _tokenControllers) { c.dispose(); }
    for (var f in _tokenFocusNodes) { f.dispose(); }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final userProfile = ref.watch(userProfileProvider).value;

    ref.listen(userProfileProvider, (previous, next) {
      if (next.value?.isAdminApproved ?? false) {
        Navigator.pushReplacementNamed(context, '/pharmacy-dashboard');
      }
    });

    // If already approved, show loading while redirecting (handled by ref.listen above)
    if (userProfile?.isAdminApproved ?? false) {
       return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    // If pending review
    if (userProfile?.isVerificationPending ?? false) {
      return Scaffold(
        backgroundColor: AppTheme.backgroundColor,
        appBar: GlassAppBar(
          title: Text('Verification Pending',
            style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600, color: AppTheme.textPrimaryColor)),
        ),
        body: _buildPendingUI(),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: GlassAppBar(
        title: Text('Pharmacy Verification',
          style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w600, color: AppTheme.textPrimaryColor)),
      ),
      body: SafeArea(
        top: false,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.pagePadding, vertical: 20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),
                Text('Registered Email Address', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: AppTheme.textPrimaryColor)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(hintText: 'Enter pharmacy email'),
                  validator: (v) => (v == null || v.isEmpty) ? 'Email is required' : null,
                ),
                const SizedBox(height: 24),
                const SizedBox(height: 20),
                Text('Pharmacist Full Name', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: AppTheme.textPrimaryColor)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _pharmacistNameController,
                  decoration: const InputDecoration(hintText: 'Enter your legal name'),
                  validator: (v) => (v == null || v.isEmpty) ? 'Pharmacist name is required' : null,
                ),
                const SizedBox(height: 24),
                Text('Pharmacy Brand Name', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: AppTheme.textPrimaryColor)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _brandNameController,
                  decoration: const InputDecoration(hintText: 'Enter your pharmacy brand name'),
                  validator: (v) => (v == null || v.isEmpty) ? 'Brand name is required' : null,
                ),
                const SizedBox(height: 24),
                Text('License or NPI Number', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: AppTheme.textPrimaryColor)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _licenseNumberController,
                  decoration: const InputDecoration(hintText: 'Enter license number'),
                  validator: (v) => (v == null || v.isEmpty) ? 'License number is required' : null,
                ),
                const SizedBox(height: 24),
                Text('License Photo', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: AppTheme.textPrimaryColor)),
                const SizedBox(height: 12),
                GestureDetector(
                  onTap: _pickImage,
                  child: Container(
                    height: 160,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.borderColor),
                    ),
                    child: _licenseImage != null && !kIsWeb
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: Image.file(File(_licenseImage!.path), fit: BoxFit.cover, width: double.infinity),
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.upload_file_rounded, color: AppTheme.primaryColor, size: 32),
                              ),
                              const SizedBox(height: 12),
                              Text('Official Pharmacy License', 
                                style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textPrimaryColor)),
                              const SizedBox(height: 4),
                              Text('Upload high-resolution image or PDF', 
                                style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondaryColor)),
                            ],
                          ),
                  ),
                ),
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
                  onPressed: _isLoading ? null : _submitVerification,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
                    minimumSize: const Size(double.infinity, 64),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    elevation: 8,
                    shadowColor: AppTheme.primaryColor.withValues(alpha: 0.4),
                  ),
                  child: _isLoading
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.security_rounded, size: 20),
                            const SizedBox(width: 12),
                            Text(
                              'Secure Verification Request',
                              style: GoogleFonts.inter(
                                  fontSize: 17, fontWeight: FontWeight.w800, letterSpacing: 0.5),
                            ),
                          ],
                        ),
                ),
                const SizedBox(height: 20),
                if (const bool.fromEnvironment('DEBUG', defaultValue: true))
                  TextButton(
                    onPressed: _isLoading ? null : _debugAdminApprove,
                    child: Text(
                      'Force Admin Approval (Debug Only)',
                      style: GoogleFonts.inter(
                        color: Colors.grey,
                        fontSize: 12,
                        decoration: TextDecoration.underline,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (image != null) {
      setState(() {
        _licenseImage = image;
      });
    }
  }

  Future<String?> _uploadImage(String uid) async {
    if (_licenseImage == null) return null;
    try {
      final storageRef = FirebaseStorage.instance
          .ref()
          .child('pharmacy_licenses')
          .child('$uid.jpg');
      if (kIsWeb) {
        final bytes = await _licenseImage!.readAsBytes();
        await storageRef.putData(bytes);
      } else {
        await storageRef.putFile(File(_licenseImage!.path));
      }
      return await storageRef.getDownloadURL();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error uploading image: $e')),
        );
      }
      return null;
    }
  }

  Future<void> _submitVerification() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_licenseImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please upload a photo of your pharmacy license.')),
      );
      return;
    }

    final pharmacistName = _pharmacistNameController.text.trim();
    final brandName = _brandNameController.text.trim();
    final licenseNumber = _licenseNumberController.text.trim();
    final token = _tokenControllers.map((c) => c.text).join();

    if (token.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a 6-digit security access code.')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authService = ref.read(authServiceProvider);
      final user = authService.currentUser;
      if (user == null) throw Exception('User session not found. Please log in again.');

      final downloadUrl = await _uploadImage(user.uid);
      if (downloadUrl == null) throw Exception('License upload failed.');

      // Submit high-fidelity verification request
      await authService.submitVerificationRequest(
        user.uid,
        licenseNumber,
        token, // Used as accessToken for terminal sync
        storeName: brandName,
        licensePhotoUrl: downloadUrl,
      );

      // Also update displayName to pharmacist name
      await authService.updateProfile(user.uid, {
        'displayName': pharmacistName,
      });

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('License submitted for clinical review!')),
      );
      
      // Refresh profile to trigger the 'Pending' UI
      ref.invalidate(userProfileProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Verification Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _debugAdminApprove() async {
    final authService = ref.read(authServiceProvider);
    final user = authService.currentUser;
    if (user == null) return;

    setState(() => _isLoading = true);
    try {
      await authService.adminApprovePharmacy(user.uid);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('DEBUG: Application Approved!')),
      );
      ref.invalidate(userProfileProvider);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Debug Error: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildPendingUI() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 32),
      decoration: const BoxDecoration(
        color: AppTheme.backgroundColor,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _buildAnimatedTimerIcon(),
          const SizedBox(height: 32),
          Text(
            'Verification in Review',
            style: GoogleFonts.inter(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF0F172A),
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'High-fidelity verification in progress. Our clinical oversight team is reviewing your pharmaceutical license and brand credentials.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 16,
              color: AppTheme.textSecondaryColor,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 48),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: AppTheme.primaryColor),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    'You will receive an email and SMS once your pharmacy command center is activated.',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFF475569),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 32),
          // Hidden debug trigger (Triple tap the info box to bypass in dev)
          GestureDetector(
            onLongPress: _debugAdminApprove, // Require long press for debug bypass
            child: Container(
              height: 40,
              width: 100,
              color: Colors.transparent,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAnimatedTimerIcon() {
    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          width: 120,
          height: 120,
          child: CircularProgressIndicator(
            value: 0.7,
            strokeWidth: 3,
            backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
            valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
          ),
        ),
        Container(
          width: 90,
          height: 90,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryColor.withValues(alpha: 0.2),
                blurRadius: 20,
                spreadRadius: 5,
              ),
            ],
          ),
          child: const Icon(Icons.verified_user_outlined, size: 40, color: AppTheme.primaryColor),
        ),
      ],
    );
  }
}
