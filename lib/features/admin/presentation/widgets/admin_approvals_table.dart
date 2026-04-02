import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme.dart';
import '../../../../core/models/user_profile.dart';
import '../../../../core/providers/admin_providers.dart';

/// Inline "Recent Pending Approvals" table for the dashboard body.
/// Streams data from Firestore and provides a "Verify" action button.
class AdminApprovalsTable extends ConsumerWidget {
  final VoidCallback? onViewDirectory;
  const AdminApprovalsTable({super.key, this.onViewDirectory});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pendingAsync = ref.watch(adminPendingApprovalsProvider);
    final approvingUid = ref.watch(approvingPharmacyProvider);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Recent Pending Approvals',
                style: GoogleFonts.inter(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
              TextButton(
                onPressed: onViewDirectory,
                child: Text(
                  'Full Directory',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.primaryColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── Table Header ──
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: AppTheme.backgroundColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                _headerCell('PHARMACY NAME', flex: 3),
                _headerCell('SUBMISSION DATE', flex: 2),
                _headerCell('STATUS', flex: 2),
                _headerCell('LICENSE TYPE', flex: 2),
                _headerCell('ACTION', flex: 1),
              ],
            ),
          ),
          const SizedBox(height: 4),

          // ── Table Body ──
          pendingAsync.when(
            data: (pharmacies) {
              if (pharmacies.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 40),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.check_circle_outline_rounded, size: 48, color: Colors.green.withValues(alpha: 0.4)),
                        const SizedBox(height: 12),
                        Text('All approvals are up to date', style: GoogleFonts.inter(color: AppTheme.textSecondaryColor)),
                      ],
                    ),
                  ),
                );
              }

              return Column(
                children: pharmacies.take(5).map((pharmacy) {
                  return _buildRow(context, ref, pharmacy, approvingUid);
                }).toList(),
              );
            },
            loading: () => const Padding(
              padding: EdgeInsets.symmetric(vertical: 40),
              child: Center(child: CircularProgressIndicator(color: AppTheme.primaryColor, strokeWidth: 2)),
            ),
            error: (e, _) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 40),
              child: Center(child: Text('Error: $e', style: GoogleFonts.inter(color: Colors.red))),
            ),
          ),
        ],
      ),
    );
  }

  Widget _headerCell(String text, {required int flex}) {
    return Expanded(
      flex: flex,
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: AppTheme.textTertiaryColor,
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  Widget _buildRow(BuildContext context, WidgetRef ref, UserProfile pharmacy, String? approvingUid) {
    final isApproving = approvingUid == pharmacy.uid;
    final initials = (pharmacy.storeName ?? pharmacy.name)
        .split(' ')
        .take(2)
        .map((w) => w.isNotEmpty ? w[0].toUpperCase() : '')
        .join();

    final dateStr = pharmacy.createdAt != null
        ? DateFormat('MMM dd, yyyy').format(pharmacy.createdAt!)
        : 'N/A';

    final status = pharmacy.verificationStatus;
    Color statusColor;
    String statusLabel;
    switch (status) {
      case 'pending':
        statusColor = AppTheme.primaryColor;
        statusLabel = 'UNDER REVIEW';
        break;
      case 'rejected':
        statusColor = Colors.red;
        statusLabel = 'REJECTED';
        break;
      default:
        statusColor = const Color(0xFFF59E0B);
        statusLabel = 'IN QUEUE';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: AppTheme.borderColor.withValues(alpha: 0.5))),
      ),
      child: Row(
        children: [
          // Pharmacy Name
          Expanded(
            flex: 3,
            child: Row(
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    initials,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    pharmacy.storeName ?? pharmacy.name,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimaryColor,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),

          // Submission Date
          Expanded(
            flex: 2,
            child: Text(
              dateStr,
              style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textSecondaryColor),
            ),
          ),

          // Status Badge
          Expanded(
            flex: 2,
            child: Align(
              alignment: Alignment.centerLeft,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: statusColor.withValues(alpha: 0.3)),
                ),
                child: Text(
                  statusLabel,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: statusColor,
                  ),
                ),
              ),
            ),
          ),

          // License Type
          Expanded(
            flex: 2,
            child: InkWell(
              onTap: pharmacy.licenseNumber != null 
                  ? () => launchUrl(
                        Uri.parse('https://search.dca.ca.gov/results?query=${pharmacy.licenseNumber}'),
                        mode: LaunchMode.externalApplication,
                      )
                  : null,
              borderRadius: BorderRadius.circular(4),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      pharmacy.licenseNumber != null ? 'Verify License' : 'N/A',
                      style: GoogleFonts.inter(
                        fontSize: 13, 
                        color: pharmacy.licenseNumber != null ? AppTheme.primaryColor : AppTheme.textSecondaryColor,
                        fontWeight: pharmacy.licenseNumber != null ? FontWeight.w600 : FontWeight.normal,
                        decoration: pharmacy.licenseNumber != null ? TextDecoration.underline : TextDecoration.none,
                      ),
                    ),
                    if (pharmacy.licenseNumber != null)
                      Text(
                        pharmacy.licenseNumber!,
                        style: GoogleFonts.inter(fontSize: 10, color: AppTheme.textTertiaryColor),
                      ),
                  ],
                ),
              ),
            ),
          ),

          // Action
          Expanded(
            flex: 1,
            child: SizedBox(
              height: 32,
              child: ElevatedButton(
                onPressed: isApproving ? null : () => _handleVerify(context, ref, pharmacy),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF0F172A),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: isApproving
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : Text(
                        'Verify',
                        style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700),
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleVerify(BuildContext context, WidgetRef ref, UserProfile pharmacy) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Approve Pharmacy?', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        content: Text(
          'Confirm approval of "${pharmacy.storeName ?? pharmacy.name}".\nThis will grant access to the product marketplace.',
          style: GoogleFonts.inter(color: AppTheme.textSecondaryColor),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: GoogleFonts.inter(color: AppTheme.textSecondaryColor)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: Text('Approve', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await approvePharmacy(ref, pharmacy.uid);
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${pharmacy.storeName ?? pharmacy.name} approved successfully!'),
              backgroundColor: const Color(0xFF22C55E),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Approval failed: $e'),
              backgroundColor: Colors.redAccent,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    }
  }
}
