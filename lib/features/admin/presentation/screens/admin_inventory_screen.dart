import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme.dart';
import '../../../../core/models/product_model.dart';
import '../../../../core/providers/admin_providers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Admin Inventory Screen displaying global stock.
class AdminInventoryScreen extends ConsumerStatefulWidget {
  const AdminInventoryScreen({super.key});

  @override
  ConsumerState<AdminInventoryScreen> createState() => _AdminInventoryScreenState();
}

class _AdminInventoryScreenState extends ConsumerState<AdminInventoryScreen> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
    
    _pulseAnimation = Tween<double>(begin: 0.4, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'GLOBAL INVENTORY',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                color: AppTheme.primaryColor,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Medication Stock Monitor',
              style: GoogleFonts.inter(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: AppTheme.textPrimaryColor,
              ),
            ),
            const SizedBox(height: 24),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppTheme.borderColor),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                    decoration: const BoxDecoration(
                      color: AppTheme.backgroundColor,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                    ),
                    child: Row(
                      children: [
                        _headerCell('MEDICATION', flex: 3),
                        _headerCell('PHARMACY', flex: 2),
                        _headerCell('STOCK COUNT', flex: 2),
                        _headerCell('STATUS', flex: 2),
                      ],
                    ),
                  ),
                  _buildInventoryList(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInventoryList() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('products').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Padding(
            padding: EdgeInsets.all(32),
            child: Center(child: CircularProgressIndicator(color: AppTheme.primaryColor)),
          );
        }

        final products = snapshot.data!.docs
            .map((doc) => Product.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .toList();

        if (products.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(32),
            child: Center(
              child: Text(
                'No inventory records found.',
                style: GoogleFonts.inter(color: AppTheme.textSecondaryColor),
              ),
            ),
          );
        }

        return ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: products.length,
          separatorBuilder: (context, index) => const Divider(height: 1),
          itemBuilder: (context, index) {
            final p = products[index];
            final isCritical = p.stockCount < lowStockThreshold;
            
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: Text(
                      p.name,
                      style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: AppTheme.textPrimaryColor),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      p.pharmacyName,
                      style: GoogleFonts.inter(color: AppTheme.textSecondaryColor, fontSize: 13),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          p.stockCount.toString(),
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w800,
                            color: isCritical ? Colors.red : AppTheme.textPrimaryColor,
                            fontSize: 16,
                          ),
                        ),
                        if (isCritical) ...[
                          const SizedBox(width: 8),
                          FadeTransition(
                            opacity: _pulseAnimation,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'LOW STOCK',
                                style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Text(
                      isCritical ? 'NEEDS RESTOCK' : 'HEALTHY',
                      style: GoogleFonts.inter(
                        color: isCritical ? Colors.red : Colors.green,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
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
}
