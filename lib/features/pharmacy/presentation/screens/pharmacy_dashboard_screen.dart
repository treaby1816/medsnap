import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers.dart';
import '../../../../core/theme.dart';
import 'pharmacy_inventory_screen.dart';
import 'add_product_screen.dart';
import '../../../../core/widgets/shimmer_loading.dart';
import '../../../../widgets/hover_card.dart';
import '../../../../core/models/product_model.dart';
import '../widgets/pharmacy_product_card.dart';
import 'package:url_launcher/url_launcher.dart';

class PharmacyDashboardScreen extends ConsumerStatefulWidget {
  const PharmacyDashboardScreen({super.key});

  @override
  ConsumerState<PharmacyDashboardScreen> createState() => _PharmacyDashboardScreenState();
}

class _PharmacyDashboardScreenState extends ConsumerState<PharmacyDashboardScreen> {
  final Color _deepBlue = const Color(0xFF1E293B);
  final Color _surfaceColor = const Color(0xFFF8F6F6);
  
  void _processOrder(String orderId) {
    HapticFeedback.mediumImpact();
    // Simulate updating the order
    Supabase.instance.client.from('orders').update({
      'status': 'preparing'
    }).eq('id', orderId).then((_) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 12),
              Text(
                "Order Verified & Preparing",
                style: GoogleFonts.inter(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          backgroundColor: AppTheme.primaryColor,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 2),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _surfaceColor,
      appBar: AppBar(
        backgroundColor: _deepBlue,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
          onPressed: () => Navigator.of(context).pushNamedAndRemoveUntil('/gateway', (route) => false),
        ),
        title: Text(
          'Pharmacy Executive Terminal',
          style: GoogleFonts.inter(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
          ),
        ),
        centerTitle: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner, color: Colors.white),
            tooltip: 'Scan to Update Inventory',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AddProductScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded, color: Colors.white70),
            tooltip: 'Close',
            onPressed: () => Navigator.of(context).pushNamedAndRemoveUntil('/gateway', (route) => false),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Personalized Welcome
            ref.watch(userProfileProvider).when(
              data: (profile) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Good Morning,',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: AppTheme.textSecondaryColor,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    profile?.name ?? 'Pharmacist',
                    style: GoogleFonts.inter(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: _deepBlue,
                      letterSpacing: -1,
                    ),
                  ),
                ],
              ),
              loading: () => const SizedBox(height: 40),
              error: (_, __) => const SizedBox(height: 40),
            ),
            const SizedBox(height: 24),
            
            // Executive Stats Grid (Responsive)
            StreamBuilder<List<Map<String, dynamic>>>(
              stream: Supabase.instance.client
                  .from('orders')
                  .stream(primaryKey: ['id'])
                  .eq('pharmacy_id', ref.watch(authProvider)?.id ?? ''),
              builder: (context, orderSnap) {
                return StreamBuilder<List<Map<String, dynamic>>>(
                  stream: Supabase.instance.client
                      .from('products')
                      .stream(primaryKey: ['id'])
                      .eq('pharmacyId', ref.watch(authProvider)?.id ?? ''),
                  builder: (context, productSnap) {
                    int pending = 0;
                    int pickups = 0;
                    int lowStockCount = 0;
                    
                    if (orderSnap.hasData) {
                      for (var data in orderSnap.data!) {
                        final status = data['status']?.toString().toLowerCase();
                        if (status == 'pending') pending++;
                        if (status == 'processing' || status == 'ready') pickups++;
                      }
                    }

                    if (productSnap.hasData) {
                      for (var data in productSnap.data!) {
                        final stock = data['stockCount'] ?? 0;
                        final max = data['maxStock'] ?? 0;
                        if (max > 0 && (stock / max) < 0.2) lowStockCount++;
                      }
                    }

                    return LayoutBuilder(
                      builder: (context, constraints) {
                        final bool isSmallMobile = constraints.maxWidth < 400;
                        final bool isMobile = constraints.maxWidth < 600;
                        
                        return GridView.count(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          crossAxisCount: isSmallMobile ? 1 : (isMobile ? 2 : 3),
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                          childAspectRatio: isSmallMobile ? 2.8 : 2.2,
                          children: [
                            _StatCard(
                              title: 'New Orders',
                              value: pending.toString().padLeft(2, '0'),
                              backgroundColor: AppTheme.primaryColor,
                              textColor: Colors.white,
                              icon: Icons.receipt_long,
                            ),
                            _StatCard(
                              title: 'Pickups',
                              value: pickups.toString().padLeft(2, '0'),
                              backgroundColor: Colors.white,
                              textColor: const Color(0xFF1E293B),
                              icon: Icons.shopping_bag_outlined,
                            ),
                            _StatCard(
                              title: 'Low Stock',
                              value: lowStockCount.toString().padLeft(2, '0'),
                              backgroundColor: const Color(0xFFFEE2E2),
                              textColor: const Color(0xFFDC2626),
                              icon: Icons.warning_amber_rounded,
                            ),
                          ],
                        );
                      }
                    );
                  }
                );
              }
            ),
            const SizedBox(height: 32),
            
            // Live on Marketplace Gallery
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.shopping_bag_outlined, color: AppTheme.primaryColor, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Live on Marketplace',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: _deepBlue,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const PharmacyInventoryScreen()),
                    );
                  },
                  child: Text(
                    'View All',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 220,
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: Supabase.instance.client
                    .from('products')
                    .stream(primaryKey: ['id'])
                    .eq('pharmacyId', ref.watch(authProvider)?.id ?? '')
                    .order('createdAt', ascending: false)
                    .limit(10),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return ListView.separated(
                      scrollDirection: Axis.horizontal,
                      separatorBuilder: (_, __) => const SizedBox(width: 16),
                      itemCount: 3,
                      itemBuilder: (_, __) => const ShimmerEffect(width: 160, height: 220, borderRadius: 16),
                    );
                  }
                  
                  final products = snapshot.data?.map((doc) => Product.fromMap(doc, doc['id'].toString())).toList() ?? [];
                  
                  if (products.isEmpty) {
                    return Container(
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.1)),
                      ),
                      child: Center(
                        child: Text("No products uploaded yet", style: GoogleFonts.inter(color: Colors.grey)),
                      ),
                    );
                  }

                  return ListView.separated(
                    scrollDirection: Axis.horizontal,
                    physics: const BouncingScrollPhysics(),
                    itemCount: products.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 16),
                    itemBuilder: (context, index) {
                      return SizedBox(
                        width: 160,
                        child: PharmacyProductCard(
                          product: products[index],
                        ),
                      );
                    },
                  );
                },
              ),
            ),

            // Live Order Queue
            Row(
              children: [
                const Icon(Icons.flash_on, color: AppTheme.primaryColor, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Live Order Queue',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: _deepBlue,
                    letterSpacing: -0.5,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            StreamBuilder<List<Map<String, dynamic>>>(
              stream: Supabase.instance.client
                  .from('orders')
                  .stream(primaryKey: ['id'])
                  .eq('pharmacy_id', ref.watch(authProvider)?.id ?? ''),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Container(
                    padding: const EdgeInsets.all(16),
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1), 
                      borderRadius: BorderRadius.circular(16)
                    ),
                    child: Text('Stream Error: ${snapshot.error}', style: const TextStyle(color: Colors.red)),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: 3,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (_, __) => const ShimmerEffect(width: double.infinity, height: 80, borderRadius: 16),
                  );
                }
                
                if (!snapshot.hasData) {
                  return const SizedBox.shrink();
                }
                
                final rawDocs = snapshot.data!.where((d) => d['status'] == 'Pending').toList();
                // Sort client-side
                final docs = List<Map<String, dynamic>>.from(rawDocs);
                docs.sort((a, b) {
                  final aTime = a['createdAt'] != null ? DateTime.tryParse(a['createdAt']) : null;
                  final bTime = b['createdAt'] != null ? DateTime.tryParse(b['createdAt']) : null;
                  return (bTime ?? DateTime(0)).compareTo(aTime ?? DateTime(0));
                });

                if (docs.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryColor.withValues(alpha: 0.05),
                          blurRadius: 20,
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Text("No pending orders right now."),
                    ),
                  );
                }

                return ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: docs.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final data = docs[index];
                    final docId = docs[index]['id'].toString();
                    final time = data['createdAt'] != null ? DateTime.tryParse(data['createdAt']) : null;
                    
                    String timeString = 'Recently';
                    if (time != null) {
                      final diff = DateTime.now().difference(time);
                      if (diff.inMinutes < 60) {
                        timeString = '${diff.inMinutes == 0 ? 1 : diff.inMinutes}m ago';
                      } else if (diff.inHours < 24) {
                        timeString = '${diff.inHours}h ago';
                      } else {
                        timeString = '${diff.inDays}d ago';
                      }
                    }

                    return HoverCard(
                      borderRadius: BorderRadius.circular(16),
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: _surfaceColor,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.person, color: Colors.grey),
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
                                      data['patientName'] ?? 'Unknown Patient',
                                      style: GoogleFonts.inter(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16,
                                        color: _deepBlue,
                                      ),
                                    ),
                                    Text(
                                      timeString,
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.primaryColor,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  data['medication'] ?? 'Multiple Items',
                                  style: GoogleFonts.inter(
                                    fontSize: 14,
                                    color: AppTheme.textSecondaryColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          ElevatedButton(
                            onPressed: () => _processOrder(docId),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryColor,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            ),
                            child: Text(
                              'Process',
                              style: GoogleFonts.inter(fontWeight: FontWeight.w700),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),

            const SizedBox(height: 40),

            // Inventory Quick-View
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.inventory_2, color: AppTheme.primaryColor, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'Fast Moving Items',
                      style: GoogleFonts.inter(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: _deepBlue,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const PharmacyInventoryScreen()),
                    );
                  },
                  child: Text(
                    'View Inventory',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            HoverCard(
              padding: const EdgeInsets.all(20),
              child: StreamBuilder<List<Map<String, dynamic>>>(
                stream: Supabase.instance.client
                  .from('products')
                  .stream(primaryKey: ['id'])
                  .eq('pharmacyId', ref.watch(authProvider)?.id ?? '')
                  .limit(5),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return Column(
                      children: List.generate(3, (i) => const Padding(
                        padding: EdgeInsets.only(bottom: 16),
                        child: ShimmerEffect(width: double.infinity, height: 60, borderRadius: 12),
                      )),
                    );
                  }
                  final productDocs = snapshot.data!;
                  if (productDocs.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        child: Text("No products listed yet.", style: GoogleFonts.inter(color: Colors.grey)),
                      ),
                    );
                  }
                  
                  return Column(
                     children: productDocs.map((doc) {
                       final data = doc;
                       final name = data['name'] ?? 'Product';
                       final stock = data['stockCount'] ?? 0;
                       final max = data['maxStock'] ?? 100;
                       final isLow = max > 0 && (stock / max) < 0.2;
                       
                       return Column(
                         children: [
                           _InventoryItem(
                             name: name, 
                             stockCount: stock, 
                             maxStock: max,
                             isLow: isLow,
                           ),
                           if (doc != productDocs.last) const Divider(height: 32),
                         ]
                       );
                     }).toList(),
                  );
                }
              ),
            ),
            const SizedBox(height: 24),
            _buildSupportSection(),
            const SizedBox(height: 100), // Space for bottom navigation
          ],
        ),
      ),
    );
  }

  Widget _buildSupportSection() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F172A).withValues(alpha: 0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white12,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.support_agent_rounded, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Technical Support',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'Direct human assistance',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: Colors.white60,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: _SupportButton(
                  icon: Icons.phone_in_talk_rounded,
                  label: 'Call Helpdesk',
                  onTap: () => _launchUrl('tel:+2348012345678'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SupportButton(
                  icon: Icons.chat_bubble_rounded,
                  label: 'WhatsApp',
                  onTap: () => _launchUrl('https://wa.me/2348012345678'),
                  color: const Color(0xFF22C55E),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
}

class _SupportButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  const _SupportButton({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: color?.withValues(alpha: 0.1) ?? Colors.white10,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color?.withValues(alpha: 0.3) ?? Colors.white10),
        ),
        child: Column(
          children: [
            Icon(icon, color: color ?? Colors.white, size: 20),
            const SizedBox(height: 8),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: color ?? Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final Color backgroundColor;
  final Color textColor;
  final IconData icon;

  const _StatCard({
    required this.title,
    required this.value,
    required this.backgroundColor,
    required this.textColor,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return HoverCard(
      padding: const EdgeInsets.all(16),
      liftAmount: -12,
      scaleAmount: 1.05,
      backgroundColor: backgroundColor,
      glowColor: backgroundColor,
      borderRadius: BorderRadius.circular(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: textColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: textColor, size: 20),
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: textColor,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: textColor.withValues(alpha: 0.7),
              letterSpacing: 0.5,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _InventoryItem extends StatelessWidget {
  final String name;
  final int stockCount;
  final int maxStock;
  final bool isLow;

  const _InventoryItem({
    required this.name,
    required this.stockCount,
    required this.maxStock,
    this.isLow = false,
  });

  @override
  Widget build(BuildContext context) {
    final Color progressColor = isLow ? const Color(0xFFDC2626) : const Color(0xFF059669); // Red or Green
    final double percentage = stockCount / maxStock;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              name,
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1E293B),
                fontSize: 14,
              ),
            ),
            Text(
              '$stockCount / $maxStock',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                color: isLow ? progressColor : Colors.grey.shade600,
                fontSize: 13,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: percentage,
            backgroundColor: progressColor.withValues(alpha: 0.1),
            valueColor: AlwaysStoppedAnimation<Color>(progressColor),
            minHeight: 6,
          ),
        ),
      ],
    );
  }
}

