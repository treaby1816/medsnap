import 'package:flutter/material.dart';
import 'package:vail_meds_v2/core/services/health_service.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers.dart';
import '../../../../core/theme.dart';
import 'product_screen.dart';
import '../../../../core/models/user_profile.dart';
import '../../../../core/widgets/shimmer_loading.dart';
import '../../../../widgets/hover_card.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final textTheme = Theme.of(context).textTheme;
    final userProfile = ref.watch(userProfileProvider).value;
    final verifiedPharmacies = ref.watch(verifiedPharmaciesProvider).value ?? [];
    final nearbyPharmaciesAsync = ref.watch(nearbyPharmaciesProvider);
    final cartItems = ref.watch(cartProvider);
    final healthNews = ref.watch(healthNewsProvider);
    final allProducts = ref.watch(allProductsProvider);
    final filteredProducts = ref.watch(filteredByBrandProductsProvider);
    // final searchQuery = ref.watch(drugSearchQueryProvider);
    final selectedCategory = ref.watch(selectedCategoryProvider);
    
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
                        GestureDetector(
                          onTap: () => Navigator.pushNamed(context, '/profile'),
                          child: Text(
                            displayName,
                            style: textTheme.headlineMedium
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        // Profile Icon
                        IconButton(
                          icon: const Icon(Icons.person_outline, color: AppTheme.primaryColor),
                          onPressed: () => Navigator.pushNamed(context, '/profile'),
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
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: AppTheme.floatingShadow,
                  ),
                  child: TextField(
                    onChanged: (val) => ref.read(drugSearchQueryProvider.notifier).state = val,
                    decoration: InputDecoration(
                      hintText: 'Search medications, pharmacies...',
                      hintStyle: TextStyle(color: AppTheme.textSecondaryColor.withValues(alpha: 0.5)),
                      prefixIcon: const Icon(Icons.search, color: AppTheme.primaryColor),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                    ),
                  ),
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 32)),

            // Categories
            SliverToBoxAdapter(
              child: SizedBox(
                height: 48,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  children: [
                    _buildCategoryPill(context, ref, 'All', selectedCategory == 'All'),
                    const SizedBox(width: 12),
                    _buildCategoryPill(context, ref, 'Antibiotics', selectedCategory == 'Antibiotics'),
                    const SizedBox(width: 12),
                    _buildCategoryPill(context, ref, 'Painkillers', selectedCategory == 'Painkillers'),
                    const SizedBox(width: 12),
                    _buildCategoryPill(context, ref, 'Vitamins', selectedCategory == 'Vitamins'),
                  ],
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 32)),

            // Marketplace Section
            allProducts.when(
              data: (products) {
                final displayProducts = filteredProducts.isNotEmpty ? filteredProducts : products;
                if (displayProducts.isEmpty) {
                  return const SliverToBoxAdapter(
                    child: Center(child: Padding(padding: EdgeInsets.all(32), child: Text('No drugs found in this category.'))),
                  );
                }
                return SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  sliver: SliverGrid(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      mainAxisSpacing: 16,
                      crossAxisSpacing: 16,
                      childAspectRatio: 0.75,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final product = displayProducts[index];
                        final pharmacyName = verifiedPharmacies.firstWhere(
                          (p) => p.uid == product.pharmacyId,
                          orElse: () => UserProfile(uid: product.pharmacyId, email: '', name: 'Pharmacy', role: 'pharmacy'),
                        ).displayName ?? 'Verified Pharmacy';

                        return HoverCard(
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProductScreen(product: product))),
                          borderRadius: BorderRadius.circular(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: ClipRRect(
                                  borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                                  child: Image.network(
                                    product.imageUrl.isNotEmpty ? product.imageUrl : 'https://images.unsplash.com/photo-1587854692152-cbe660dbbb88?q=80&w=400',
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    errorBuilder: (context, error, stackTrace) => Container(color: Colors.grey[100], child: const Icon(Icons.medication, color: AppTheme.primaryColor)),
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.all(12),
                                child: SizedBox(
                                  height: 70,
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
                        );
                      },
                      childCount: displayProducts.length,
                    ),
                  ),
                );
              },
              loading: () => SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2, mainAxisSpacing: 16, crossAxisSpacing: 16, childAspectRatio: 0.75,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (_, __) => const ShimmerEffect(width: double.infinity, height: 200, borderRadius: 20),
                    childCount: 4,
                  ),
                ),
              ),
              error: (_, __) => const SliverToBoxAdapter(
                child: Center(child: Padding(padding: EdgeInsets.all(32), child: Text('Could not load marketplace.'))),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 32)),

            // Prescription Scanning
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: HoverCard(
                  onTap: () => Navigator.pushNamed(context, '/scan'),
                  borderRadius: BorderRadius.circular(24),
                  glowColor: AppTheme.primaryColor,
                  child: Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppTheme.primaryColor, Color(0xFFF97316)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
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

            // Dynamic Nearby Pharmacies Carousel
            SliverToBoxAdapter(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Top Nearby Pharmacies', style: textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                        const Icon(Icons.my_location, color: AppTheme.primaryColor, size: 18),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  nearbyPharmaciesAsync.when(
                    data: (pharmacies) {
                      if (pharmacies.isEmpty) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 24),
                          child: Text("Finding nearby verified pharmacies...", style: TextStyle(fontSize: 12)),
                        );
                      }
                      return CarouselSlider(
                        options: CarouselOptions(
                          height: 220,
                          viewportFraction: 0.75,
                          enableInfiniteScroll: pharmacies.length > 2,
                          enlargeCenterPage: true,
                          autoPlay: true,
                          autoPlayInterval: const Duration(seconds: 4),
                          autoPlayAnimationDuration: const Duration(milliseconds: 800),
                        ),
                        items: pharmacies.map((data) => _buildNearbyPharmacyCard(context, data)).toList(),
                      );
                    },
                    loading: () => CarouselSlider(
                      options: CarouselOptions(height: 220, viewportFraction: 0.75, enlargeCenterPage: true),
                      items: List.generate(3, (i) => const ShimmerEffect(width: double.infinity, height: 220, borderRadius: 24)).toList(),
                    ),
                    error: (e, s) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Text('Could not calculate nearby locations: $e', style: const TextStyle(color: Colors.red, fontSize: 12)),
                    ),
                  )
                ],
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 32)),

            // Sponsored Jobs Section
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
                    HoverCard(
                      onTap: () => Navigator.pushNamed(context, '/nearby'),
                      borderRadius: BorderRadius.circular(20),
                      child: Container(
                        height: 160,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(20),
                          image: const DecorationImage(
                            image: NetworkImage('https://images.unsplash.com/photo-1549463595-654db9756184?q=80&w=600&auto=format&fit=crop'),
                            fit: BoxFit.cover,
                          ),
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

            // Health Insights
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
                      loading: () => Column(
                        children: List.generate(3, (i) => const Padding(
                          padding: EdgeInsets.only(bottom: 16),
                          child: ShimmerEffect(width: double.infinity, height: 110, borderRadius: 16),
                        )),
                      ),
                      error: (e, s) => Text('Failed to load health news: $e'),
                    ),
                  ],
                ),
              ),
            ),

            const SliverToBoxAdapter(child: SizedBox(height: 120)),
          ],
        ),
      ),
    );
  }

  Widget _buildNewsCard(BuildContext context, HealthArticle article) {
    return HoverCard(
      borderRadius: BorderRadius.circular(16),
      padding: const EdgeInsets.all(16),
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
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  maxLines: 1, 
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  article.description, 
                  maxLines: 2, 
                  overflow: TextOverflow.ellipsis, 
                  style: const TextStyle(fontSize: 11, color: AppTheme.textSecondaryColor),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNearbyPharmacyCard(BuildContext context, Map<String, dynamic> data) {
    final UserProfile ph = data['profile'];
    final double distanceKm = data['distanceKm'];
    final int estimatedMinutes = data['estimatedMinutes'];
    
    // Dynamic fallback image if storefront is missing
    const String defaultStoreFront = 'https://images.unsplash.com/photo-1576602976047-174e57a47881?q=80&w=600&auto=format&fit=crop';
    final String imageToUse = (ph.storeFrontImageUrl != null && ph.storeFrontImageUrl!.isNotEmpty)
        ? ph.storeFrontImageUrl!
        : defaultStoreFront;

    return HoverCard(
      onTap: () => Navigator.pushNamed(
        context, 
        '/chat', 
        arguments: {
          'receiverId': ph.uid,
          'receiverName': ph.displayName ?? ph.storeName ?? 'Pharmacy',
        },
      ),
      borderRadius: BorderRadius.circular(24),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 0.0), // Margin handled by Carousel
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          image: DecorationImage(
            image: NetworkImage(imageToUse),
            fit: BoxFit.cover,
            colorFilter: ColorFilter.mode(Colors.black.withValues(alpha: 0.3), BlendMode.darken),
          ),
        ),
        child: Stack(
          children: [
            // Verified Badge
            Positioned(
              top: 16,
              right: 16,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.verified, color: Colors.blue, size: 14),
                    const SizedBox(width: 4),
                    Text('Verified', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.bold, color: AppTheme.textPrimaryColor)),
                  ],
                ),
              ),
            ),
            
            // Bottom Glassmorphic Panel
            Positioned(
              bottom: 12,
              left: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ph.displayName ?? ph.storeName ?? 'Pharmacy', 
                      style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.bold, color: AppTheme.textPrimaryColor),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.location_on, color: AppTheme.primaryColor, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          '${distanceKm.toStringAsFixed(1)} km away',
                          style: GoogleFonts.inter(fontSize: 12, color: AppTheme.primaryColor, fontWeight: FontWeight.w600),
                        ),
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 6),
                          width: 4, height: 4,
                          decoration: const BoxDecoration(color: AppTheme.textSecondaryColor, shape: BoxShape.circle),
                        ),
                        const Icon(Icons.directions_car, color: AppTheme.textSecondaryColor, size: 14),
                        const SizedBox(width: 4),
                        Text(
                          '$estimatedMinutes min drive',
                          style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondaryColor, fontWeight: FontWeight.w500),
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
  }

  Widget _buildCategoryPill(BuildContext context, WidgetRef ref, String label, bool isSelected) {
    return GestureDetector(
      onTap: () => ref.read(selectedCategoryProvider.notifier).state = label,
      child: Container(
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
      ),
    );
  }

}
