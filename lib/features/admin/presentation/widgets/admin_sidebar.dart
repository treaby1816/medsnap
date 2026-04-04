import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/providers.dart';

/// Fixed-width sidebar for the admin dashboard.
/// Role-aware: only shows admin-only tabs (Approvals, Support, Analytics)
/// when the user has role == 'admin' or 'super_admin'.
class AdminSidebar extends ConsumerWidget {
  final int selectedIndex;
  final ValueChanged<int> onItemSelected;
  final VoidCallback onLogout;
  final VoidCallback? onExportPdf;

  const AdminSidebar({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
    required this.onLogout,
    this.onExportPdf,
  });

  static const double width = 220;
  static const Color _sidebarBg = Color(0xFF0F172A);
  static const Color _activeColor = Color(0xFFEC5B13);
  static const Color _inactiveColor = Color(0xFF94A3B8);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(userProfileProvider).value;
    final userRole = profile?.role ?? 'patient';
    final isAdmin = userRole == 'admin' || userRole == 'super_admin';

    // Build navigation items based on role
    final items = <_NavItem>[
      const _NavItem(Icons.dashboard_rounded, 'Dashboard', false),
      const _NavItem(Icons.verified_user_outlined, 'Approvals', true),
      const _NavItem(Icons.inventory_2_outlined, 'Inventory', false),
      const _NavItem(Icons.analytics_outlined, 'Analytics', true),
      const _NavItem(Icons.people_outline_rounded, 'Staff', true),
      const _NavItem(Icons.support_agent_rounded, 'Support', true),
    ];

    // Filter: non-admins only see non-restricted items
    final visibleItems = isAdmin ? items : items.where((i) => !i.adminOnly).toList();

    return Container(
      width: width,
      color: _sidebarBg,
      child: Column(
        children: [
          // ── Branding Header ──
          const SizedBox(height: 28),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Image.asset(
                  'assets/images/logo.png',
                  width: 36,
                  height: 36,
                  fit: BoxFit.contain,
                ),
                const SizedBox(width: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'VAILMEDS',
                      style: GoogleFonts.inter(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                      ),
                    ),
                    Text(
                      isAdmin ? 'ADMIN' : 'CLINICAL CONCIERGE',
                      style: GoogleFonts.inter(
                        color: _inactiveColor,
                        fontSize: 8,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          // Admin badge
          if (isAdmin)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(
                'Clinical Concierge',
                style: GoogleFonts.inter(
                  color: _inactiveColor.withValues(alpha: 0.6),
                  fontSize: 9,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          const SizedBox(height: 24),

          // ── Navigation Items ──
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: visibleItems.length,
              itemBuilder: (context, index) {
                final item = visibleItems[index];
                // Map visible index back to full index for callback
                final fullIndex = items.indexOf(item);
                final isActive = fullIndex == selectedIndex;
                return _buildNavTile(item, isActive, () => onItemSelected(fullIndex));
              },
            ),
          ),

          // ── Export Reports (admin-only) ──
          if (isAdmin && onExportPdf != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: SizedBox(
                width: double.infinity,
                height: 40,
                child: OutlinedButton.icon(
                  onPressed: onExportPdf,
                  icon: const Icon(Icons.picture_as_pdf, size: 16, color: _inactiveColor),
                  label: Text(
                    'Export Reports',
                    style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: _inactiveColor),
                  ),
                  style: OutlinedButton.styleFrom(
                    side: BorderSide(color: _inactiveColor.withValues(alpha: 0.3)),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ),
          const SizedBox(height: 10),

          // ── New Report CTA ──
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton(
                onPressed: onExportPdf ?? () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: _activeColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: Text(
                  'New Report',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // ── Support & Logout ──
          _buildFooterItem(Icons.logout_rounded, 'Logout', onLogout),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildNavTile(_NavItem item, bool isActive, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(10),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
            decoration: BoxDecoration(
              color: isActive ? _activeColor.withValues(alpha: 0.12) : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
              border: isActive
                  ? const Border(left: BorderSide(color: _activeColor, width: 3))
                  : null,
            ),
            child: Row(
              children: [
                Icon(item.icon, size: 20, color: isActive ? _activeColor : _inactiveColor),
                const SizedBox(width: 12),
                Text(
                  item.label,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                    color: isActive ? _activeColor : _inactiveColor,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFooterItem(IconData icon, String label, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 2),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              Icon(icon, size: 18, color: _inactiveColor),
              const SizedBox(width: 12),
              Text(
                label,
                style: GoogleFonts.inter(color: _inactiveColor, fontSize: 13, fontWeight: FontWeight.w500),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem {
  final IconData icon;
  final String label;
  final bool adminOnly;
  const _NavItem(this.icon, this.label, this.adminOnly);
}
