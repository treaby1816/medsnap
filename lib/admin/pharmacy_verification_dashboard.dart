import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../core/providers/admin_providers.dart';
import '../core/models/user_profile.dart';
import '../core/providers.dart';

// Constants for Clinical Palette
const Color primaryOrange = Color(0xFFec5b13);
const Color backgroundSlate = Color(0xFF0F172A);
const Color surfaceColor = Color(0xFFF8F6F6);
const Color softRed = Color(0xFFEF4444);

class PharmacyVerificationDashboard extends ConsumerStatefulWidget {
  const PharmacyVerificationDashboard({super.key});

  @override
  ConsumerState<PharmacyVerificationDashboard> createState() => _PharmacyVerificationDashboardState();
}

class _PharmacyVerificationDashboardState extends ConsumerState<PharmacyVerificationDashboard> {
  String _searchQuery = '';
  UserProfile? _selectedPharmacy;
  bool _isProcessing = false;

  @override
  Widget build(BuildContext context) {
    final pendingPharmaciesAsync = ref.watch(adminPendingApprovalsProvider);

    return Scaffold(
      backgroundColor: surfaceColor,
      appBar: AppBar(
        backgroundColor: backgroundSlate,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Pharmacy Verification Hub',
          style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
      body: Row(
        children: [
          // Left: Searchable List
          Expanded(
            flex: 2,
            child: Column(
              children: [
                _buildSearchBar(),
                Expanded(
                  child: pendingPharmaciesAsync.when(
                    data: (pharmacies) {
                      var filteredList = pharmacies;
                      if (_searchQuery.isNotEmpty) {
                        filteredList = pharmacies.where((p) {
                          final name = p.storeName?.toLowerCase() ?? p.name.toLowerCase();
                          final license = p.licenseNumber?.toLowerCase() ?? '';
                          return name.contains(_searchQuery) || license.contains(_searchQuery);
                        }).toList();
                      }

                      if (filteredList.isEmpty) {
                        return _buildEmptyState();
                      }

                      return ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: filteredList.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 12),
                        itemBuilder: (context, index) {
                          final pharmacy = filteredList[index];
                          final isSelected = _selectedPharmacy?.uid == pharmacy.uid;
                          return _buildPharmacyCard(pharmacy, isSelected);
                        },
                      );
                    },
                    loading: () => const Center(child: CircularProgressIndicator(color: primaryOrange)),
                    error: (err, stack) => Center(child: Text('Error: $err')),
                  ),
                ),
              ],
            ),
          ),
          
          // Right: Verification Sidebar
          AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            width: _selectedPharmacy == null ? 0 : MediaQuery.of(context).size.width * 0.35,
            child: _selectedPharmacy == null ? const SizedBox.shrink() : _buildSidebar(),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Search by store name or license...',
          hintStyle: GoogleFonts.inter(color: Colors.grey, fontSize: 14),
          prefixIcon: const Icon(Icons.search, color: primaryOrange, size: 20),
          filled: true,
          fillColor: Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 0),
        ),
        onChanged: (val) => setState(() => _searchQuery = val.toLowerCase()),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.assignment_turned_in_outlined, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          Text(
            'Queue Clear',
            style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey),
          ),
          Text(
            'No pending pharmacy verifications.',
            style: GoogleFonts.inter(color: Colors.grey.shade500),
          ),
        ],
      ),
    );
  }

  Widget _buildPharmacyCard(UserProfile pharmacy, bool isSelected) {
    return InkWell(
      onTap: () => setState(() => _selectedPharmacy = pharmacy),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.white.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? primaryOrange : Colors.transparent,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            const CircleAvatar(
              radius: 24,
              backgroundColor: backgroundSlate,
              child: Icon(Icons.local_pharmacy, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    pharmacy.storeName ?? pharmacy.name,
                    style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16, color: backgroundSlate),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'License: ${pharmacy.licenseNumber ?? "N/A"}',
                    style: GoogleFonts.inter(fontSize: 13, color: Colors.grey.shade600),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _buildSidebar() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(left: BorderSide(color: Color(0xFFE2E8F0), width: 1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSidebarHeader(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLicensePreview(),
                  const SizedBox(height: 32),
                  _buildInfoSection('Entity Details', [
                    _buildInfoRow('Store Name', _selectedPharmacy!.storeName ?? 'N/A'),
                    _buildInfoRow('Registration Name', _selectedPharmacy!.name),
                    _buildInfoRow('License Number', _selectedPharmacy!.licenseNumber ?? 'N/A'),
                    _buildInfoRow('NPI Number', _selectedPharmacy!.npiNumber ?? 'N/A'),
                  ]),
                  const SizedBox(height: 32),
                  _buildInfoSection('Contact Information', [
                    _buildInfoRow('Email Address', _selectedPharmacy!.email),
                    _buildInfoRow('Phone', _selectedPharmacy!.phone ?? 'N/A'),
                  ]),
                ],
              ),
            ),
          ),
          _buildActionButtons(),
        ],
      ),
    );
  }

  Widget _buildSidebarHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Verification Details',
            style: GoogleFonts.inter(fontSize: 22, fontWeight: FontWeight.bold, color: backgroundSlate),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => setState(() => _selectedPharmacy = null),
          ),
        ],
      ),
    );
  }

  Widget _buildLicensePreview() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'LICENSE PHOTO',
          style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w800, color: Colors.grey, letterSpacing: 1.2),
        ),
        const SizedBox(height: 12),
        GestureDetector(
          onTap: () => _showZoomedImage(_selectedPharmacy!.licensePhotoUrl),
          child: Hero(
            tag: 'license_photo_${_selectedPharmacy!.uid}',
            child: Container(
              height: 200,
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: _selectedPharmacy!.licensePhotoUrl != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: CachedNetworkImage(
                        imageUrl: _selectedPharmacy!.licensePhotoUrl!,
                        fit: BoxFit.cover,
                        placeholder: (_, __) => const Center(child: CircularProgressIndicator()),
                        errorWidget: (_, __, ___) => const Icon(Icons.broken_image_outlined, size: 40, color: Colors.grey),
                      ),
                    )
                  : const Center(child: Text('No photo provided')),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: Text(
            'Click to zoom and inspect',
            style: GoogleFonts.inter(fontSize: 12, color: primaryOrange, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  void _showZoomedImage(String? url) {
    if (url == null) return;
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(10),
        child: Stack(
          alignment: Alignment.center,
          children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(color: Colors.black54, width: double.infinity, height: double.infinity),
            ),
            Hero(
              tag: 'license_photo_${_selectedPharmacy!.uid}',
              child: InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: CachedNetworkImage(
                  imageUrl: url,
                  placeholder: (_, __) => const CircularProgressIndicator(),
                ),
              ),
            ),
            Positioned(
              top: 20,
              right: 20,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 32),
                onPressed: () => Navigator.pop(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.toUpperCase(),
          style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w800, color: primaryOrange, letterSpacing: 1.2),
        ),
        const SizedBox(height: 16),
        ...children,
      ],
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade500, fontWeight: FontWeight.w500)),
          const SizedBox(height: 4),
          Text(value, style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w600, color: backgroundSlate)),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -4)),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              style: OutlinedButton.styleFrom(
                foregroundColor: softRed,
                side: const BorderSide(color: softRed),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _isProcessing ? null : _handleReject,
              child: const Text('Reject', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryOrange,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: _isProcessing ? null : _handleApprove,
              child: _isProcessing
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Approve', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleApprove() async {
    if (_selectedPharmacy == null) return;
    
    setState(() => _isProcessing = true);
    try {
      final authService = ref.read(authServiceProvider);
      
      // Perform Path C Update (exactly 5 keys in the service layer)
      await authService.adminApprovePharmacy(_selectedPharmacy!.uid);
      
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pharmacy Verified Successfully!'), backgroundColor: Colors.green),
      );
      setState(() => _selectedPharmacy = null);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _handleReject() async {
    if (_selectedPharmacy == null) return;

    final reasonController = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reject Verification'),
        content: TextField(
          controller: reasonController,
          decoration: const InputDecoration(hintText: 'Enter reason for rejection'),
          maxLines: 3,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: softRed, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(context, reasonController.text),
            child: const Text('Reject'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty) {
      setState(() => _isProcessing = true);
      try {
        await ref.read(authServiceProvider).adminRejectPharmacy(_selectedPharmacy!.uid, result);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Pharmacy registration rejected.')),
        );
        setState(() => _selectedPharmacy = null);
      } catch (e) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      } finally {
        if (mounted) setState(() => _isProcessing = false);
      }
    }
  }
}
