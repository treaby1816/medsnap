import 'package:flutter/material.dart';
import 'package:vail_meds_v2/core/services/health_service.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme.dart';
import '../../../../core/models/product_model.dart';
import 'product_screen.dart';
import '../../../../core/models/user_profile.dart';
import '../../../../core/providers.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final userProfile = ref.watch(userProfileProvider).value;
    final verifiedPharmacies = ref.watch(verifiedPharmaciesProvider).value ?? [];
    final cartItems = ref.watch(cartProvider);
    final healthNews = ref.watch(healthNewsProvider);
    final allProducts = ref.watch(allProductsProvider);
    final searchProducts = ref.watch(filteredDrugsProvider);
    final searchQuery = ref.watch(drugSearchQueryProvider);
    
    final displayName = userProfile?.displayName ?? 
                      (userProfile?.email.split('@')[0] ?? 'User');

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: SafeArea(
        child: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            // Floating Header
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Good Morning,',
                          style: textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          displayName,
                          style: textTheme.headlineMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        // Pharmacy Chat Icon
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.chat_bubble_outline, color: AppTheme.primaryColor),
                              onPressed: () => _showPharmacySelection(context, ref, verifiedPharmacies),
                            ),
                            if (verifiedPharmacies.isNotEmpty)
                              Positioned(
                                right: 8,
                                top: 8,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                                  child: Text(
                                    '${verifiedPharmacies.length}',
                                    style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        // Cart Icon
                        Stack(
                          clipBehavior: Clip.none,
                          children: [
                            IconButton(
                              icon: const Icon(Icons.shopping_cart_outlined, color: AppTheme.textPrimaryColor),
                              onPressed: () => Navigator.pushNamed(context, '/checkout'),
                            ),
                            if (cartItems.isNotEmpty)
                              Positioned(
                                right: 8,
                                top: 8,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: const BoxDecoration(color: AppTheme.primaryColor, shape: BoxShape.circle),
                                  child: Text(
                                    '${cartItems.length}',
                                    style: const TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(width: 8),
                        CircleAvatar(
                          radius: 20,
                          backgroundImage: NetworkImage(userProfile?.photoUrl ?? 'https://ui-avatars.com/api/?name=$displayName'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),

            // Search Bar
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: AppTheme.floatingShadow,
                  ),
                    child: TextField(
                      onChanged: (value) => ref.read(drugSearchQueryProvider.notifier).state = value,
                      decoration: InputDecoration(
                        hintText: 'Search medications, pharmacies...',
                        prefixIcon: const Icon(Icons.search, color: AppTheme.textSecondaryColor),
                        suffixIcon: searchQuery.isNotEmpty 
                          ? IconButton(icon: const Icon(Icons.clear), onPressed: () => ref.read(drugSearchQueryProvider.notifier).state = '')
                          : const Icon(Icons.tune, color: AppTheme.primaryColor, size: 20),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                        fillColor: Colors.white,
                        filled: true,
                      ),
                    ),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 24)),

            // Sponsored Ads Carousel
            SliverToBoxAdapter(
              child: CarouselSlider(
                options: CarouselOptions(
                  height: 160,
                  viewportFraction: 0.85,
                  enlargeCenterPage: true,
                  autoPlay: true,
                ),
                items: [1, 2, 3].map((i) {
                  return Builder(
                    builder: (BuildContext context) {
                      return Container(
                        width: MediaQuery.of(context).size.width,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          gradient: const LinearGradient(
                            colors: [AppTheme.primaryColor, Color(0xFFFF9A5C)],
                          ),
                        ),
                        child: Stack(
                          children: [
                            Positioned(
                              right: -20,
                              bottom: -20,
                              child: Icon(Icons.medication, size: 150, color: Colors.white.withValues(alpha: 0.1)),
                            ),
                            Padding(
                              padding: const EdgeInsets.all(24),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(8)),
                                    child: Text('SPONSORED', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.white)),
                                  ),
                                  const SizedBox(height: 12),
                                  Text('Get 20% off on all\nsupplements this week!', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  );
                }).toList(),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 32)),

            // Categories
            SliverToBoxAdapter(
              child: SizedBox(
                height: 44,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  children: [
                    _buildCategoryPill('All Products', true),
                    const SizedBox(width: 12),
                    _buildCategoryPill('Supplements', false),
                    const SizedBox(width: 12),
                    _buildCategoryPill('Pain Relief', false),
                    const SizedBox(width: 12),
                    _buildCategoryPill('Cold & Flu', false),
                  ],
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 24)),

            // --- LIVE MARKETPLACE PRODUCT GRID ---
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Marketplace', style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    const Icon(Icons.storefront, color: AppTheme.primaryColor, size: 20),
                  ],
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 12)),
            allProducts.when(
              data: (products) {
                // If a search query is active, show filtered results instead
                final displayProducts = searchQuery.isNotEmpty ? searchProducts : products;
                
                if (displayProducts.isEmpty) {
                  return SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                      child: Container(
                        padding: const EdgeInsets.all(32),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withValues(alpha: 0.05),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.1)),
                        ),
                        child: Column(
                          children: [
                            Icon(Icons.inventory_2_outlined, size: 48, color: AppTheme.primaryColor.withValues(alpha: 0.4)),
                            const SizedBox(height: 16),
                            Text(
                              searchQuery.isNotEmpty 
                                ? 'No results for "$searchQuery"' 
                                : 'Marketplace is being stocked',
                              style: textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              searchQuery.isNotEmpty 
                                ? 'Try a different search term.' 
                                : 'Verified pharmacies will list their inventory here soon. Check back shortly!',
                              style: textTheme.bodySmall?.copyWith(color: AppTheme.textSecondaryColor),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }
                
                return SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 0.72,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final product = displayProducts[index];
                        // Find the source pharmacy name
                        final pharmacyName = verifiedPharmacies
                            .where((p) => p.uid == product.pharmacyId)
                            .map((p) => p.displayName ?? p.name)
                            .firstOrNull ?? 'Verified Pharmacy';
                        
                        return GestureDetector(
                          onTap: () => Navigator.pushNamed(context, '/product', arguments: product),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2))],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // Product Image
                                Expanded(
                                  flex: 3,
                                  child: ClipRRect(
                                    borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
                                    child: product.imageUrl.isNotEmpty
                                      ? Image.network(product.imageUrl, width: double.infinity, fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) => Container(
                                            color: AppTheme.primaryColor.withValues(alpha: 0.1),
                                            child: const Center(child: Icon(Icons.medication, color: AppTheme.primaryColor, size: 32)),
                                          ),
                                        )
                                      : Container(
                                          color: AppTheme.primaryColor.withValues(alpha: 0.1),
                                          child: const Center(child: Icon(Icons.medication, color: AppTheme.primaryColor, size: 32)),
                                        ),
                                  ),
                                ),
                                // Product Info
                                Expanded(
                                  flex: 2,
                                  child: Padding(
                                    padding: const EdgeInsets.all(10),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(product.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13), maxLines: 1, overflow: TextOverflow.ellipsis),
                                        Row(
                                          children: [
                                            const Icon(Icons.storefront, size: 10, color: AppTheme.primaryColor),
                                            const SizedBox(width: 4),
                                            Expanded(child: Text(pharmacyName, style: const TextStyle(fontSize: 10, color: AppTheme.primaryColor), maxLines: 1, overflow: TextOverflow.ellipsis)),
                                          ],
                                        ),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text('\u20a6${product.price.toStringAsFixed(0)}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppTheme.textPrimaryColor)),
                                            GestureDetector(
                                              onTap: () {
                                                ref.read(cartProvider.notifier).addItem({
                                                  'id': product.id,
                                                  'name': product.name,
                                                  'price': product.price,
                                                  'imageUrl': product.imageUrl,
                                                  'pharmacyId': product.pharmacyId,
                                                  'pharmacyName': pharmacyName,
                                                });
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  SnackBar(content: Text('${product.name} added to cart!'), backgroundColor: AppTheme.primaryColor, behavior: SnackBarBehavior.floating, duration: const Duration(seconds: 1)),
                                                );
                                              },
                                              child: Container(
                                                padding: const EdgeInsets.all(6),
                                                decoration: BoxDecoration(color: AppTheme.primaryColor, borderRadius: BorderRadius.circular(8)),
                                                child: const Icon(Icons.add, color: Colors.white, size: 14),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        );
                      },
                      childCount: displayProducts.length,
                    ),
                  ),
                );
              },
              loading: () => const SliverToBoxAdapter(
                child: Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator(color: AppTheme.primaryColor))),
              ),
              error: (_, __) => const SliverToBoxAdapter(
                child: Center(child: Padding(padding: EdgeInsets.all(32), child: Text('Could not load marketplace.'))),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 32)),

            // Prescription Scanning (Request Restored)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: GestureDetector(
                  onTap: () => Navigator.pushNamed(context, '/scan'),
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppTheme.primaryColor, Color(0xFFF97316)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                      boxShadow: AppTheme.primaryGlow,
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.camera_alt, color: Colors.white, size: 28),
                        ),
                        const SizedBox(width: 20),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Scan Prescription',
                                style: GoogleFonts.inter(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                              Text(
                                'Upload or take a photo to order drugs',
                                style: GoogleFonts.inter(
                                  color: Colors.white.withValues(alpha: 0.9),
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.arrow_forward_ios, color: Colors.white, size: 16),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 32)),

            // Verified Pharmacies Carousel (New Request)
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Featured Pharmacies', style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                        const Icon(Icons.verified, color: Colors.blue, size: 18),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (verifiedPharmacies.isEmpty)
                    const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 24),
                      child: Text("Finding verified pharmacies...", style: TextStyle(fontSize: 12)),
                    )
                  else
                    CarouselSlider(
                      options: CarouselOptions(
                        height: 120,
                        viewportFraction: 0.4,
                        enableInfiniteScroll: verifiedPharmacies.length > 2,
                        enlargeCenterPage: true,
                        autoPlay: true,
                      ),
                      items: verifiedPharmacies.map((ph) {
                        return _buildPharmacyCard(context, ph);
                      }).toList(),
                    ),
                ],
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 32)),

            // Sponsored Jobs Section (New Request)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.1)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: AppTheme.primaryColor.withValues(alpha: 0.1), shape: BoxShape.circle),
                        child: const Icon(Icons.work_outline, color: AppTheme.primaryColor),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Medical Job Openings', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16)),
                            Text('View 12+ active roles in your area', style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondaryColor)),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: () => Navigator.pushNamed(context, '/job-board'),
                        child: const Text('Explore'),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 32)),

            // Nearby Facilities Sliver
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Nearby Facilities', style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    const SizedBox(height: 16),
                    GestureDetector(
                      onTap: () => Navigator.pushNamed(context, '/nearby'),
                      child: Container(
                        height: 160,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          image: const DecorationImage(
                            image: NetworkImage('https://images.unsplash.com/photo-1549463595-654db9756184?q=80&w=600&auto=format&fit=crop'),
                            fit: BoxFit.cover,
                          ),
                          boxShadow: [
                            BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 10, offset: const Offset(0, 4)),
                          ],
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(20),
                            gradient: LinearGradient(
                              begin: Alignment.bottomCenter,
                              end: Alignment.topCenter,
                              colors: [Colors.black.withValues(alpha: 0.6), Colors.transparent],
                            ),
                          ),
                          padding: const EdgeInsets.all(16),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text('Vail Village Pharmacy', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                                  Text('0.8 miles away • Open until 9 PM', style: TextStyle(color: Colors.white70, fontSize: 12)),
                                ],
                              ),
                              Icon(Icons.directions, color: Colors.white),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 32)),

            // Real-time Health Insights
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Real-time Health Insights', style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                        const Icon(Icons.bolt, color: Colors.amber, size: 20),
                      ],
                    ),
                    const SizedBox(height: 16),
                    healthNews.when(
                      data: (articles) => Column(
                        children: articles.take(3).map((article) => _buildNewsCard(context, article)).toList(),
                      ),
                      loading: () => const Center(child: CircularProgressIndicator()),
                      error: (e, s) => Text('Failed to load health news: $e'),
                    ),
                  ],
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 32)),

            // Marketplace Heading
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Text('Marketplace Deals', style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 16)),

            // Product Grid or Search Results
            if (searchQuery.isNotEmpty)
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                sliver: searchProducts.isEmpty 
                  ? const SliverToBoxAdapter(child: Center(child: Text('No drugs found.')))
                  : SliverGrid(
                      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        childAspectRatio: 1.15,
                      ),
                      delegate: SliverChildBuilderDelegate(
                        (context, index) => _buildProductCard(context, ref, searchProducts[index], verifiedPharmacies),
                        childCount: searchProducts.length,
                      ),
                    ),
              )
            else
              allProducts.when(
                data: (products) => SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  sliver: products.isEmpty 
                    ? const SliverToBoxAdapter(child: Center(child: Text('No products available right now.')))
                    : SliverGrid(
                        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                          childAspectRatio: 1.15,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) => _buildProductCard(context, ref, products[index], verifiedPharmacies),
                          childCount: products.length,
                        ),
                      ),
                ),
                loading: () => const SliverToBoxAdapter(child: Center(child: CircularProgressIndicator())),
                error: (e, s) => SliverToBoxAdapter(child: Center(child: Text('Error: $e'))),
              ),

            const SliverToBoxAdapter(child: SizedBox(height: 120)),
          ],
        ),
      ),
    );
  }

  Widget _buildNewsCard(BuildContext context, HealthArticle article) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.05)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.02), blurRadius: 10, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          if (article.imageUrl != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                article.imageUrl!, 
                width: 80, 
                height: 80, 
                fit: BoxFit.cover,
                loadingBuilder: (context, child, loadingProgress) {
                  if (loadingProgress == null) return child;
                  return Container(
                    width: 80,
                    height: 80,
                    color: Colors.grey[100],
                    child: const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
                  );
                },
                errorBuilder: (context, error, stackTrace) => Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(color: AppTheme.primaryColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.broken_image_outlined, color: AppTheme.primaryColor, size: 24),
                ),
              ),
            )
          else
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(color: AppTheme.primaryColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.article, color: AppTheme.primaryColor),
            ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(article.publishedAt, style: const TextStyle(fontSize: 10, color: AppTheme.primaryColor, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(
                  article.title, 
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13), // Slightly smaller font
                  maxLines: 1, 
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  article.description, 
                  maxLines: 2, 
                  overflow: TextOverflow.ellipsis, 
                  style: const TextStyle(fontSize: 11, color: AppTheme.textSecondaryColor), // Slightly smaller font
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPharmacyCard(BuildContext context, UserProfile ph) {
    return GestureDetector(
      onTap: () => Navigator.pushNamed(context, '/chat', arguments: ph.uid),
      child: Column(
        children: [
          Stack(
            children: [
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.2), width: 2),
                  image: DecorationImage(
                    image: NetworkImage(ph.photoUrl ?? 'https://ui-avatars.com/api/?name=${ph.displayName}'),
                    fit: BoxFit.cover,
                  ),
                ),
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(color: Colors.blue, shape: BoxShape.circle),
                  child: const Icon(Icons.verified, size: 10, color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(ph.displayName ?? 'Pharmacy', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildCategoryPill(String label, bool isSelected) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: isSelected ? AppTheme.primaryColor : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: isSelected ? AppTheme.primaryGlow : AppTheme.floatingShadow,
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: TextStyle(
          color: isSelected ? Colors.white : AppTheme.textSecondaryColor,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
          fontSize: 14,
        ),
      ),
    );
  }

  Widget _buildProductCard(BuildContext context, WidgetRef ref, Product product, List<UserProfile> pharmacies) {
    final textTheme = Theme.of(context).textTheme;
    
    // Find the pharmacy for this product to get the name
    final pharmacy = pharmacies.firstWhere(
      (p) => p.uid == product.pharmacyId,
      orElse: () => UserProfile(uid: product.pharmacyId, email: '', name: 'Verified Pharmacy', displayName: 'Verified Pharmacy', role: 'pharmacy'),
    );

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductScreen(product: product),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: AppTheme.floatingShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                child: product.imageUrl.isNotEmpty
                  ? Image.network(
                      product.imageUrl,
                      fit: BoxFit.cover,
                      width: double.infinity,
                      errorBuilder: (context, error, stackTrace) => Image.asset(
                        'assets/images/pharmacist_patient2.jpg',
                        fit: BoxFit.cover,
                        width: double.infinity,
                      ),
                    )
                  : Image.asset(
                      'assets/images/pharmacist_patient2.jpg',
                      fit: BoxFit.cover,
                      width: double.infinity,
                    ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    product.name,
                    style: textTheme.bodyMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimaryColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.store, size: 12, color: AppTheme.primaryColor),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          pharmacy.displayName ?? 'Verified Pharmacy',
                          style: textTheme.bodySmall?.copyWith(
                            color: AppTheme.textTertiaryColor,
                            fontSize: 10,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '₦${product.price.toStringAsFixed(0)}',
                        style: textTheme.titleMedium?.copyWith(
                          color: AppTheme.primaryColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      GestureDetector(
                        onTap: () {
                          ref.read(cartProvider.notifier).addItem({
                            'id': product.id,
                            'name': product.name,
                            'price': product.price,
                            'imageUrl': product.imageUrl,
                            'pharmacyId': product.pharmacyId,
                            'pharmacyName': pharmacy.displayName,
                          });
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('${product.name} added to cart!'),
                              backgroundColor: AppTheme.primaryColor,
                              duration: const Duration(seconds: 1),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.add,
                            size: 16,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ),
                    ],
                  )
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showPharmacySelection(BuildContext context, WidgetRef ref, List<UserProfile> pharmacies) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Quick Chat with Pharmacy', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text('${pharmacies.length} verified pharmacies online', style: GoogleFonts.inter(color: AppTheme.textSecondaryColor)),
            const SizedBox(height: 16),
            if (pharmacies.isEmpty)
              const Center(child: Padding(padding: EdgeInsets.all(20), child: Text("No pharmacies online right now.")))
            else
              ConstrainedBox(
                constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.4),
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: pharmacies.length,
                  itemBuilder: (context, index) {
                    final ph = pharmacies[index];
                    return ListTile(
                      leading: CircleAvatar(backgroundImage: NetworkImage(ph.photoUrl ?? 'https://ui-avatars.com/api/?name=${ph.displayName}')),
                      title: Text(ph.displayName ?? 'Pharmacy'),
                      subtitle: const Text('Online • Swift Reply'),
                      trailing: ElevatedButton(
                        onPressed: () => Navigator.pushNamed(context, '/chat', arguments: ph.uid),
                        child: const Text('Chat'),
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}