import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme.dart';
import '../../../../core/providers.dart';
import '../../../../core/models/user_profile.dart';
import '../../../../widgets/glass_app_bar.dart';

class PendingApprovalsScreen extends ConsumerWidget {
  const PendingApprovalsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingAsync = ref.watch(pendingPharmaciesProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: GlassAppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppTheme.textPrimaryColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Pending Approvals',
          style: GoogleFonts.inter(
            fontSize: 18,
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
      body: pendingAsync.when(
        data: (pharmacies) {
          if (pharmacies.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle_outline_rounded, size: 80, color: Colors.green.withValues(alpha: 0.5)),
                  const SizedBox(height: 20),
                  Text(
                    'All clear!',
                    style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'No pending approvals at the moment.',
                    style: GoogleFonts.inter(color: AppTheme.textSecondaryColor),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(20),
            itemCount: pharmacies.length,
            itemBuilder: (context, index) {
              final pharmacy = pharmacies[index];
              return _buildPharmacyCard(context, ref, pharmacy);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget _buildPharmacyCard(BuildContext context, WidgetRef ref, UserProfile pharmacy) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                child: Text(
                  pharmacy.storeName?.substring(0, 1) ?? pharmacy.name.substring(0, 1),
                  style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pharmacy.storeName ?? pharmacy.name,
                      style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    Text(
                      pharmacy.email,
                      style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textSecondaryColor),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 32),
          _buildInfoRow('License', pharmacy.licenseNumber ?? 'N/A'),
          _buildInfoRow('NPI Number', pharmacy.npiNumber ?? 'N/A'),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => _handleReject(context, ref, pharmacy),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.red,
                    side: const BorderSide(color: Colors.red),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Reject'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => _handleApprove(context, ref, pharmacy),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Approve'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.inter(fontSize: 14, color: AppTheme.textSecondaryColor)),
          Text(value, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Future<void> _handleApprove(BuildContext context, WidgetRef ref, UserProfile pharmacy) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Approve Pharmacy?'),
        content: Text('Confirming ${pharmacy.storeName} license and registration.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Approve')),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(authServiceProvider).adminApprovePharmacy(pharmacy.uid);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pharmacy Approved!')));
      }
    }
  }

  Future<void> _handleReject(BuildContext context, WidgetRef ref, UserProfile pharmacy) async {
    final reasonController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Pharmacy?'),
        content: TextField(
          controller: reasonController,
          decoration: const InputDecoration(hintText: 'Rejection reason'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(context, true), child: const Text('Reject')),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(authServiceProvider).adminRejectPharmacy(pharmacy.uid, reasonController.text);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Pharmacy Rejected.')));
      }
    }
  }
}
