import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../../../core/theme.dart';
import '../../../../core/providers.dart';
import '../../../../widgets/glass_app_bar.dart';

class PharmacyOrdersScreen extends ConsumerWidget {
  const PharmacyOrdersScreen({super.key});

  void _updateOrderStatus(BuildContext context, String orderId, String newStatus) async {
    try {
      await FirebaseFirestore.instance.collection('orders').doc(orderId).update({
        'status': newStatus,
      });
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Order marked as $newStatus')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider);
    if (user == null) return const Scaffold(body: Center(child: Text('Please log in')));

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: GlassAppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppTheme.textPrimaryColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Manage Orders',
          style: GoogleFonts.inter(
            fontSize: 20,
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
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('orders')
            .where('globalPharmacyId', isEqualTo: user.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          
          final orders = snapshot.data!.docs;
          if (orders.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.shopping_bag_outlined, size: 64, color: AppTheme.primaryColor),
                  ),
                  const SizedBox(height: 24),
                  Text('No Orders Yet', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 20, color: AppTheme.textPrimaryColor)),
                  const SizedBox(height: 8),
                  Text('Your incoming orders will appear here.', style: GoogleFonts.inter(color: AppTheme.textSecondaryColor, fontSize: 14)),
                ],
              ),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(AppTheme.pagePadding),
            itemCount: orders.length,
            itemBuilder: (context, index) {
              final order = orders[index].data() as Map<String, dynamic>;
              final orderId = orders[index].id;
              final status = order['status'] ?? 'Pending';
              final total = order['totalAmount'] ?? 0.0;
              final items = order['items'] as List<dynamic>? ?? [];

              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(color: Colors.grey.withValues(alpha: 0.1)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Order #${orderId.substring(0, 8)}',
                            style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: AppTheme.textPrimaryColor),
                          ),
                          _StatusBadge(status: status),
                        ],
                      ),
                      const Divider(height: 24),
                      ...items.map((item) => Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Text('${item['quantity']}x ', style: const TextStyle(fontWeight: FontWeight.bold)),
                            Expanded(child: Text(item['name'] ?? 'Item')),
                            Text('₦${item['price']}'),
                          ],
                        ),
                      )),
                      const Divider(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Total', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                          Text('₦${total.toStringAsFixed(2)}', 
                            style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: AppTheme.primaryColor, fontSize: 16)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      if (status == 'Pending')
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: () => _updateOrderStatus(context, orderId, 'Ready'),
                            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryColor, foregroundColor: Colors.white),
                            child: const Text('Mark as Ready'),
                          ),
                        )
                      else if (status == 'Ready')
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: () => _updateOrderStatus(context, orderId, 'Delivered'),
                            style: OutlinedButton.styleFrom(foregroundColor: Colors.green),
                            child: const Text('Mark as Delivered'),
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final String status;
  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color = Colors.grey;
    if (status == 'Pending') color = Colors.orange;
    if (status == 'Ready') color = Colors.blue;
    if (status == 'Delivered') color = Colors.green;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        status,
        style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.bold),
      ),
    );
  }
}
