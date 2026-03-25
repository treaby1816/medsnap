import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme.dart';
import '../../core/providers.dart';

class OrdersScreen extends ConsumerWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartProvider);
    final cartItems = cart.values.toList();

    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          _buildHeader(),
          // Shows the active checkout area if items are in the cart
          if (cartItems.isNotEmpty) _buildActiveCartSection(context, ref, cartItems),
          
          const Padding(
            padding: EdgeInsets.fromLTRB(20, 20, 20, 10),
            child: Row(
              children: [
                Icon(Icons.history, size: 18, color: Colors.grey),
                SizedBox(width: 8),
                Text("Order History",
                    style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
              ],
            ),
          ),
          
          Expanded(
            child: Builder(
              builder: (context) {
                final currentUser = ref.watch(authProvider);
                if (currentUser == null) {
                  return const Center(
                    child: Text('Please sign in to view your orders.',
                      style: TextStyle(color: Colors.grey, fontSize: 16)),
                  );
                }
                return StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('orders')
                      .where('userId', isEqualTo: currentUser.uid)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.hasError) {
                      debugPrint('Firestore Error: ${snapshot.error}');
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.cloud_off, size: 48, color: Colors.grey.shade300),
                            const SizedBox(height: 12),
                            const Text('Could not load orders.',
                              style: TextStyle(color: Colors.grey, fontSize: 14)),
                            const SizedBox(height: 8),
                            TextButton(
                              onPressed: () => ref.invalidate(authProvider),
                              child: const Text('Retry'),
                            ),
                          ],
                        ),
                      );
                    }
                
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                      child: CircularProgressIndicator(color: AppTheme.primaryColor));
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return cartItems.isEmpty ? _buildEmptyState() : const SizedBox.shrink();
                }

                final orders = snapshot.data!.docs;
                return ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                  itemCount: orders.length,
                  itemBuilder: (context, index) {
                    final order = orders[index].data() as Map<String, dynamic>;
                    return _buildOrderHistoryCard(order);
                  },
                );
              },
            );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveCartSection(BuildContext context, WidgetRef ref, List<CartItem> items) {
    final total = ref.watch(cartProvider.notifier).total;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 20),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primaryColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text("${items.length} Items in Cart",
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              Text("₦${total.toStringAsFixed(2)}",
                  style: const TextStyle(
                      color: AppTheme.primaryColor, fontWeight: FontWeight.bold)),
            ],
          ),
          const SizedBox(height: 12),
          // Show items with pharmacy name
          ...items.map((item) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    "${item.name} (${item.pharmacyName})",
                    style: const TextStyle(fontSize: 12, color: AppTheme.textSecondaryColor),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  "x${item.quantity}",
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          )),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _showPaymentSheet(context, ref),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text("PROCEED TO CHECKOUT", 
                style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1)),
            ),
          ),
        ],
      ),
    );
  }

  // PAYMENT SELECTION BOTTOM SHEET
  void _showPaymentSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(25))),
      builder: (context) => Container(
        padding: const EdgeInsets.all(25),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Select Payment Method", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            ListTile(
              leading: const Icon(Icons.credit_card, color: AppTheme.primaryColor),
              title: const Text("Pay with Card"),
              onTap: () => _handleCheckout(context, ref),
            ),
            ListTile(
              leading: const Icon(Icons.account_balance, color: AppTheme.primaryColor),
              title: const Text("Bank Transfer"),
              onTap: () => _handleCheckout(context, ref),
            ),
          ],
        ),
      ),
    );
  }

  // THE FULL CHECKOUT EXECUTION LOGIC
  void _handleCheckout(BuildContext context, WidgetRef ref) async {
    Navigator.pop(context); // Close BottomSheet

    // 1. Show a loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const Center(
        child: CircularProgressIndicator(color: AppTheme.primaryColor),
      ),
    );

    try {
      // 2. Execute the checkout logic from our provider
      await ref.read(cartProvider.notifier).checkout();

      // 3. Remove the loading indicator
      if (context.mounted) Navigator.pop(context);

      // 4. Navigate to Success Screen
      if (context.mounted) {
        Navigator.pushNamed(context, '/success');
      }
    } catch (e) {
      // 5. If it fails, remove loading and show error
      if (context.mounted) Navigator.pop(context);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Checkout Failed: ${e.toString()}"),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Widget _buildOrderHistoryCard(Map<String, dynamic> order) {
    final List items = order['items'] ?? [];
    final String medName = items.isNotEmpty ? items[0]['name'] : 'Medication Order';
    final double price = (order['totalAmount'] ?? 0.0).toDouble();
    final String status = order['status'] ?? 'Pending';
    final Timestamp? date = order['orderDate'] as Timestamp?;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade100),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.medication_outlined, color: AppTheme.primaryColor),
        ),
        title: Text(
          items.length > 1 ? "$medName + ${items.length - 1} more" : medName,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              date != null
                  ? "${date.toDate().day}/${date.toDate().month}/${date.toDate().year}"
                  : "Processing...",
              style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
            ),
            if (items.isNotEmpty)
              Text(
                "Source: ${items[0]['pharmacyName'] ?? 'Verified Pharmacy'}",
                style: const TextStyle(color: AppTheme.primaryColor, fontSize: 11, fontWeight: FontWeight.w500),
              ),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text("₦${price.toStringAsFixed(2)}",
                style: const TextStyle(
                    fontWeight: FontWeight.bold, color: AppTheme.primaryColor)),
            const SizedBox(height: 8),
            _buildStatusChip(status),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(20, 60, 20, 20),
      decoration: const BoxDecoration(color: Colors.white),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Orders & Cart", style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
          Text("Manage your current cart and past orders",
              style: TextStyle(fontSize: 14, color: Colors.grey)),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_bag_outlined, size: 64, color: Colors.grey.shade300),
          const SizedBox(height: 16),
          const Text("Your cart and history are empty.",
              style: TextStyle(color: Colors.grey, fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    Color chipColor = Colors.orange;
    if (status == 'Completed' || status == 'Delivered') {
      chipColor = Colors.green;
    } else if (status == 'Cancelled') {
      chipColor = Colors.red;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: chipColor.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status,
        style: TextStyle(color: chipColor, fontSize: 11, fontWeight: FontWeight.bold),
      ),
    );
  }
}