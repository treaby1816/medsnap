import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/theme.dart';
import '../../../../core/models/product_model.dart';
import '../../../../core/providers/admin_providers.dart';

/// Admin Inventory Screen — Global Stock Intelligence Hub
class AdminInventoryScreen extends ConsumerStatefulWidget {
  const AdminInventoryScreen({super.key});

  @override
  ConsumerState<AdminInventoryScreen> createState() => _AdminInventoryScreenState();
}

class _AdminInventoryScreenState extends ConsumerState<AdminInventoryScreen> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(vsync: this, duration: const Duration(seconds: 1))..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.3, end: 1.0).animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'SUPPLY CHAIN INTELLIGENCE', 
                    style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w800, color: AppTheme.primaryColor, letterSpacing: 2.0)
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Global Inventory Monitor', 
                    style: GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.w800, color: AppTheme.textPrimaryColor, letterSpacing: -0.5)
                  ),
                ],
              ),
              _buildGlobalSearch(),
            ],
          ),
          const SizedBox(height: 32),

          // ── Stock Health Overview ──
          _buildInventoryGrid(),
          const SizedBox(height: 48),
        ],
      ),
    );
  }

  Widget _buildGlobalSearch() {
    return Container(
      width: 320,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: TextField(
        controller: _searchController,
        onChanged: (v) => setState(() => _searchQuery = v.toLowerCase()),
        style: GoogleFonts.inter(fontSize: 14),
        decoration: InputDecoration(
          hintText: 'Search SKU or Pharmacy...',
          hintStyle: GoogleFonts.inter(color: AppTheme.textTertiaryColor),
          prefixIcon: const Icon(Icons.search_rounded, size: 20, color: AppTheme.textTertiaryColor),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
        ),
      ),
    );
  }

  Widget _buildInventoryGrid() {
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Live Stock Telemetry', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.textPrimaryColor)),
              _inventoryLegend(),
            ],
          ),
          const SizedBox(height: 24),
          _buildStreamContent(),
        ],
      ),
    );
  }

  Widget _inventoryLegend() {
    return Row(
      children: [
        _legendItem(const Color(0xFF22C55E), 'Healthy'),
        const SizedBox(width: 16),
        _legendItem(const Color(0xFFF59E0B), 'Monitoring'),
        const SizedBox(width: 16),
        _legendItem(const Color(0xFFEF4444), 'Critical'),
      ],
    );
  }

  Widget _legendItem(Color color, String label) {
    return Row(
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 6),
        Text(label, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w700, color: AppTheme.textSecondaryColor)),
      ],
    );
  }

  Widget _buildStreamContent() {
    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: Supabase.instance.client.from('products').stream(primaryKey: ['id']),
      builder: (context, snapshot) {
        if (snapshot.hasError) return Center(child: Text('Data Stream Error: ${snapshot.error}'));
        if (!snapshot.hasData) return const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor));

        final products = snapshot.data!
            .map((doc) => Product.fromMap(doc, doc['id'].toString()))
            .where((p) => p.name.toLowerCase().contains(_searchQuery) || p.pharmacyName.toLowerCase().contains(_searchQuery))
            .toList();

        if (products.isEmpty) {
          return _buildEmptyState();
        }

        return Column(
          children: [
            // Table Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
              color: AppTheme.backgroundColor.withValues(alpha: 0.5),
              child: Row(children: [
                _headerCell('MEDICATION SKU', flex: 4),
                _headerCell('PHARMACY NODE', flex: 3),
                _headerCell('AVAILABLE UNIT', flex: 2),
                _headerCell('HEALTH STATUS', flex: 2),
              ]),
            ),
            // Table Rows
            ...products.map((p) => _buildInventoryRow(p)),
          ],
        );
      },
    );
  }

  Widget _buildInventoryRow(Product p) {
    final bool isLow = p.stockCount < lowStockThreshold;
    final bool isCritical = p.stockCount < (lowStockThreshold / 2);
    final statusColor = isCritical ? const Color(0xFFEF4444) : (isLow ? const Color(0xFFF59E0B) : const Color(0xFF22C55E));
    final statusText = isCritical ? 'CRITICAL' : (isLow ? 'MONITOR' : 'OPTIMAL');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: AppTheme.borderColor.withValues(alpha: 0.5))),
      ),
      child: Row(
        children: [
          // Medication
          Expanded(
            flex: 4,
            child: Row(
              children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Center(child: Icon(Icons.medication_rounded, size: 20, color: statusColor)),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(p.name, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.textPrimaryColor)),
                      Text('Category: Clinical Pharma', style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textTertiaryColor)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          // Pharmacy
          Expanded(
            flex: 3,
            child: Row(
              children: [
                const Icon(Icons.location_on_outlined, size: 14, color: AppTheme.textTertiaryColor),
                const SizedBox(width: 6),
                Text(p.pharmacyName, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textSecondaryColor)),
              ],
            ),
          ),
          // Unit Count
          Expanded(
            flex: 2,
            child: Text(
              p.stockCount.toString(),
              style: GoogleFonts.robotoMono(
                fontSize: 16, 
                fontWeight: FontWeight.w800, 
                color: statusColor,
              ),
            ),
          ),
          // Health Status
          Expanded(
            flex: 2,
            child: Row(
              children: [
                FadeTransition(
                  opacity: (isLow || isCritical) ? _pulseAnimation : const AlwaysStoppedAnimation(1.0),
                  child: Container(width: 8, height: 8, decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle)),
                ),
                const SizedBox(width: 10),
                Text(
                  statusText,
                  style: GoogleFonts.inter(
                    fontSize: 11, 
                    fontWeight: FontWeight.w800, 
                    color: statusColor,
                    letterSpacing: 0.5
                  ),
                ),
              ],
            ),
          ),
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

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 60),
      child: Column(
        children: [
          Icon(Icons.inventory_2_outlined, size: 48, color: AppTheme.textTertiaryColor.withValues(alpha: 0.5)),
          const SizedBox(height: 16),
          Text('No matching records', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textSecondaryColor)),
          Text('Try adjusting your search query.', style: GoogleFonts.inter(color: AppTheme.textTertiaryColor)),
        ],
      ),
    );
  }
}

