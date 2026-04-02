import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:io';
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
  final _storeNameController = TextEditingController();
  final _licenseController = TextEditingController();
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
    _storeNameController.dispose();
    _licenseController.dispose();
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
                Text('Pharmacy / Store Name', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: AppTheme.textPrimaryColor)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _storeNameController,
                  decoration: const InputDecoration(hintText: 'Enter pharmacy name'),
                  validator: (v) => (v == null || v.isEmpty) ? 'Store name is required' : null,
                ),
                const SizedBox(height: 24),
                Text('License or NPI Number', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: AppTheme.textPrimaryColor)),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _licenseController,
                  decoration: const InputDecoration(hintText: 'Enter pharmacy license/NPI number'),
                  validator: (v) => (v == null || v.isEmpty) ? 'License is required' : null,
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
                    child: _licenseImage != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.file(File(_licenseImage!.path), fit: BoxFit.cover, width: double.infinity),
                          )
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.add_a_photo_outlined, color: AppTheme.primaryColor, size: 32),
                              const SizedBox(height: 8),
                              Text('Tap to upload license photo', style: GoogleFonts.inter(fontSize: 14, color: AppTheme.textSecondaryColor)),
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
                    minimumSize: const Size(double.infinity, 56),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text(
                          'Submit for Approval',
                          style: GoogleFonts.inter(
                              fontSize: 16, fontWeight: FontWeight.bold),
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
      final ref = FirebaseStorage.instance.ref().child('license_photos').child('$uid.jpg');
      await ref.putFile(File(_licenseImage!.path));
      return await ref.getDownloadURL();
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

    final storeName = _storeNameController.text.trim();
    final license = _licenseController.text.trim();
    final token = _tokenControllers.map((c) => c.text).join();

    if (token.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a 6-digit security access code.')),
      );
      return;
    }

    final user = ref.read(authProvider);
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('User session not found. Please log in again.')),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      String? photoUrl;
      if (_licenseImage != null) {
        photoUrl = await _uploadImage(user.uid);
      }

      await ref.read(authServiceProvider).submitVerificationRequest(
            user.uid,
            license,
            token,
            storeName: storeName,
            npiNumber: license,
            licensePhotoUrl: photoUrl,
          );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Verification submitted!')),
      );
      
      ref.invalidate(userProfileProvider);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _debugAdminApprove() async {
    final user = ref.read(authProvider);
    if (user == null) return;

    setState(() => _isLoading = true);
    try {
      await ref.read(authServiceProvider).adminApprovePharmacy(user.uid);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('DEBUG: Approved!')),
      );
      ref.invalidate(userProfileProvider);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Widget _buildPendingUI() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.timer_outlined, size: 64, color: AppTheme.primaryColor),
          ),
          const SizedBox(height: 32),
          Text(
            'Review in Progress',
            style: GoogleFonts.inter(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: const Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 40),
            child: Text(
              'Our compliance team is verifying your license and NPI number. This usually takes 24-48 hours.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 15,
                color: AppTheme.textSecondaryColor,
                height: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 48),
          TextButton(
            onPressed: _debugAdminApprove,
            child: Text(
              'FORCE APPROVAL (DEBUG)',
              style: GoogleFonts.inter(
                color: Colors.red,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
