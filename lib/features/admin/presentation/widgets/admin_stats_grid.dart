import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme.dart';
import '../../../../core/providers/admin_providers.dart';
import '../../../../widgets/hover_card.dart';

class AdminStatsGrid extends ConsumerWidget {
  final Function(int)? onCardTap;

  const AdminStatsGrid({super.key, this.onCardTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(adminStatsProvider);

    return statsAsync.when(
      data: (stats) => LayoutBuilder(
        builder: (context, constraints) {
          final cardWidth = constraints.maxWidth < 600 
            ? ((constraints.maxWidth - 16) / 2) - 1 // 2 columns for mobile
            : ((constraints.maxWidth - 48) / 4) - 1; // 4 columns for desktop
            
          return Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              _StatCard(
                width: constraints.maxWidth < 400 ? constraints.maxWidth : cardWidth, // 1 column for very small
                icon: Icons.person_rounded,
                gradient: const [Color(0xFF3B82F6), Color(0xFF2563EB)],
                label: 'Total Patients',
                value: _formatNumber(stats.totalPatients),
                badge: 'STABLE',
                badgeColor: const Color(0xFF3B82F6),
                onTap: () => onCardTap?.call(4),
              ),
              _StatCard(
                width: cardWidth < 180 ? constraints.maxWidth / 2 - 8 : cardWidth,
                icon: Icons.storefront_rounded,
                gradient: const [AppTheme.primaryColor, Color(0xFFFF8C42)],
                label: 'Active Pharmacies',
                value: _formatNumber(stats.activePharmacies),
                badge: 'REALTIME',
                badgeColor: const Color(0xFF22C55E),
                onTap: () => onCardTap?.call(1),
              ),
              _StatCard(
                width: cardWidth < 180 ? constraints.maxWidth / 2 - 8 : cardWidth,
                icon: Icons.verified_user_outlined,
                gradient: const [Color(0xFFF59E0B), Color(0xFFD97706)],
                label: 'Pending Verifications',
                value: stats.pendingVerifications.toString(),
                badge: stats.pendingVerifications > 0 ? 'URGENT' : 'STABLE',
                badgeColor: const Color(0xFFF59E0B),
                onTap: () => onCardTap?.call(1),
              ),
              _StatCard(
                width: cardWidth < 180 ? constraints.maxWidth / 2 - 8 : cardWidth,
                icon: Icons.support_agent_rounded,
                gradient: const [Color(0xFFEF4444), Color(0xFFDC2626)],
                label: 'Support Tickets',
                value: stats.supportTickets.toString(),
                badge: stats.supportTickets > 0 ? '${stats.supportTickets} OPEN' : 'ALL CLEAR',
                badgeColor: stats.supportTickets > 0 ? const Color(0xFFEF4444) : const Color(0xFF22C55E),
                onTap: () => onCardTap?.call(5),
              ),
            ],
          );
        },
      ),
      loading: () => const SizedBox(
        height: 140,
        child: Center(child: CircularProgressIndicator(color: AppTheme.primaryColor, strokeWidth: 2)),
      ),
      error: (e, _) => Text('Error loading stats: $e'),
    );
  }

  String _formatNumber(int n) {
    if (n >= 1000000000) {
      return '${(n / 1000000000).toStringAsFixed(1)}B';
    } else if (n >= 1000000) {
      return '${(n / 1000000).toStringAsFixed(1)}M';
    } else if (n >= 1000) {
      return '${(n / 1000).toStringAsFixed(n % 1000 == 0 ? 0 : 1)}k';
    }
    return n.toString();
  }
}

class _StatCard extends StatefulWidget {
  final double width;
  final IconData icon;
  final List<Color> gradient;
  final String label;
  final String value;
  final String badge;
  final Color badgeColor;
  final VoidCallback? onTap;

  const _StatCard({
    required this.width,
    required this.icon,
    required this.gradient,
    required this.label,
    required this.value,
    required this.badge,
    required this.badgeColor,
    this.onTap,
  });

  @override
  State<_StatCard> createState() => _StatCardState();
}

class _StatCardState extends State<_StatCard> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return HoverCard(
      onTap: widget.onTap,
      borderRadius: BorderRadius.circular(24),
      padding: const EdgeInsets.all(28),
      child: SizedBox(
        width: widget.width - 56, // Adjusted for HoverCard padding
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Status Orb & Icon
                Stack(
                  alignment: Alignment.center,
                  children: [
                    ScaleTransition(
                      scale: Tween(begin: 1.0, end: 1.4).animate(
                        CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
                      ),
                      child: Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: widget.badgeColor.withValues(alpha: 0.15),
                        ),
                      ),
                    ),
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: widget.badgeColor,
                        boxShadow: [
                          BoxShadow(
                            color: widget.badgeColor.withValues(alpha: 0.6),
                            blurRadius: 8,
                          )
                        ],
                      ),
                    ),
                  ],
                ),
                
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppTheme.backgroundColor,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppTheme.borderColor.withValues(alpha: 0.5)),
                  ),
                  child: Text(
                    widget.badge,
                    style: GoogleFonts.outfit(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: widget.badgeColor,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Icon(widget.icon, size: 16, color: AppTheme.textSecondaryColor),
                const SizedBox(width: 8),
                Text(
                  widget.label,
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    color: AppTheme.textSecondaryColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              widget.value,
              style: GoogleFonts.outfit(
                fontSize: 34,
                fontWeight: FontWeight.w800,
                color: AppTheme.textPrimaryColor,
                letterSpacing: -1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
