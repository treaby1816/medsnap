import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme.dart';
import '../../../../core/providers/admin_providers.dart';
import '../widgets/staff_card.dart';

/// Admin Staff Management Hub — Command & Control RBAC
class AdminStaffScreen extends ConsumerStatefulWidget {
  const AdminStaffScreen({super.key});

  @override
  ConsumerState<AdminStaffScreen> createState() => _AdminStaffScreenState();
}

class _AdminStaffScreenState extends ConsumerState<AdminStaffScreen> {
  String _activeFilter = 'all'; // 'all', 'super_admin', 'admin'

  @override
  Widget build(BuildContext context) {
    final staffAsync = ref.watch(adminStaffProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header Section ──
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Administrative Sovereignty',
                    style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w800, color: AppTheme.textPrimaryColor),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Managing clinical auditors and system administrators',
                    style: GoogleFonts.inter(fontSize: 14, color: AppTheme.textSecondaryColor),
                  ),
                ],
              ),
              _buildInviteButton(),
            ],
          ),
          const SizedBox(height: 32),

          // ── Dashboard Overview Micro-stats ──
          Row(
            children: [
              _buildMetricCard('VERIFICATION LOAD', '98.2%', Icons.speed_rounded, const Color(0xFF22C55E)),
              const SizedBox(width: 16),
              _buildMetricCard('AVG. RESPONSE', '4.2m', Icons.timer_outlined, AppTheme.primaryColor),
              const SizedBox(width: 16),
              _buildMetricCard('TEAM HEALTH', 'OPTIMAL', Icons.favorite_border_rounded, const Color(0xFF3B82F6)),
            ],
          ),
          const SizedBox(height: 40),

          // ── Filter Hub ──
          Row(
            children: [
              _filterChip('Total Force', 'all'),
              const SizedBox(width: 12),
              _filterChip('Lead Board', 'super_admin'),
              const SizedBox(width: 12),
              _filterChip('Auditors', 'admin'),
            ],
          ),
          const SizedBox(height: 24),

          // ── Staff Grid ──
          staffAsync.when(
            data: (members) {
              final filtered = _activeFilter == 'all' 
                  ? members 
                  : members.where((m) => m.role == _activeFilter).toList();
              
              if (filtered.isEmpty) {
                return Center(child: Text('No personnel found for this role.', style: GoogleFonts.inter(color: AppTheme.textTertiaryColor)));
              }

              return LayoutBuilder(
                builder: (context, constraints) {
                  final crossAxisCount = constraints.maxWidth > 1200 ? 3 : (constraints.maxWidth > 800 ? 2 : 1);
                  return GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: crossAxisCount,
                      crossAxisSpacing: 20,
                      mainAxisSpacing: 20,
                      childAspectRatio: 1.45,
                    ),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) => StaffCard(staff: filtered[index]),
                  );
                },
              );
            },
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Error: $e')),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.borderColor),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: color.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, size: 20, color: color),
            ),
            const SizedBox(width: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w800, color: AppTheme.textTertiaryColor, letterSpacing: 0.5)),
                const SizedBox(height: 4),
                Text(value, style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.textPrimaryColor)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _filterChip(String label, String value) {
    final isSelected = _activeFilter == value;
    return InkWell(
      onTap: () => setState(() => _activeFilter = value),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? AppTheme.primaryColor : AppTheme.borderColor),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: isSelected ? Colors.white : AppTheme.textSecondaryColor,
          ),
        ),
      ),
    );
  }

  Widget _buildInviteButton() {
    return ElevatedButton.icon(
      onPressed: () {},
      icon: const Icon(Icons.add_rounded, size: 20),
      label: Text('INVITE AUDITOR', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 1)),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}
