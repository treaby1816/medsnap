import 'dart:io' show File;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../core/theme.dart';
import '../../../../widgets/glass_app_bar.dart';

import 'pharmacy_notifications_screen.dart';
import 'pharmacy_security_screen.dart';

import '../../../../core/providers.dart';
import '../../../../core/models/user_profile.dart';
import '../../../../widgets/hover_card.dart';

class PharmacyProfileScreen extends ConsumerWidget {
  const PharmacyProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userProfileAsync = ref.watch(userProfileProvider);
    
    return userProfileAsync.when(
      data: (profile) => _buildContent(context, ref, profile!),
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, s) => Scaffold(body: Center(child: Text('Error: $e'))),
    );
  }

  Widget _buildContent(BuildContext context, WidgetRef ref, UserProfile profile) {
    final displayName = profile.displayName ?? profile.email.split('@')[0];
    
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: GlassAppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppTheme.textPrimaryColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Profile',
          style: GoogleFonts.inter(
            color: AppTheme.textPrimaryColor,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        actions: [
          IconButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Theme is currently locked to Clinical Light Mode.'), behavior: SnackBarBehavior.floating),
              );
            },
            icon: const Icon(Icons.dark_mode_outlined, color: AppTheme.textPrimaryColor),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded, color: AppTheme.textSecondaryColor),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.pagePadding),
        child: Column(
          children: [
            // Profile Header
            Center(
              child: Column(
                children: [
                  Stack(
                    children: [
                      CircleAvatar(
                        radius: 50,
                        backgroundColor:
                            AppTheme.primaryColor.withValues(alpha: 0.1),
                        backgroundImage: profile.photoUrl != null 
                            ? NetworkImage(profile.photoUrl!) 
                            : null,
                        child: profile.photoUrl == null 
                            ? const Icon(Icons.person, size: 50, color: AppTheme.primaryColor)
                            : null,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    displayName,
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimaryColor,
                    ),
                  ),
                  Text(
                    'Chief Pharmacist',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: AppTheme.textSecondaryColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Account Settings
            _buildOptionGroup(
              title: 'Account Settings',
              items: [
                _buildProfileOption(
                  icon: Icons.person_outline,
                  title: 'Personal Information',
                  onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Account editing coming in the next update!')),
                  ),
                ),
                _buildProfileOption(
                  icon: Icons.notifications_none_rounded,
                  title: 'Notifications',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const PharmacyNotificationsScreen()),
                  ),
                ),
                _buildProfileOption(
                  icon: Icons.shield_outlined,
                  title: 'Security',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const PharmacySecurityScreen()),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Pharmacy Details
            _buildOptionGroup(
              title: 'Pharmacy Details',
              items: [
                _buildProfileOption(
                  icon: Icons.storefront_outlined,
                  title: 'Pharmacy Name',
                  onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Pharmacy information can be updated via Support.')),
                  ),
                ),
                _ImageUploadTile(
                  title: 'Store Front Image',
                  initialImageUrl: profile.storeFrontImageUrl,
                  storagePath: 'store_fronts',
                  fieldName: 'storeFrontImageUrl',
                ),
                _ImageUploadTile(
                  title: 'Store Inside Image',
                  initialImageUrl: profile.storeInsideImageUrl,
                  storagePath: 'store_insides',
                  fieldName: 'storeInsideImageUrl',
                ),
                _buildProfileOption(
                  icon: Icons.inventory_2_outlined,
                  title: 'Inventory Settings',
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Inventory threshold settings are centralized in the Admin Portal.'), behavior: SnackBarBehavior.floating),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 32),

            // Logout Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () async {
                  await ref.read(authServiceProvider).signOut();
                  if (context.mounted) {
                    Navigator.of(context).pushNamedAndRemoveUntil(
                      '/gateway',
                      (route) => false,
                    );
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor:
                      const Color(0xFFEF4444).withValues(alpha: 0.1),
                  foregroundColor: const Color(0xFFEF4444),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(AppTheme.buttonRadius),
                  ),
                ),
                child: Text('Log Out',
                    style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionGroup(
      {required String title, required List<Widget> items}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: AppTheme.textSecondaryColor,
              letterSpacing: 0.5,
            ),
          ),
        ),
        HoverCard(
          padding: EdgeInsets.zero,
          liftAmount: -10,
          scaleAmount: 1.01,
          borderRadius: BorderRadius.circular(AppTheme.cardRadius),
          child: Column(children: items),
        ),
      ],
    );
  }

  Widget _buildProfileOption({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      onTap: onTap,
      leading: Icon(icon, color: AppTheme.textSecondaryColor),
      title: Text(
        title,
        style: GoogleFonts.inter(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: AppTheme.textPrimaryColor,
        ),
      ),
      trailing: const Icon(Icons.chevron_right,
          color: AppTheme.textTertiaryColor, size: 20),
    );
  }
}

class _ImageUploadTile extends ConsumerStatefulWidget {
  final String title;
  final String? initialImageUrl;
  final String storagePath;
  final String fieldName;

  const _ImageUploadTile({
    required this.title,
    this.initialImageUrl,
    required this.storagePath,
    required this.fieldName,
  });

  @override
  ConsumerState<_ImageUploadTile> createState() => _ImageUploadTileState();
}

class _ImageUploadTileState extends ConsumerState<_ImageUploadTile> {
  bool _isUploading = false;
  final ImagePicker _picker = ImagePicker();

  Future<void> _pickAndUpload() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 70);
    if (image == null) return;

    if (!mounted) return;
    setState(() => _isUploading = true);

    try {
      final user = ref.read(authProvider);
      if (user == null) throw Exception('User not logged in');

      final path = '${widget.storagePath}/${user.id}.jpg';
      if (kIsWeb) {
        final bytes = await image.readAsBytes();
        await Supabase.instance.client.storage.from('pharmacy_images').uploadBinary(path, bytes, fileOptions: const FileOptions(upsert: true));
      } else {
        await Supabase.instance.client.storage.from('pharmacy_images').upload(path, File(image.path), fileOptions: const FileOptions(upsert: true));
      }
      final url = Supabase.instance.client.storage.from('pharmacy_images').getPublicUrl(path);

      await ref.read(authServiceProvider).updateProfile(user.id, {
        widget.fieldName: url,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Image uploaded successfully')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error uploading image: $e')));
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppTheme.primaryColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: const Icon(Icons.image_outlined, color: AppTheme.primaryColor, size: 20),
      ),
      title: Text(
        widget.title,
        style: GoogleFonts.inter(
          fontSize: 15,
          fontWeight: FontWeight.w500,
          color: AppTheme.textPrimaryColor,
        ),
      ),
      subtitle: widget.initialImageUrl != null 
          ? Text('Image uploaded', style: GoogleFonts.inter(color: Colors.green, fontSize: 12)) 
          : Text('No image uploaded yet', style: GoogleFonts.inter(color: AppTheme.textTertiaryColor, fontSize: 12)),
      trailing: _isUploading 
        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
        : IconButton(
            icon: const Icon(Icons.upload_rounded, color: AppTheme.primaryColor),
            onPressed: _pickAndUpload,
          ),
    );
  }
}
