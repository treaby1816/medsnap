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

                        return GestureDetector(
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => ProductScreen(product: product))),
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

            // Featured Pharmacies Carousel
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
                        autoPlay: false, // Stopped "rolling" as requested
                      ),
                      items: verifiedPharmacies.map((ph) {
                        return _buildPharmacyCard(context, ph);
                      }).toList(),
                    ),
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
