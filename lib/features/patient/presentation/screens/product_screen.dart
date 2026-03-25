import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers.dart';
import '../../../../core/theme.dart';
import '../../../../core/models/product_model.dart';

class ProductScreen extends ConsumerWidget {
  final Product product;
  const ProductScreen({super.key, required this.product});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final size = MediaQuery.of(context).size;
    final padding = MediaQuery.of(context).padding;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Stack(
        children: [
          // 1. Hero Image spanning top portion
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: size.height * 0.45,
            child: product.imageUrl.isNotEmpty
              ? Image.network(
                  product.imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Image.asset(
                    'assets/images/pharmacist_patient2.jpg',
                    fit: BoxFit.cover,
                  ),
                )
              : Image.asset(
                  'assets/images/pharmacist_patient2.jpg',
                  fit: BoxFit.cover,
                ),
          ),
          
          // 2. Image Gradient Overlay
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: size.height * 0.45,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.4),
                    Colors.transparent,
                    AppTheme.backgroundColor.withValues(alpha: 0.4),
                    AppTheme.backgroundColor,
                  ],
                  stops: const [0.0, 0.4, 0.8, 1.0],
                ),
              ),
            ),
          ),

          // 3. Scrollable Content
          // THE FIX: Positioned.fill forces the ScrollView to respect the screen width, 
          // allowing the long description text to wrap correctly instead of overflowing.
          Positioned.fill(
            child: SafeArea(
              bottom: false, // Let the bottom bar handle its own safe area
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: Column(
                  children: [
                    // Transparent spacer matching image height
                    SizedBox(height: size.height * 0.35),
                    
                    // Pull-up detail sheet
                    Container(
                      width: double.infinity,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(28, 36, 28, 120), // Kept extra bottom padding so content isn't hidden by the floating bar
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Top indicator pill
                            Center(
                              child: Container(
                                width: 48,
                                height: 4,
                                decoration: BoxDecoration(
                                  color: AppTheme.borderColor,
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ),
                            const SizedBox(height: 32),
                            
                            // Title
                            Text(
                              product.name,
                              style: textTheme.displaySmall?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 16),
                            
                            // Price and Rating
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '₦${product.price.toStringAsFixed(0)}',
                                  style: textTheme.headlineMedium?.copyWith(
                                    color: AppTheme.textPrimaryColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Row(
                                  children: [
                                    const Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 20),
                                    const SizedBox(width: 4),
                                    Text(
                                      '4.8',
                                      style: textTheme.bodyMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    Text(
                                      ' (124 reviews)',
                                      style: textTheme.bodySmall,
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            
                            const SizedBox(height: 32),
                            
                            // Description
                            Text(
                              'Description',
                              style: textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 12),
                            // This is the text that caused the 199k pixel overflow. 
                            // It is now safely bounded by the Positioned.fill parent.
                            Text(
                              product.description.isNotEmpty 
                                ? product.description 
                                : 'No description available for this medication.',
                              style: textTheme.bodyMedium?.copyWith(
                                height: 1.6,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // 4. Custom Floating Back Button
          Positioned(
            top: padding.top + 16,
            left: 24,
            child: GestureDetector(
              onTap: () => Navigator.of(context).maybePop(),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: AppTheme.floatingShadow,
                ),
                child: const Icon(Icons.arrow_back, color: AppTheme.textPrimaryColor, size: 20),
              ),
            ),
          ),
          
          // 5. Floating Action Bar at the Bottom
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: EdgeInsets.fromLTRB(24, 16, 24, padding.bottom + 16),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: 20,
                    offset: const Offset(0, -10),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Quantity Selector
                  Container(
                    height: AppTheme.buttonHeight,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppTheme.borderColor),
                      borderRadius: BorderRadius.circular(AppTheme.buttonRadius),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.remove, size: 20, color: AppTheme.textSecondaryColor),
                        const SizedBox(width: 16),
                        Text('1', style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                        const SizedBox(width: 16),
                        const Icon(Icons.add, size: 20, color: AppTheme.primaryColor),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  
                  // Add to Cart Button
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        ref.read(cartProvider.notifier).addItem({
                          'id': product.id,
                          'name': product.name,
                          'price': product.price,
                          'imageUrl': product.imageUrl,
                          'pharmacyId': product.pharmacyId,
                          // Use a fallback for now, though ideally we'd pass pharmacyName here too
                          'pharmacyName': 'Verified Pharmacy', 
                        });
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('${product.name} added to cart!'),
                            backgroundColor: AppTheme.primaryColor,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        shadowColor: AppTheme.primaryGlow.first.color,
                        elevation: 8,
                      ),
                      child: const Text('Add to Cart'),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}