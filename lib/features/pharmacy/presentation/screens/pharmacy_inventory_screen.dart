import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme.dart';
import '../../../../core/providers.dart';
import '../../../../core/models/product_model.dart';
import '../../../../widgets/glass_app_bar.dart';
import '../widgets/pharmacy_product_card.dart';
import 'add_product_screen.dart';

class PharmacyInventoryScreen extends ConsumerWidget {
  final bool isEmbedded;
  const PharmacyInventoryScreen({super.key, this.isEmbedded = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider);
    if (user == null) {
      return const Scaffold(body: Center(child: Text('Please log in')));
    }

    final productsAsync = ref.watch(pharmacyProductsProvider(user.id));

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: GlassAppBar(
        leading: isEmbedded
            ? null // No back button when embedded in tab
            : IconButton(
                icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimaryColor),
                onPressed: () => Navigator.pop(context),
              ),
        title: Text(
          'My Inventory',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimaryColor,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add_circle_outline, color: AppTheme.primaryColor),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AddProductScreen()),
            ),
          ),
          if (!isEmbedded)
            IconButton(
              icon: const Icon(Icons.close_rounded, color: AppTheme.textSecondaryColor),
              onPressed: () => Navigator.pop(context),
            ),
          const SizedBox(width: 8),
        ],
      ),
      body: productsAsync.when(
        data: (products) => products.isEmpty
            ? _buildEmptyState(context)
            : GridView.builder(
                padding: const EdgeInsets.all(AppTheme.pagePadding),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  childAspectRatio: 0.75,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                ),
                itemCount: products.length,
                itemBuilder: (context, index) {
                  final product = products[index];
                  return PharmacyProductCard(
                    product: product,
                    onEdit: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Edit feature coming soon!')),
                      );
                    },
                    onDelete: () => _showDeleteDialog(context, ref, product),
                  );
                },
              ),
        loading: () => const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor)),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.inventory_2_outlined, size: 80, color: AppTheme.textTertiaryColor.withValues(alpha: 0.3)),
          const SizedBox(height: 20),
          Text(
            'No products found',
            style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textSecondaryColor),
          ),
          const SizedBox(height: 8),
          Text(
            'Start by adding your first medication.',
            style: GoogleFonts.inter(color: AppTheme.textTertiaryColor),
          ),
          const SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const AddProductScreen()),
            ),
            icon: const Icon(Icons.add),
            label: const Text('Add Product'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, WidgetRef ref, Product product) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Product'),
        content: Text('Are you sure you want to delete ${product.name}? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => AddProductScreen(existingProduct: product)),
              );
            },
            child: const Text('Edit', style: TextStyle(color: Colors.blue)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await ref.read(pharmacyServiceProvider).deleteProduct(product.id, product.imageUrl);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Product deleted')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.redAccent)),
          ),
        ],
      ),
    );
  }
}
