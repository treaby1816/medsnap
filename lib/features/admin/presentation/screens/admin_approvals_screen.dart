import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
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



  @override
  Widget build(BuildContext context) {
    final pendingAsync = ref.watch(adminPendingApprovalsProvider);
    final approvingUid = ref.watch(approvingPharmacyProvider);
    final currentUserInfo = ref.watch(userProfileProvider).value;
    final isSeniorAuditor = currentUserInfo?.role == 'super_admin' || currentUserInfo?.role == 'admin';

    return Stack(
      children: [
        Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Hub Header ──
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'SECURITY & VERIFICATION',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.primaryColor,
                          letterSpacing: 2.0,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Clinical Verification Queue',
                        style: GoogleFonts.inter(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          color: AppTheme.textPrimaryColor,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ],
                  ),
                  _buildHeaderActions(),
                ],
              ),
              const SizedBox(height: 32),

              // ── Layout Switcher (Split Pane) ──
              Expanded(
                child: pendingAsync.when(
                  data: (pharmacies) {
                    final visible = pharmacies.where((p) => !_recentlyApproved.contains(p.uid)).toList();
                    return _buildWorkspaceSplit(visible, approvingUid, isSeniorAuditor);
                  },
                  loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor)),
                  error: (e, _) => Center(child: Text('Verification Stream Error: $e', style: const TextStyle(color: Colors.red))),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildHeaderActions() {
    return Row(
      children: [
        _actionBtn(Icons.assignment_turned_in_outlined, 'VailMeds Audit Log'),
        const SizedBox(width: 12),
        _actionBtn(Icons.security_rounded, 'Compliance Policy'),
      ],
    );
  }

  Widget _actionBtn(IconData icon, String label) {
    return OutlinedButton.icon(
      onPressed: () {},
      icon: Icon(icon, size: 16),
      label: Text(label, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700)),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppTheme.textSecondaryColor,
        side: const BorderSide(color: AppTheme.borderColor),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  Widget _buildWorkspaceSplit(List<UserProfile> pharmacies, String? approvingUid, bool isSeniorAuditor) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Main Queue (Table flex 8) ──
        Expanded(
          flex: 8,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: AppTheme.borderColor),
              boxShadow: [
                BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 20, offset: const Offset(0, 10))
              ],
            ),
            child: Column(
              children: [
                // Premium Table Header
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
                  decoration: BoxDecoration(
                    color: AppTheme.backgroundColor.withValues(alpha: 0.5),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  ),
                  child: Row(
                    children: [
                      _headerCell('ENTITY NAME', flex: 4),
                      _headerCell('IDENTIFIER', flex: 2),
                      _headerCell('TIMESTAMP', flex: 2),
                      _headerCell('SEC. STATUS', flex: 2),
                      _headerCell('ACTION', flex: 2),
                    ],
                  ),
                ),
                // Scrollable Table Body
                Expanded(
                  child: pharmacies.isEmpty
                      ? _buildEmptyQueue()
                      : ListView.builder(
                          itemCount: pharmacies.length,
                          padding: EdgeInsets.zero,
                          itemBuilder: (context, index) {
                            final pharmacy = pharmacies[index];
                            final isSelected = _selectedPharmacy?.uid == pharmacy.uid;
                            return _buildQueueRow(pharmacy, isSelected, approvingUid);
                          },
                        ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 24),

        // ── Clinical Inspector (flex 4) ──
        Expanded(
          flex: 4,
          child: _buildInspectorPane(approvingUid, isSeniorAuditor),
        ),
      ],
    );
  }

  Widget _buildQueueRow(UserProfile pharmacy, bool isSelected, String? approvingUid) {
    final isApproving = approvingUid == pharmacy.uid;
    final dateStr = pharmacy.createdAt != null
        ? DateFormat('MMM dd, hh:mm a').format(pharmacy.createdAt!)
        : 'N/A';

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      color: isSelected ? AppTheme.primaryColor.withValues(alpha: 0.02) : Colors.transparent,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => setState(() => _selectedPharmacy = pharmacy),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
            decoration: BoxDecoration(
              border: Border(
                left: isSelected ? const BorderSide(color: AppTheme.primaryColor, width: 4) : BorderSide.none,
                bottom: BorderSide(color: AppTheme.borderColor.withValues(alpha: 0.5)),
              ),
            ),
            child: Row(
              children: [
                // Entity info
                Expanded(
                  flex: 4,
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: isSelected ? AppTheme.primaryColor : AppTheme.backgroundColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.business_rounded, 
                          size: 18, 
                          color: isSelected ? Colors.white : AppTheme.primaryColor
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              pharmacy.storeName ?? pharmacy.name,
                              style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.textPrimaryColor),
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              pharmacy.email,
                              style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textTertiaryColor),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // License ID
                Expanded(
                  flex: 2,
                  child: Text(
                    pharmacy.licenseNumber ?? 'UNASSIGNED',
                    style: GoogleFonts.robotoMono(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textSecondaryColor),
                  ),
                ),
                // Timestamp
                Expanded(
                  flex: 2,
                  child: Text(dateStr, style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textSecondaryColor)),
                ),
                // Security status
                Expanded(
                  flex: 2,
                  child: _statusBadge(pharmacy.verificationStatus),
                ),
                // CTA
                Expanded(
                  flex: 2,
                  child: Text(
                    isApproving ? 'VERIFYING...' : 'REVIEW',
                    style: GoogleFonts.inter(
                      fontSize: 11, 
                      fontWeight: FontWeight.w900, 
                      color: isApproving ? const Color(0xFF22C55E) : AppTheme.primaryColor,
                      letterSpacing: 1.0
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

  Widget _statusBadge(String status) {
    final color = status == 'pending' ? AppTheme.primaryColor : const Color(0xFFF59E0B);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 6, height: 6, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 8),
          Text(
            status.toUpperCase(),
            style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w800, color: color),
          ),
        ],
      ),
    );
  }

  Widget _buildInspectorPane(String? approvingUid, bool isSeniorAuditor) {
    if (_selectedPharmacy == null) {
      return _buildInspectorPlaceholder();
    }

    final p = _selectedPharmacy!;
    final isApproving = approvingUid == p.uid;

    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.borderColor),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 20, offset: const Offset(0, 10))
        ],
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Pane Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('ENTITY PROFILE', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w800, color: AppTheme.textTertiaryColor, letterSpacing: 1.5)),
                _trustIndicator(88), // Mock trust score
              ],
            ),
            const SizedBox(height: 24),
            
            Text(p.storeName ?? p.name, style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.w800, color: AppTheme.textPrimaryColor)),
            const SizedBox(height: 8),
            Text(p.email, style: GoogleFonts.inter(fontSize: 14, color: AppTheme.textSecondaryColor)),
            
            const SizedBox(height: 32),
            
            // Document Review
            _sectionLabel('PRIMARY CREDENTIALS'),
            const SizedBox(height: 12),
            _buildDocPreview(),
            const SizedBox(height: 24),
            
            // Metadata Grid
            _metadataItem('License Number', p.licenseNumber ?? 'N/A', isMono: true),
            _metadataItem('NPI Record', p.npiNumber ?? 'Pending Discovery'),
            _metadataItem('Entity Type', 'Licensed Pharmacy Hub'),
            
            const SizedBox(height: 40),
            
            // Verification Actions
            if (isSeniorAuditor) ...[
              _verificationCTA(
                onTap: isApproving ? null : () => _handleApprove(p),
                label: isApproving ? 'Writing Audit Block...' : 'SECURE APPROVAL',
                icon: Icons.verified_user_rounded,
                isPrimary: true,
              ),
              const SizedBox(height: 12),
            ],
            _verificationCTA(
              onTap: isApproving ? null : () => _handleReject(p),
              label: 'FLAG FOR REVIEW',
              icon: Icons.flag_rounded,
              isPrimary: false,
            ),
          ],
        ),
      ),
    );
  }

  Widget _trustIndicator(int score) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0xFF22C55E).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          const Icon(Icons.bolt_rounded, size: 14, color: Color(0xFF22C55E)),
          const SizedBox(width: 4),
          Text('TRUST SCORE: $score', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w800, color: const Color(0xFF22C55E))),
        ],
      ),
    );
  }

  Widget _buildDocPreview() {
    return Container(
      width: double.infinity,
      height: 220,
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Stack(
        children: [
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.contact_page_outlined, size: 48, color: AppTheme.textTertiaryColor.withValues(alpha: 0.5)),
                const SizedBox(height: 12),
                Text('SECURED LICENSE PDF', style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.bold, color: AppTheme.textTertiaryColor)),
              ],
            ),
          ),
          Positioned(
            bottom: 16, right: 16,
            child: FloatingActionButton.small(
              onPressed: () {},
              backgroundColor: Colors.white,
              elevation: 4,
              child: const Icon(Icons.open_in_full_rounded, size: 18, color: AppTheme.primaryColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _metadataItem(String label, String value, {bool isMono = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.textTertiaryColor)),
          const SizedBox(height: 4),
          Text(
            value,
            style: isMono 
              ? GoogleFonts.robotoMono(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.primaryColor)
              : GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.textPrimaryColor),
          ),
        ],
      ),
    );
  }

  Widget _verificationCTA({required VoidCallback? onTap, required String label, required IconData icon, required bool isPrimary}) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 20),
        label: Text(label, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w800, letterSpacing: 0.5)),
        style: ElevatedButton.styleFrom(
          backgroundColor: isPrimary ? AppTheme.primaryColor : Colors.white,
          foregroundColor: isPrimary ? Colors.white : const Color(0xFFEF4444),
          elevation: 0,
          side: isPrimary ? null : const BorderSide(color: Color(0xFFEF4444)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }

  Widget _sectionLabel(String text) {
    return Text(text, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w800, color: AppTheme.textTertiaryColor, letterSpacing: 1.0));
  }

  Widget _buildInspectorPlaceholder() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: AppTheme.backgroundColor,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.verified_user_outlined, size: 48, color: AppTheme.textTertiaryColor),
            ),
            const SizedBox(height: 24),
            Text('Clinical Review Workspace', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.textPrimaryColor)),
            const SizedBox(height: 8),
            Text('Select a pharmacy from the queue\nto begin clinical verification.', textAlign: TextAlign.center, style: GoogleFonts.inter(fontSize: 14, color: AppTheme.textSecondaryColor)),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyQueue() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.check_circle_outline_rounded, size: 64, color: const Color(0xFF22C55E).withValues(alpha: 0.5)),
          const SizedBox(height: 16),
          Text('All entities verified', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.textPrimaryColor)),
          Text('The verification queue is currently empty.', style: GoogleFonts.inter(color: AppTheme.textSecondaryColor)),
        ],
      ),
    );
  }

  Widget _headerCell(String text, {required int flex}) {
    return Expanded(
      flex: flex,
      child: Text(text, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w800, color: AppTheme.textTertiaryColor, letterSpacing: 1.5)),
    );
  }

  // ── Logic Handlers (Unchanged signature) ──

  Future<void> _handleApprove(UserProfile pharmacy) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('SECURE APPROVAL', style: GoogleFonts.inter(fontWeight: FontWeight.w800, letterSpacing: 0.5)),
          content: Text(
            'Confirming digital verification for "${pharmacy.storeName ?? pharmacy.name}". This action will be logged in the immutable audit trail.',
            style: GoogleFonts.inter(color: AppTheme.textSecondaryColor),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('CANCEL', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: AppTheme.textTertiaryColor))),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              child: const Text('AUTHORIZE'),
            ),
          ],
        ),
      ),
    );

    if (confirmed == true) {
      try {
        await approvePharmacy(ref, pharmacy.uid);
        setState(() {
          _recentlyApproved.add(pharmacy.uid);
          _selectedPharmacy = null;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Entity ${pharmacy.storeName ?? pharmacy.name} approved and logged.'),
              backgroundColor: const Color(0xFF22C55E),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Approval Fail: $e'), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating),
          );
        }
      }
    }
  }

  Future<void> _handleReject(UserProfile pharmacy) async {
    final reasonController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('FLAG FOR REVIEW', style: GoogleFonts.inter(fontWeight: FontWeight.w800, color: const Color(0xFFEF4444))),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Specify the compliance violation for "${pharmacy.storeName ?? pharmacy.name}".', style: GoogleFonts.inter(color: AppTheme.textSecondaryColor)),
              const SizedBox(height: 16),
              TextField(
                controller: reasonController,
                maxLines: 3,
                decoration: InputDecoration(
                  hintText: 'Compliance notes...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  filled: true,
                  fillColor: AppTheme.backgroundColor,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('CANCEL')),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFEF4444), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
              child: const Text('FLAG ENTITY'),
            ),
          ],
        ),
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
            const SnackBar(content: Text('Entity flagged for review.'), behavior: SnackBarBehavior.floating),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Fail: $e'), backgroundColor: Colors.red, behavior: SnackBarBehavior.floating),
          );
        }
      }
    }
  }
}
