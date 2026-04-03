import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/providers.dart';
import '../../../../core/theme.dart';
import '../../../../widgets/floating_chat_button.dart';
import '../../../../widgets/floating_chat_panel.dart';
import 'pharmacy_dashboard_screen.dart';
import 'pharmacy_inventory_screen.dart';
import 'pharmacy_orders_screen.dart';
import 'pharmacy_logs_screen.dart';
import 'pharmacy_support_screen.dart';
import 'pharmacy_profile_screen.dart';
import 'pharmacy_analytics_screen.dart';
import 'pharmacy_notifications_screen.dart';
import 'pharmacy_security_screen.dart';

class PharmacyMainScreen extends StatefulWidget {
  const PharmacyMainScreen({super.key});

  @override
  State<PharmacyMainScreen> createState() => _PharmacyMainScreenState();
}

class _PharmacyMainScreenState extends State<PharmacyMainScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const PharmacyDashboardScreen(),
    const PharmacyInventoryScreen(isEmbedded: true),
    const PharmacyOrdersScreen(),
    const PharmacyAnalyticsScreen(),
    const _SettingsTab(),
  ];

  @override
  Widget build(BuildContext context) {
    // Uses theme's BottomNavigationBarThemeData — no manual styling needed
    return Scaffold(
      body: Stack(
        children: [
          IndexedStack(index: _currentIndex, children: _screens),
          // Floating Chat Button — Pharmacy Dashboard
          FloatingChatButton(
            onPressed: () => showFloatingChatPanel(context, userRole: 'pharmacy'),
          ),
        ],
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_outlined),
            activeIcon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.inventory_2_outlined),
            activeIcon: Icon(Icons.inventory_2),
            label: 'Inventory',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.shopping_cart_outlined),
            activeIcon: Icon(Icons.shopping_cart),
            label: 'Orders',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.analytics_outlined),
            activeIcon: Icon(Icons.analytics),
            label: 'Analytics',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            activeIcon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
class _SettingsTab extends ConsumerWidget {
  const _SettingsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userProfile = ref.watch(userProfileProvider).value;
    final displayName = userProfile?.displayName ?? 
                      (userProfile?.email.split('@')[0] ?? 'Pharmacist');
    return Container(
      color: AppTheme.backgroundColor,
      child: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Glassmorphic header area
            Container(
              color: Colors.white,
              height: 72,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.settings,
                        color: AppTheme.primaryColor, size: 24),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Settings',
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimaryColor,
                    ),
                  ),
                ],
              ),
            ),
            Container(color: AppTheme.borderColor, height: 1),
            Expanded(
              child: Scrollbar(
                child: ListView(
                  padding: const EdgeInsets.all(20),
                  children: [
                    _buildSettingsTile(
                      context,
                      icon: Icons.person_outline,
                      title: 'Profile',
                      subtitle: '$displayName — Pharmacist',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const PharmacyProfileScreen()),
                      ),
                    ),
                    _buildSettingsTile(
                      context,
                      icon: Icons.receipt_long_outlined,
                      title: 'Activity Logs',
                      subtitle: 'Verification pipeline & history',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const PharmacyLogsScreen()),
                      ),
                    ),
                    _buildSettingsTile(
                      context,
                      icon: Icons.support_agent_outlined,
                      title: 'Support',
                      subtitle: 'Live chat, call, email',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const PharmacySupportScreen()),
                      ),
                    ),
                    _buildSettingsTile(
                      context,
                      icon: Icons.notifications_none_rounded,
                      title: 'Notifications',
                      subtitle: 'Manage alerts and preferences',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const PharmacyNotificationsScreen()),
                      ),
                    ),
                    _buildSettingsTile(
                      context,
                      icon: Icons.security_rounded,
                      title: 'Security',
                      subtitle: 'Password, 2FA, sessions',
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const PharmacySecurityScreen()),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          // FIXED: Actually call signOut to clear the persistent session
                          await ref.read(authServiceProvider).signOut();
                          if (context.mounted) {
                            Navigator.of(context).pushNamedAndRemoveUntil(
                              '/gateway',
                              (route) => false,
                            );
                          }
                        },
                        icon: const Icon(Icons.logout_rounded, size: 20),
                        label: const Text('Sign Out'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: const Color(0xFFEF4444),
                          side: const BorderSide(color: Color(0xFFFECACA)),
                          backgroundColor: const Color(0xFFFEF2F2),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(AppTheme.buttonRadius),
                          ),
                          textStyle: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
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

  Widget _buildSettingsTile(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child:
                      Icon(icon, color: AppTheme.textSecondaryColor, size: 20),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.textPrimaryColor,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppTheme.textTertiaryColor,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right_rounded,
                    color: AppTheme.textTertiaryColor),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
