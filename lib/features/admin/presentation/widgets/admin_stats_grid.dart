import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme.dart';
import '../../../../core/providers/admin_providers.dart';

class AdminStatsGrid extends ConsumerWidget {
  final Function(int)? onCardTap;

  const AdminStatsGrid({super.key, this.onCardTap});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statsAsync = ref.watch(adminStatsProvider);

    return statsAsync.when(
      data: (stats) => LayoutBuilder(
        builder: (context, constraints) {
          final cardWidth = (constraints.maxWidth - 48) / 4; // 3 gaps × 16
          return Wrap(
            spacing: 16,
            runSpacing: 16,
            children: [
              _StatCard(
                width: cardWidth < 180 ? constraints.maxWidth / 2 - 8 : cardWidth,
                icon: Icons.person_rounded,
                iconBg: const Color(0xFF3B82F6),
                label: 'Total Patients',
                value: _formatNumber(stats.totalPatients),
                badge: '+12%',
                badgeColor: const Color(0xFF3B82F6),
                onTap: () => onCardTap?.call(4), // Staff/Patients stub
              ),
              _StatCard(
                width: cardWidth < 180 ? constraints.maxWidth / 2 - 8 : cardWidth,
                icon: Icons.storefront_rounded,
                iconBg: AppTheme.primaryColor,
                label: 'Active Pharmacies',
                value: _formatNumber(stats.activePharmacies),
                badge: 'ACTIVE',
                badgeColor: const Color(0xFF22C55E),
                onTap: () => onCardTap?.call(1), // Approvals/Directory
              ),
              _StatCard(
                width: cardWidth < 180 ? constraints.maxWidth / 2 - 8 : cardWidth,
                icon: Icons.verified_user_outlined,
                iconBg: const Color(0xFFF59E0B),
                label: 'Pending Verifications',
                value: stats.pendingVerifications.toString(),
                badge: 'URGENT',
                badgeColor: const Color(0xFFF59E0B),
                onTap: () => onCardTap?.call(1), // Approvals
              ),
              _StatCard(
                width: cardWidth < 180 ? constraints.maxWidth / 2 - 8 : cardWidth,
                icon: Icons.support_agent_rounded,
                iconBg: const Color(0xFFEF4444),
                label: 'Support Tickets',
                value: stats.supportTickets.toString(),
                badge: stats.supportTickets > 0 ? '${stats.supportTickets} OPEN' : 'ALL CLEAR',
                badgeColor: stats.supportTickets > 0 ? const Color(0xFFEF4444) : const Color(0xFF22C55E),
                onTap: () => onCardTap?.call(5), // Support module
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
    if (n >= 1000) {
      return '${(n / 1000).toStringAsFixed(n % 1000 == 0 ? 0 : 1)}k';
    }
    return n.toString();
  }
}

class _StatCard extends StatelessWidget {
  final double width;
  final IconData icon;
  final Color iconBg;
  final String label;
  final String value;
  final String badge;
  final Color badgeColor;
  final VoidCallback? onTap;

  const _StatCard({
    required this.width,
    required this.icon,
    required this.iconBg,
    required this.label,
    required this.value,
    required this.badge,
    required this.badgeColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: width,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppTheme.borderColor),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: iconBg.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: iconBg, size: 22),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: badgeColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      badge,
                      style: GoogleFonts.inter(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: badgeColor,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: AppTheme.textSecondaryColor,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value,
                style: GoogleFonts.inter(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
