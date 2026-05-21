import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// PatientSearchScreen — Drug Search & Catalog
// Translated from the VailMeds HTML/Tailwind mockup.
// NOTE: Bottom Navigation is handled by MainNavigationScreen.
// ─────────────────────────────────────────────────────────────────────────────

class PatientSearchScreen extends StatefulWidget {
  const PatientSearchScreen({super.key});

  @override
  State<PatientSearchScreen> createState() => _PatientSearchScreenState();
}

class _PatientSearchScreenState extends State<PatientSearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedCategory = 'All';
  bool _isBooking = false;

  // Category data with icons
  static const List<Map<String, dynamic>> _categories = [
    {'name': 'All', 'icon': null},
    {'name': 'Pain Relief', 'icon': Icons.medical_services_outlined},
    {'name': 'Antibiotics', 'icon': Icons.coronavirus_outlined},
    {'name': 'Chronic Care', 'icon': Icons.favorite_outline},
    {'name': 'First Aid', 'icon': Icons.health_and_safety_outlined},
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ── Booking Logic ────────────────────────────────────────────────────────
  Future<void> _confirmBooking(String medId, String medName, double price) async {
    setState(() => _isBooking = true);

    try {
      await Supabase.instance.client.from('orders').insert({
        'medicationId': medId,
        'medicationName': medName,
        'price': price,
        'status': 'Pending',
        'orderDate': DateTime.now().toIso8601String(),
        'customerName': 'Guest User',
      });

      if (!mounted) return;

      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => _SuccessDialog(
          message: 'Your order for $medName has been placed. Track it in the Orders tab.',
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _isBooking = false);
    }
  }

  // ── Build ────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppTheme.darkBackgroundColor : const Color(0xFFF4F7FA),
      body: Stack(
        children: [
          CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              _buildSearchHeader(isDark),
              SliverToBoxAdapter(child: _buildCategoryChips(isDark)),
              SliverToBoxAdapter(child: _buildResultsHeader()),
              _buildResultsList(isDark),
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],
          ),

          // Loading overlay during booking
          if (_isBooking) _buildLoadingOverlay(),
        ],
      ),
    );
  }

  // ── 1. Search Header with Gradient ───────────────────────────────────────
  Widget _buildSearchHeader(bool isDark) {
    return SliverToBoxAdapter(
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.primaryColor.withValues(alpha: 0.05),
              Colors.transparent,
            ],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Find your medication',
              style: GoogleFonts.inter(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : AppTheme.textPrimaryColor,
              ),
            ),
            const SizedBox(height: 16),
            _buildSearchInput(isDark),
          ],
        ),
      ),
    );
  }

  // ── 2. Search Input ──────────────────────────────────────────────────────
  Widget _buildSearchInput(bool isDark) {
    return Container(
      height: 56,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.white.withValues(alpha: 0.1) : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (value) {
          setState(() {
            _searchQuery = value.toLowerCase().trim();
          });
        },
        style: GoogleFonts.inter(
          fontSize: 15,
          color: isDark ? Colors.white : AppTheme.textPrimaryColor,
        ),
        decoration: InputDecoration(
          hintText: 'Search by drug name or brand...',
          hintStyle: GoogleFonts.inter(
            color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
            fontSize: 15,
          ),
          prefixIcon: const Icon(Icons.search, color: Color(0xFF94A3B8), size: 22),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: Icon(
                    Icons.clear,
                    size: 18,
                    color: isDark ? Colors.white38 : Colors.grey,
                  ),
                  onPressed: () {
                    _searchController.clear();
                    setState(() => _searchQuery = '');
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 18),
        ),
      ),
    );
  }

  // ── 3. Category Chips ────────────────────────────────────────────────────
  Widget _buildCategoryChips(bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Categories',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppTheme.textPrimaryColor,
                  ),
                ),
                GestureDetector(
                  onTap: () {},
                  child: Text(
                    'See All',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 42,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: _categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final cat = _categories[index];
                final isSelected = _selectedCategory == cat['name'];
                return _buildChip(
                  label: cat['name'] as String,
                  icon: cat['icon'] as IconData?,
                  isSelected: isSelected,
                  isDark: isDark,
                  onTap: () => setState(() => _selectedCategory = cat['name'] as String),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChip({
    required String label,
    required IconData? icon,
    required bool isSelected,
    required bool isDark,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryColor
              : isDark
                  ? const Color(0xFF1E293B)
                  : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: isSelected
              ? null
              : Border.all(
                  color: isDark
                      ? Colors.white.withValues(alpha: 0.1)
                      : const Color(0xFFE2E8F0),
                ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppTheme.primaryColor.withValues(alpha: 0.25),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  )
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null && !isSelected) ...[
              Icon(icon, size: 16, color: AppTheme.primaryColor),
              const SizedBox(width: 6),
            ],
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected
                    ? Colors.white
                    : isDark
                        ? Colors.white70
                        : AppTheme.textPrimaryColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── 4. Results Header ────────────────────────────────────────────────────
  Widget _buildResultsHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Search Results',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          GestureDetector(
            onTap: () {},
            child: Row(
              children: [
                const Icon(Icons.filter_list, size: 18, color: Color(0xFF64748B)),
                const SizedBox(width: 4),
                Text(
                  'Sort',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── 5. Results List (Firestore-powered) ──────────────────────────────────
  Widget _buildResultsList(bool isDark) {
    return SliverToBoxAdapter(
      child: StreamBuilder<List<Map<String, dynamic>>>(
        stream: Supabase.instance.client.from('medications').stream(primaryKey: ['id']),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Padding(
              padding: EdgeInsets.all(40),
              child: Center(child: Text('Error loading data')),
            );
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Padding(
              padding: EdgeInsets.all(40),
              child: Center(
                child: CircularProgressIndicator(color: AppTheme.primaryColor),
              ),
            );
          }

          final docs = snapshot.data!.where((data) {
            final name = (data['name'] ?? '').toString().toLowerCase();
            final brand = (data['brand'] ?? '').toString().toLowerCase();
            final category = data['category'] ?? '';

            final matchesSearch =
                _searchQuery.isEmpty || name.contains(_searchQuery) || brand.contains(_searchQuery);
            final matchesCategory =
                _selectedCategory == 'All' || category == _selectedCategory;

            return matchesSearch && matchesCategory;
          }).toList();

          if (docs.isEmpty) {
            return _buildEmptyState(isDark);
          }

          return ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final data = docs[index];
              final String medId = data['id'].toString();
              return _ProductCard(
                medId: medId,
                name: data['name'] ?? 'Unknown Drug',
                brand: data['brand'] ?? 'General',
                subtitle: data['subtitle'] ?? data['description'] ?? '',
                price: (data['price'] ?? 0.0).toDouble(),
                imageUrl: data['imageUrl'] ?? '',
                isAvailable: data['isAvailable'] ?? true,
                isDark: isDark,
                isBooking: _isBooking,
                onViewDetails: () {
                  Navigator.pushNamed(context, '/product', arguments: data);
                },
                onNotifyMe: () {},
                onConfirmBooking: () => _confirmBooking(
                  medId,
                  data['name'] ?? 'Unknown',
                  (data['price'] ?? 0.0).toDouble(),
                ),
              );
            },
          );
        },
      ),
    );
  }

  // ── 6. Empty State ───────────────────────────────────────────────────────
  Widget _buildEmptyState(bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(40),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.search_off_rounded,
              size: 36,
              color: AppTheme.primaryColor,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'No medications found',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white70 : AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Try adjusting your search or category filter',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
            ),
          ),
        ],
      ),
    );
  }

  // ── 7. Loading Overlay ───────────────────────────────────────────────────
  Widget _buildLoadingOverlay() {
    return Container(
      color: Colors.black.withValues(alpha: 0.4),
      child: Center(
        child: Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          elevation: 12,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 36, vertical: 28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryColor),
                ),
                const SizedBox(height: 18),
                Text(
                  'Confirming Order...',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// _ProductCard — Modular product card widget
// Handles In Stock / Out of Stock states per the HTML mockup
// ═════════════════════════════════════════════════════════════════════════════

class _ProductCard extends StatelessWidget {
  final String medId;
  final String name;
  final String brand;
  final String subtitle;
  final double price;
  final String imageUrl;
  final bool isAvailable;
  final bool isDark;
  final bool isBooking;
  final VoidCallback onViewDetails;
  final VoidCallback onNotifyMe;
  final VoidCallback onConfirmBooking;

  const _ProductCard({
    required this.medId,
    required this.name,
    required this.brand,
    required this.subtitle,
    required this.price,
    required this.imageUrl,
    required this.isAvailable,
    required this.isDark,
    required this.isBooking,
    required this.onViewDetails,
    required this.onNotifyMe,
    required this.onConfirmBooking,
  });

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: isAvailable ? 1.0 : 0.75,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : const Color(0xFFF1F5F9),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image with stock badge
            _buildImage(),
            const SizedBox(width: 14),
            // Details
            Expanded(child: _buildDetails()),
          ],
        ),
      ),
    );
  }

  Widget _buildImage() {
    return SizedBox(
      width: 96,
      height: 96,
      child: Stack(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: ColorFiltered(
              colorFilter: isAvailable
                  ? const ColorFilter.mode(Colors.transparent, BlendMode.multiply)
                  : const ColorFilter.matrix(<double>[
                      0.2126, 0.7152, 0.0722, 0, 0,
                      0.2126, 0.7152, 0.0722, 0, 0,
                      0.2126, 0.7152, 0.0722, 0, 0,
                      0, 0, 0, 1, 0,
                    ]),
              child: imageUrl.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: imageUrl,
                      width: 96,
                      height: 96,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(
                        color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                        child: const Icon(Icons.medication, size: 32, color: Colors.grey),
                      ),
                      errorWidget: (_, __, ___) => Container(
                        color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                        child: const Icon(Icons.medication, size: 32, color: Colors.grey),
                      ),
                    )
                  : Container(
                      width: 96,
                      height: 96,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.medication, size: 36, color: Colors.grey),
                    ),
            ),
          ),
          // Stock badge
          Positioned(
            top: 4,
            left: 4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
              decoration: BoxDecoration(
                color: isAvailable ? const Color(0xFF22C55E) : const Color(0xFF64748B),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                isAvailable ? 'IN STOCK' : 'OUT OF STOCK',
                style: GoogleFonts.inter(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Brand
        Text(
          brand.toUpperCase(),
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: AppTheme.primaryColor,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 3),
        // Name
        Text(
          name,
          style: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : AppTheme.textPrimaryColor,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        // Subtitle
        if (subtitle.isNotEmpty) ...[
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: const Color(0xFF94A3B8),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
        const SizedBox(height: 10),
        // Price + Action Button
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '₦${price.toStringAsFixed(2)}',
              style: GoogleFonts.inter(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: isAvailable
                    ? (isDark ? Colors.white : AppTheme.textPrimaryColor)
                    : const Color(0xFF94A3B8),
              ),
            ),
            _buildActionButton(),
          ],
        ),
      ],
    );
  }

  Widget _buildActionButton() {
    if (isAvailable) {
      return GestureDetector(
        onTap: onViewDetails,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            'View Details',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ),
      );
    } else {
      return GestureDetector(
        onTap: onNotifyMe,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            'Notify Me',
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF64748B),
            ),
          ),
        ),
      );
    }
  }
}

// ═════════════════════════════════════════════════════════════════════════════
// _SuccessDialog — Success confirmation after booking
// ═════════════════════════════════════════════════════════════════════════════

class _SuccessDialog extends StatelessWidget {
  final String message;
  const _SuccessDialog({required this.message});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFF22C55E).withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle, color: Color(0xFF22C55E), size: 52),
            ),
            const SizedBox(height: 20),
            Text(
              'Order Successful!',
              style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(color: const Color(0xFF64748B), fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/orders');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: Text(
                  'Go to Orders',
                  style: GoogleFonts.inter(fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Back to Search',
                style: GoogleFonts.inter(
                  color: const Color(0xFF64748B),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

