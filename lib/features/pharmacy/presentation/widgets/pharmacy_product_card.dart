import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../../core/theme.dart';
import '../../../../core/models/product_model.dart';
import '../../../../widgets/hover_card.dart';

class PharmacyProductCard extends ConsumerWidget {
  final Product product;
  final VoidCallback? onDelete;
  final VoidCallback? onEdit;

  const PharmacyProductCard({
    super.key,
    required this.product,
    this.onDelete,
    this.onEdit,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bool isLowStock = product.maxStock > 0 && (product.stockCount / product.maxStock) < 0.2;
    
    return HoverCard(
      borderRadius: BorderRadius.circular(16),
      liftAmount: -10,
      scaleAmount: 1.05,
      glowColor: isLowStock ? Colors.redAccent : AppTheme.primaryColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Image
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                    child: CachedNetworkImage(
                      imageUrl: product.imageUrl,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(color: Colors.grey.shade200),
                      errorWidget: (context, url, error) => const Icon(Icons.error),
                    ),
                  ),
                ),
                if (isLowStock)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.redAccent,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'LOW STOCK',
                        style: GoogleFonts.inter(
                          color: Colors.white,
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  product.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '₦${product.price.toStringAsFixed(0)}',
                      style: GoogleFonts.inter(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isLowStock ? Colors.red.withValues(alpha: 0.1) : Colors.green.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        '${product.stockCount} in stock',
                        style: GoogleFonts.inter(
                          color: isLowStock ? Colors.red : Colors.green.shade700,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
                if (onEdit != null || onDelete != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (onEdit != null)
                        IconButton(
                          icon: const Icon(Icons.edit_outlined, size: 18, color: AppTheme.textSecondaryColor),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: onEdit,
                        ),
                      if (onEdit != null && onDelete != null) const SizedBox(width: 8),
                      if (onDelete != null)
                        IconButton(
                          icon: const Icon(Icons.delete_outline, size: 18, color: Colors.redAccent),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: onDelete,
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
