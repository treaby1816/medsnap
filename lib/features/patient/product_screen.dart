import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; // 1. Added Riverpod
import 'package:cached_network_image/cached_network_image.dart';
import '../../core/theme.dart';
import '../../core/providers/cart_provider.dart'; // 2. Added Cart Provider

class ProductScreen extends ConsumerWidget { // 3. Changed to ConsumerWidget
  final Map<String, dynamic> productData;

  const ProductScreen({
    super.key,
    required this.productData,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) { // 4. Added WidgetRef
    // Extract data with safe fallbacks
    final String name = productData['name'] ?? "Unknown Medication";
    final String price = productData['price']?.toString() ?? "0";
    final String imageUrl = productData['imageUrl'] ?? "";
    final String pharmacy = productData['pharmacyName'] ?? "Vail Partner Pharmacy";
    final String description = productData['description'] ?? "No description available.";

    return Scaffold(
      appBar: AppBar(
        title: Text(name),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Image Section
            Container(
              height: 250,
              width: double.infinity,
              color: Colors.grey[100],
              child: imageUrl.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: imageUrl,
                      fit: BoxFit.contain,
                      placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                      errorWidget: (context, url, error) => const Icon(Icons.medication, size: 100, color: Colors.grey),
                    )
                  : const Icon(Icons.medication, size: 100, color: Colors.grey),
            ),

            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Text("Pharmacy: $pharmacy", style: TextStyle(color: Colors.grey[600], fontSize: 16)),
                  const SizedBox(height: 16),
                  Text("₦$price", style: const TextStyle(fontSize: 22, color: AppTheme.primaryColor, fontWeight: FontWeight.bold)),
                  const Divider(height: 40),
                  const Text("About this Medication", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 10),
                  Text(description, style: const TextStyle(fontSize: 16, height: 1.5, color: Colors.black87)),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomAction(context, ref, name), // 5. Passed ref
    );
  }

  Widget _buildBottomAction(BuildContext context, WidgetRef ref, String name) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          )
        ],
      ),
      child: ElevatedButton(
        onPressed: () {
          // 6. Logic to add item to Riverpod cart state
          ref.read(cartProvider.notifier).addItem(productData);

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("$name added to your cart"),
              backgroundColor: AppTheme.primaryColor,
              behavior: SnackBarBehavior.floating,
              action: SnackBarAction(
                label: "VIEW CART",
                textColor: Colors.white,
                onPressed: () {
                  Navigator.pushNamed(context, '/orders');
                },
              ),
            ),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryColor,
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: const Text(
          "Add to Cart",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
        ),
      ),
    );
  }
}