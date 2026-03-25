import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme.dart';
import '../../../../core/app_router.dart';
import '../../../../core/providers.dart';
import '../../../../core/models/user_profile.dart';
import 'dart:ui' as ui;

class PatientProfileScreen extends ConsumerWidget {
  const PatientProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userProfileAsync = ref.watch(userProfileProvider);
    final canPop = Navigator.of(context).canPop();

    return Scaffold(
      backgroundColor: const Color(0xFFF8F6F6),
      extendBodyBehindAppBar: true,
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(56.0),
        child: ClipRRect(
          child: BackdropFilter(
            filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: AppBar(
              backgroundColor: Colors.white.withValues(alpha: 0.8),
              elevation: 0,
              centerTitle: true,
              leading: canPop
                  ? IconButton(
                      icon: const Icon(Icons.arrow_back, color: AppTheme.primaryColor),
                      onPressed: () => Navigator.pop(context),
                    )
                  : const SizedBox(), 
              title: Text(
                'Profile',
                style: GoogleFonts.inter(
                  color: const Color(0xFF0F172A),
                  fontWeight: FontWeight.w700,
                  fontSize: 18,
                  letterSpacing: -0.5,
                ),
              ),
              actions: [
                IconButton(
                  icon: const Icon(Icons.settings, color: AppTheme.primaryColor),
                  onPressed: () => _showSettingsSheet(context, ref),
                ),
              ],
            ),
          ),
        ),
      ),
      body: userProfileAsync.when(
        data: (profile) => _buildProfileContent(context, ref, profile!),
        loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor)),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }

  void _showSettingsSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Settings', style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),
            ListTile(
              leading: const Icon(Icons.person_outline, color: AppTheme.primaryColor),
              title: const Text('Edit Profile'),
              trailing: const Icon(Icons.chevron_right, size: 20),
              onTap: () {
                Navigator.pop(context);
                _showEditProfileDialog(context, ref);
              },
            ),
            ListTile(
              leading: const Icon(Icons.notifications_outlined, color: AppTheme.primaryColor),
              title: const Text('Notifications'),
              trailing: const Icon(Icons.chevron_right, size: 20),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.help_outline, color: AppTheme.primaryColor),
              title: const Text('Help & Support'),
              trailing: const Icon(Icons.chevron_right, size: 20),
              onTap: () {
                Navigator.pop(context);
                Navigator.pushNamed(context, AppRouter.support);
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text('Sign Out', style: TextStyle(color: Colors.red)),
              onTap: () async {
                Navigator.pop(context);
                await ref.read(authServiceProvider).signOut();
                if (context.mounted) {
                  Navigator.of(context).pushNamedAndRemoveUntil(
                    AppRouter.welcome,
                    (route) => false,
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showEditProfileDialog(BuildContext context, WidgetRef ref) {
    final profile = ref.read(userProfileProvider).value;
    if (profile == null) return;

    final nameController = TextEditingController(text: profile.name);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Edit Profile', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                labelText: 'Full Name',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppTheme.primaryColor, width: 2),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
            ),
            onPressed: () async {
              final newName = nameController.text.trim();
              if (newName.isNotEmpty) {
                try {
                  await ref.read(authServiceProvider).updateProfile(
                    profile.uid,
                    {'name': newName},
                  );
                  ref.invalidate(userProfileProvider);
                  if (context.mounted) Navigator.pop(context);
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Failed to update profile')),
                    );
                  }
                }
              }
            },
            child: const Text('Save', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileContent(BuildContext context, WidgetRef ref, UserProfile profile) {
    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(top: 100.0, bottom: 120.0, left: 16.0, right: 16.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Profile Avatar
          Center(
            child: Stack(
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 4),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                    image: DecorationImage(
                      image: NetworkImage(profile.photoUrl ??
                          'https://ui-avatars.com/api/?name=${profile.displayName ?? profile.email}&background=random'),
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: GestureDetector(
                    onTap: () {
                      HapticFeedback.lightImpact();
                      _editProfile(context, ref, profile);
                    },
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 2),
                      ),
                      child: const Icon(Icons.edit, color: Colors.white, size: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            profile.displayName ?? profile.email.split('@')[0],
            style: GoogleFonts.inter(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF0F172A)),
          ),
          const SizedBox(height: 4),
          Text(
            profile.email,
            style: GoogleFonts.inter(fontSize: 14, color: const Color(0xFF64748B)),
          ),
          const SizedBox(height: 32),

          // Health Summary
          _buildHealthSummary(profile),
          const SizedBox(height: 32),

          // Health Records
          const _SectionHeader(title: 'Health Records'),
          _SectionGroup(
            children: [
              _ProfileSectionItem(
                icon: Icons.history_edu,
                title: 'Medical Records & History',
                onTap: () => _editHealthRecords(context, ref, profile),
              ),
              _ProfileSectionItem(
                icon: Icons.devices,
                title: 'Connected Devices',
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (profile.connectedDevices?.contains('apple_health') ?? false) const _DeviceIcon(iconText: 'ios'),
                    if (profile.connectedDevices?.contains('google_fit') ?? false) const _DeviceIcon(iconText: 'fit'),
                  ],
                ),
                onTap: () => _manageDevices(context, ref, profile),
              ),
              _ProfileSectionItem(
                icon: Icons.verified_user_outlined,
                title: 'Insurance Details',
                isLast: true,
                onTap: () => _editInsurance(context, ref, profile),
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Logout
          _buildLogoutButton(context, ref),
          const SizedBox(height: 32),
          Text('VAILMEDS CLINICAL V4.2.1', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: const Color(0xFF94A3B8), letterSpacing: 2.0)),
        ],
      ),
    );
  }

  Widget _buildHealthSummary(UserProfile profile) {
    final records = profile.healthRecords ?? {};
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('HEALTH SUMMARY', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: AppTheme.primaryColor, letterSpacing: 1.0)),
              Text('REAL-TIME SYNC', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: const Color(0xFF64748B))),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _HealthMetric(label: 'BLOOD TYPE', value: records['blood_type'] ?? 'N/A')),
              const SizedBox(width: 12),
              Expanded(child: _HealthMetric(label: 'HEIGHT', value: records['height'] ?? 'N/A')),
              const SizedBox(width: 12),
              Expanded(child: _HealthMetric(label: 'WEIGHT', value: records['weight'] ?? 'N/A', isWeight: true)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context, WidgetRef ref) {
    return SizedBox(
      width: double.infinity,
      child: TextButton.icon(
        onPressed: () async {
          await ref.read(authServiceProvider).signOut();
          if (context.mounted) Navigator.pushReplacementNamed(context, AppRouter.gateway);
        },
        icon: const Icon(Icons.logout, color: Colors.red),
        label: Text('Logout', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.red)),
        style: TextButton.styleFrom(
          backgroundColor: Colors.red.withValues(alpha: 0.05),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }

  // --- Handlers ---
  void _editProfile(BuildContext context, WidgetRef ref, UserProfile profile) {
    final nameController = TextEditingController(text: profile.displayName);
    final photoController = TextEditingController(text: profile.photoUrl);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Basic Profile'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Full Name')),
            const SizedBox(height: 12),
            TextField(
                controller: photoController,
                decoration: const InputDecoration(
                    labelText: 'Profile Photo URL',
                    hintText: 'Enter https://...')),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              await ref.read(authServiceProvider).updateProfile(profile.uid, {
                'displayName': nameController.text,
                'photoUrl': photoController.text,
              });
              ref.invalidate(userProfileProvider);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _editHealthRecords(BuildContext context, WidgetRef ref, UserProfile profile) {
    final bloodController = TextEditingController(text: profile.healthRecords?['blood_type']);
    final heightController = TextEditingController(text: profile.healthRecords?['height']);
    final weightController = TextEditingController(text: profile.healthRecords?['weight']);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit Health Records'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: bloodController, decoration: const InputDecoration(labelText: 'Blood Type')),
            TextField(controller: heightController, decoration: const InputDecoration(labelText: 'Height')),
            TextField(controller: weightController, decoration: const InputDecoration(labelText: 'Weight')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              await ref.read(authServiceProvider).updateProfile(profile.uid, {
                'healthRecords': {
                  'blood_type': bloodController.text,
                  'height': heightController.text,
                  'weight': weightController.text,
                }
              });
              ref.invalidate(userProfileProvider);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _editInsurance(BuildContext context, WidgetRef ref, UserProfile profile) {
    final providerController = TextEditingController(text: profile.insuranceProvider);
    final idController = TextEditingController(text: profile.insuranceID);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Insurance Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: providerController, decoration: const InputDecoration(labelText: 'Provider')),
            TextField(controller: idController, decoration: const InputDecoration(labelText: 'Insurance ID')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          TextButton(
            onPressed: () async {
              await ref.read(authServiceProvider).updateProfile(profile.uid, {
                'insuranceProvider': providerController.text,
                'insuranceID': idController.text,
              });
              ref.invalidate(userProfileProvider);
              if (context.mounted) Navigator.pop(context);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _manageDevices(BuildContext context, WidgetRef ref, UserProfile profile) {
    final currentDevices = profile.connectedDevices ?? [];
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Connected Devices'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SwitchListTile(
                title: const Text('Apple Health'),
                value: currentDevices.contains('apple_health'),
                onChanged: (val) async {
                  if (val) {
                    currentDevices.add('apple_health');
                  } else {
                    currentDevices.remove('apple_health');
                  }
                  await ref.read(authServiceProvider).updateProfile(profile.uid, {'connectedDevices': currentDevices});
                  ref.invalidate(userProfileProvider);
                  setState(() {});
                },
              ),
              SwitchListTile(
                title: const Text('Google Fit'),
                value: currentDevices.contains('google_fit'),
                onChanged: (val) async {
                  if (val) {
                    currentDevices.add('google_fit');
                  } else {
                    currentDevices.remove('google_fit');
                  }
                  await ref.read(authServiceProvider).updateProfile(profile.uid, {'connectedDevices': currentDevices});
                  ref.invalidate(userProfileProvider);
                  setState(() {});
                },
              ),
            ],
          ),
          actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text('Done'))],
        ),
      ),
    );
  }
}

