import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vail_meds_v2/core/services/health_service.dart';
import 'package:vail_meds_v2/core/theme.dart';
import 'package:vail_meds_v2/widgets/glass_app_bar.dart';
import 'package:vail_meds_v2/widgets/hover_card.dart';
import 'package:vail_meds_v2/core/widgets/shimmer_loading.dart';
import 'package:vail_meds_v2/core/providers.dart';
import 'package:url_launcher/url_launcher.dart';

class HealthNewsScreen extends ConsumerWidget {
  const HealthNewsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final healthNews = ref.watch(healthNewsProvider);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: GlassAppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimaryColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Health Intelligence',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimaryColor,
          ),
        ),
      ),
      body: healthNews.when(
        data: (articles) => CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Clinical Trends & News',
                      style: GoogleFonts.inter(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFF0F172A),
                        letterSpacing: -1,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Stay updated with the latest in medical technology and healthcare breakthroughs.',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: AppTheme.textSecondaryColor,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final article = articles[index];
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: _buildLargeNewsCard(context, article),
                    );
                  },
                  childCount: articles.length,
                ),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
        loading: () => ListView.builder(
          padding: const EdgeInsets.all(24),
          itemCount: 5,
          itemBuilder: (_, __) => const Padding(
            padding: EdgeInsets.only(bottom: 20),
            child: ShimmerEffect(width: double.infinity, height: 280, borderRadius: 24),
          ),
        ),
        error: (e, s) => Center(child: Text('Error: $e')),
      ),
    );
  }

  Widget _buildLargeNewsCard(BuildContext context, HealthArticle article) {
    return HoverCard(
      onTap: () => _launchUrl(article.url),
      borderRadius: BorderRadius.circular(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (article.imageUrl != null)
            ClipRRect(
              borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              child: Image.network(
                article.imageUrl!,
                height: 180,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  height: 180,
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  child: const Icon(Icons.broken_image, color: AppTheme.primaryColor),
                ),
              ),
            ),
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.timer_outlined, size: 14, color: AppTheme.primaryColor),
                    const SizedBox(width: 6),
                    Text(
                      article.publishedAt,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    const Spacer(),
                    const Icon(Icons.share_outlined, size: 18, color: AppTheme.textSecondaryColor),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  article.title,
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF0F172A),
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  article.description,
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    color: AppTheme.textSecondaryColor,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 16),
                const Row(
                  children: [
                    Text(
                      'Read Full Article',
                      style: TextStyle(
                        color: AppTheme.primaryColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(width: 8),
                    Icon(Icons.arrow_forward, size: 16, color: AppTheme.primaryColor),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}
