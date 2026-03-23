import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme.dart';
import '../../../../widgets/glass_app_bar.dart';

class PharmacyLogsScreen extends ConsumerStatefulWidget {
  const PharmacyLogsScreen({super.key});

  @override
  ConsumerState<PharmacyLogsScreen> createState() =>
      _PharmacyLogsScreenState();
}

class _PharmacyLogsScreenState extends ConsumerState<PharmacyLogsScreen> {
  final TextEditingController _searchController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: GlassAppBar(
        title: Text(
          'Activity Logs',
          style: GoogleFonts.inter(
            color: AppTheme.textPrimaryColor,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.filter_list,
                color: AppTheme.textPrimaryColor),
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar — uses theme InputDecorationTheme
          Padding(
            padding: const EdgeInsets.all(AppTheme.pagePadding),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search logs...',
                prefixIcon: const Icon(Icons.search,
                    color: AppTheme.textSecondaryColor),
                hintStyle:
                    GoogleFonts.inter(color: AppTheme.textSecondaryColor),
              ),
            ),
          ),

          // Logs List
          Expanded(
            child: ListView(
              padding:
                  const EdgeInsets.symmetric(horizontal: AppTheme.pagePadding),
              children: [
                _buildLogItem(
                  icon: Icons.inventory_2_outlined,
                  title: 'Stock Updated',
                  description: 'Amoxicillin 500mg restocked (+50 units)',
                  time: '10 mins ago',
                  iconColor: const Color(0xFF16A34A),
                  bgColor: const Color(0xFF16A34A).withValues(alpha: 0.1),
                ),
                _buildLogItem(
                  icon: Icons.shopping_cart_outlined,
                  title: 'New Order',
                  description: 'Order ORD-8831 placed by customer',
                  time: '45 mins ago',
                  iconColor: const Color(0xFF3B82F6),
                  bgColor: const Color(0xFF3B82F6).withValues(alpha: 0.1),
                ),
                _buildLogItem(
                  icon: Icons.person_outline,
                  title: 'Profile Updated',
                  description: 'Pharmacist profile details modified',
                  time: '2 hours ago',
                  iconColor: const Color(0xFF8B5CF6),
                  bgColor: const Color(0xFF8B5CF6).withValues(alpha: 0.1),
                ),
                _buildLogItem(
                  icon: Icons.warning_amber_rounded,
                  title: 'Low Stock Alert',
                  description: 'Lisinopril 10mg reached critical level',
                  time: '5 hours ago',
                  iconColor: const Color(0xFFEF4444),
                  bgColor: const Color(0xFFEF4444).withValues(alpha: 0.1),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLogItem({
    required IconData icon,
    required String title,
    required String description,
    required String time,
    required Color iconColor,
    required Color bgColor,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        boxShadow: AppTheme.floatingShadow,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.textPrimaryColor,
                      ),
                    ),
                    Text(
                      time,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        color: AppTheme.textSecondaryColor,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: AppTheme.textSecondaryColor,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}