// --- Internal Widgets ---
class _HealthMetric extends StatelessWidget {
  final String label, value;
  final bool isWeight;
  const _HealthMetric({required this.label, required this.value, this.isWeight = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: BoxDecoration(color: AppTheme.primaryColor.withValues(alpha: 0.05), borderRadius: BorderRadius.circular(8)),
      child: Column(
        children: [
          Text(label, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: const Color(0xFF64748B))),
          const SizedBox(height: 4),
          Text(value, style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.primaryColor)),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.only(left: 4, bottom: 12), child: Align(alignment: Alignment.centerLeft, child: Text(title.toUpperCase(), style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: const Color(0xFF94A3B8), letterSpacing: 1.0))));
}

class _SectionGroup extends StatelessWidget {
  final List<Widget> children;
  const _SectionGroup({required this.children});
  @override
  Widget build(BuildContext context) => Container(decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4))]), child: Column(mainAxisSize: MainAxisSize.min, children: children));
}

class _ProfileSectionItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final Widget? trailing;
  final bool isLast;
  final VoidCallback onTap;
  const _ProfileSectionItem({required this.icon, required this.title, this.trailing, this.isLast = false, required this.onTap});

  @override
  Widget build(BuildContext context) => InkWell(onTap: onTap, child: Container(padding: const EdgeInsets.all(16), decoration: BoxDecoration(border: isLast ? null : Border(bottom: BorderSide(color: Colors.grey.withValues(alpha: 0.1)))), child: Row(children: [Icon(icon, color: const Color(0xFF64748B), size: 22), const SizedBox(width: 12), Expanded(child: Text(title, style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: const Color(0xFF334155)))), if (trailing != null) trailing! else const Icon(Icons.chevron_right, color: Color(0xFF94A3B8), size: 20)])));
}

class _DeviceIcon extends StatelessWidget {
  final String iconText;
  const _DeviceIcon({required this.iconText});
  @override
  Widget build(BuildContext context) => Container(padding: const EdgeInsets.all(4), decoration: const BoxDecoration(color: Color(0xFFF1F5F9), shape: BoxShape.circle), child: Icon(iconText == 'fit' ? Icons.watch : Icons.apple, size: 12, color: const Color(0xFF0F172A)));
}
