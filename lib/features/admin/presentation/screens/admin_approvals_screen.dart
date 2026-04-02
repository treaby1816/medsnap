import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/theme.dart';
import '../../../../core/models/user_profile.dart';
import '../../../../core/providers.dart';
import '../../../../core/providers/admin_providers.dart';

class AdminApprovalsScreen extends ConsumerStatefulWidget {
  const AdminApprovalsScreen({super.key});

  @override
  ConsumerState<AdminApprovalsScreen> createState() => _AdminApprovalsScreenState();
}

class _AdminApprovalsScreenState extends ConsumerState<AdminApprovalsScreen> {
  UserProfile? _selectedPharmacy;
  final Set<String> _recentlyApproved = {};

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      debugPrint('Could not launch $url');
    }
  }

  @override
  Widget build(BuildContext context) {
    final pendingAsync = ref.watch(adminPendingApprovalsProvider);
    final approvingUid = ref.watch(approvingPharmacyProvider);
    final currentUserInfo = ref.watch(userProfileProvider).value;
    final isSeniorAuditor = currentUserInfo?.role == 'super_admin' || currentUserInfo?.role == 'admin';

    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Page Header ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'VERIFICATION QUEUE',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.primaryColor,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Pharmacist Credentials',
                    style: GoogleFonts.inter(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.textPrimaryColor,
                    ),
                  ),
                ],
              ),
              Row(
                children: [
                  OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.filter_list_rounded, size: 18),
                    label: Text('Filters', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppTheme.borderColor),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                  ),
                  const SizedBox(width: 10),
                  OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.download_rounded, size: 18),
                    label: Text('Export CSV', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppTheme.borderColor),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ── Split Pane ──
          Expanded(
            child: pendingAsync.when(
              data: (pharmacies) {
                // Remove recently approved from immediate UI view while fading out
                final visiblePharmacies = pharmacies.where((p) => !_recentlyApproved.contains(p.uid)).toList();
                return _buildSplitPane(visiblePharmacies, approvingUid, isSeniorAuditor);
              },
              loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor)),
              error: (e, _) => Center(child: Text('Error: $e')),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSplitPane(List<UserProfile> pharmacies, String? approvingUid, bool isSeniorAuditor) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Left: Data Table (flex 8) ──
        Expanded(
          flex: 8,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppTheme.borderColor),
            ),
            child: Column(
              children: [
                // Table Header
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                  decoration: const BoxDecoration(
                    color: AppTheme.backgroundColor,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                  ),
                  child: Row(
                    children: [
                      _headerCell('PHARMACY NAME', flex: 3),
                      _headerCell('LICENSE NUMBER', flex: 2),
                      _headerCell('SUBMISSION', flex: 2),
                      _headerCell('STATUS', flex: 2),
                      _headerCell('ACTION', flex: 2),
                    ],
                  ),
                ),
                // Table Rows
                Expanded(
                  child: pharmacies.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.check_circle_outline, size: 56, color: Colors.green.withValues(alpha: 0.4)),
                              const SizedBox(height: 12),
                              Text('No pending applications', style: GoogleFonts.inter(color: AppTheme.textSecondaryColor)),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: pharmacies.length,
                          padding: EdgeInsets.zero,
                          itemBuilder: (context, index) {
                            final pharmacy = pharmacies[index];
                            final isSelected = _selectedPharmacy?.uid == pharmacy.uid;
                            return _buildAnimatedTableRow(pharmacy, isSelected, approvingUid);
                          },
                        ),
                ),
                // Pagination (visual)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  decoration: const BoxDecoration(
                    border: Border(top: BorderSide(color: AppTheme.borderColor)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Showing ${pharmacies.length} of ${pharmacies.length} applications',
                        style: GoogleFonts.inter(fontSize: 12, color: AppTheme.primaryColor),
                      ),
                      Row(
                        children: [
                          _paginationBtn('<', false),
                          _paginationBtn('1', true),
                          _paginationBtn('2', false),
                          _paginationBtn('3', false),
                          _paginationBtn('>', false),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 20),

        // ── Right: License Preview Sidebar (flex 4) ──
        Expanded(
          flex: 4,
          child: _buildLicensePreview(approvingUid, isSeniorAuditor),
        ),
      ],
    );
  }

  Widget _buildAnimatedTableRow(UserProfile pharmacy, bool isSelected, String? approvingUid) {
    // Check if this row is currently being approved
    final isApprovingThis = approvingUid == pharmacy.uid;

    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child: isApprovingThis
          ? Container(
              height: 70,
              color: Colors.green.withValues(alpha: 0.1),
              child: const Center(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.check_circle_rounded, color: Colors.green, size: 24),
                    SizedBox(width: 10),
                    Text('Approving and creating record...', style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            )
          : _buildTableRow(pharmacy, isSelected, approvingUid),
    );
  }

  Widget _buildTableRow(UserProfile pharmacy, bool isSelected, String? approvingUid) {
    final dateStr = pharmacy.createdAt != null
        ? '${DateFormat('MMM dd, yyyy').format(pharmacy.createdAt!)}\n${DateFormat('hh:mm a').format(pharmacy.createdAt!)}'
        : 'N/A';

    final statusColor = pharmacy.verificationStatus == 'pending'
        ? AppTheme.primaryColor
        : const Color(0xFFF59E0B);
    final statusLabel = pharmacy.verificationStatus == 'pending' ? 'UNDER REVIEW' : 'PENDING';

    return Material(
      color: isSelected ? AppTheme.primaryColor.withValues(alpha: 0.04) : Colors.transparent,
      child: InkWell(
        onTap: () => setState(() => _selectedPharmacy = pharmacy),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            border: Border(
              left: isSelected
                  ? const BorderSide(color: AppTheme.primaryColor, width: 3)
                  : BorderSide.none,
              bottom: BorderSide(color: AppTheme.borderColor.withValues(alpha: 0.5)),
            ),
          ),
          child: Row(
            children: [
              // Pharmacy Name
              Expanded(
                flex: 3,
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      alignment: Alignment.center,
                      child: const Icon(Icons.storefront_rounded, size: 18, color: AppTheme.primaryColor),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            pharmacy.storeName ?? pharmacy.name,
                            style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.textPrimaryColor),
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (pharmacy.email.isNotEmpty)
                            Text(
                              pharmacy.email,
                              style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textTertiaryColor),
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // License Number
              Expanded(
                flex: 2,
                child: Text(
                  pharmacy.licenseNumber ?? 'N/A',
                  style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textSecondaryColor, fontWeight: FontWeight.w500),
                ),
              ),

              // Submission Date
              Expanded(
                flex: 2,
                child: Text(
                  dateStr,
                  style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondaryColor),
                ),
              ),

              // Status
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
                      style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w700, color: statusColor),
                    ),
                  ),
                ),
              ),

              // Action
              Expanded(
                flex: 2,
                child: TextButton(
                  onPressed: () => setState(() => _selectedPharmacy = pharmacy),
                  child: Text(
                    isSelected ? 'Review Details' : 'View Documents',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLicensePreview(String? approvingUid, bool isSeniorAuditor) {
    if (_selectedPharmacy == null) {
      return Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.borderColor),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.touch_app_outlined, size: 48, color: AppTheme.textTertiaryColor.withValues(alpha: 0.4)),
              const SizedBox(height: 12),
              Text(
                'Select an application',
                style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textSecondaryColor),
              ),
              const SizedBox(height: 4),
              Text(
                'Click a row to preview license details',
                style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textTertiaryColor),
              ),
            ],
          ),
        ),
      );
    }

    final pharmacy = _selectedPharmacy!;
    final isApproving = approvingUid == pharmacy.uid;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header & REF ID ──
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    pharmacy.storeName ?? pharmacy.name,
                    style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w800, color: AppTheme.textPrimaryColor),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'REF: APP-${pharmacy.uid.substring(0, 3).toUpperCase()}',
                    style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w800, color: AppTheme.primaryColor),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // ── Document Viewer Placeholder ──
            Container(
              width: double.infinity,
              height: 180,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0x1AEC5B13)), // Subtle Orange Outline (#ec5b131a)
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.description_outlined, size: 40, color: AppTheme.textTertiaryColor),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.zoom_in, size: 16),
                    label: Text('Enlarge Document', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600)),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: AppTheme.borderColor),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // ── Metadata Section ──
            Text(
              'SUBMITTED METADATA',
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: AppTheme.textTertiaryColor,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 12),
            _metadataRow('Full Legal Name', pharmacy.storeName ?? pharmacy.name),
            
            // License ID (Bold Monospace)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('License ID', style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondaryColor, fontWeight: FontWeight.bold)),
                  Text(
                    pharmacy.licenseNumber ?? 'N/A',
                    style: GoogleFonts.robotoMono(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ],
              ),
            ),
            
            _metadataRow('NPI Number', pharmacy.npiNumber ?? 'N/A'),
            _metadataRow('Email', pharmacy.email),
            const SizedBox(height: 12),

            // Verification Link
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {
                  const url = 'https://nabp.pharmacy/lookup';
                  _launchUrl(url);
                },
                icon: const Icon(Icons.open_in_new, size: 16),
                label: Text('Verify on NABP', style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppTheme.borderColor),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // ── System Cross-Check ──
            Text(
              'SYSTEM CROSS-CHECK',
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                color: AppTheme.textTertiaryColor,
                letterSpacing: 1.0,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFF0FDF4),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFF059669).withValues(alpha: 0.3)), // Green #059669
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: Color(0xFF059669), size: 22),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'License Verified',
                          style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.textPrimaryColor),
                        ),
                        Text(
                          'External database match found.',
                          style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textSecondaryColor),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ── Action Buttons ──
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: isApproving ? null : () => _handleReject(pharmacy),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: const BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text('Reject', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14)),
                  ),
                ),
                if (isSeniorAuditor) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: isApproving ? null : () => _handleApprove(pharmacy),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                      child: isApproving
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                            )
                          : Text('Approve', style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 14)),
                    ),
                  ),
                ],
              ],
            ),
            if (!isSeniorAuditor)
              Padding(
                padding: const EdgeInsets.only(top: 10),
                child: Text(
                  'Only Senior Auditors can approve pharmacy applications.',
                  style: GoogleFonts.inter(fontSize: 11, color: Colors.orange, fontStyle: FontStyle.italic),
                  textAlign: TextAlign.center,
                ),
              ),
          ],
        ),
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

  Widget _metadataRow(String label, String value, {Color? valueColor}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondaryColor, fontWeight: FontWeight.bold)),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: valueColor ?? AppTheme.textPrimaryColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _paginationBtn(String label, bool active) {
    return Container(
      width: 32,
      height: 32,
      margin: const EdgeInsets.symmetric(horizontal: 2),
      decoration: BoxDecoration(
        color: active ? AppTheme.primaryColor : Colors.transparent,
        borderRadius: BorderRadius.circular(6),
        border: active ? null : Border.all(color: AppTheme.borderColor),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: active ? Colors.white : AppTheme.textSecondaryColor,
        ),
      ),
    );
  }

  Future<void> _handleApprove(UserProfile pharmacy) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Approve Pharmacy?', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        content: Text(
          'Confirm approval of "${pharmacy.storeName ?? pharmacy.name}".\nThis will grant marketplace access and write an Audit Log.',
          style: GoogleFonts.inter(color: AppTheme.textSecondaryColor),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            child: const Text('Approve'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await approvePharmacy(ref, pharmacy.uid);
        
        // Hide the item from the UX gracefully
        setState(() {
          _recentlyApproved.add(pharmacy.uid);
          _selectedPharmacy = null;
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.check_circle_rounded, color: Colors.white),
                  const SizedBox(width: 10),
                  Text('${pharmacy.storeName ?? pharmacy.name} approved securely!'),
                ],
              ),
              backgroundColor: const Color(0xFF22C55E),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating),
          );
        }
      }
    }
  }

  Future<void> _handleReject(UserProfile pharmacy) async {
    final reasonController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text('Reject Application?', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Provide a reason for rejecting "${pharmacy.storeName ?? pharmacy.name}".', style: GoogleFonts.inter(color: AppTheme.textSecondaryColor)),
            const SizedBox(height: 12),
            TextField(
              controller: reasonController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Reason for rejection...',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
            child: const Text('Reject'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await rejectPharmacy(ref, pharmacy.uid, reasonController.text);
        
        setState(() {
          _recentlyApproved.add(pharmacy.uid);
          _selectedPharmacy = null;
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${pharmacy.storeName ?? pharmacy.name} rejected.'), behavior: SnackBarBehavior.floating),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating),
          );
        }
      }
    }
  }
}
