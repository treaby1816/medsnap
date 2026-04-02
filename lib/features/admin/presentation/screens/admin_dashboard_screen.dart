import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme.dart';
import '../../../../core/providers.dart';
import '../../../../core/utils/compliance_report_exporter.dart';
import '../widgets/admin_sidebar.dart';
import '../widgets/admin_header.dart';
import '../widgets/admin_stats_grid.dart';
import '../widgets/admin_performance_chart.dart';
import '../widgets/admin_activity_feed.dart';
import '../widgets/admin_approvals_table.dart';
import 'admin_approvals_screen.dart';
import 'admin_support_center.dart';
import 'admin_analytics_screen.dart';
import 'admin_inventory_screen.dart';

/// The main Admin Dashboard screen — desktop-first layout with:
///  • Fixed sidebar navigation (left)
///  • Scrollable body (right): header, bento stats, chart, feed, table
///
/// Sidebar navigation switches between inline views:
///   0 = Dashboard, 1 = Approvals, 2 = Inventory (stub),
///   3 = Analytics, 4 = Staff (stub), 5 = Support
class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  int _selectedIndex = 0;

  // Label map for breadcrumb navigation
  static const _sectionLabels = {
    0: 'Dashboard',
    1: 'Approvals',
    2: 'Inventory',
    3: 'Analytics',
    4: 'Staff',
    5: 'Support',
  };

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(userProfileProvider).value;

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Row(
        children: [
          // ── Sidebar ──
          AdminSidebar(
            selectedIndex: _selectedIndex,
            onItemSelected: (i) => setState(() => _selectedIndex = i),
            onLogout: () async {
              await ref.read(authServiceProvider).signOut();
              if (context.mounted) {
                Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
              }
            },
            onExportPdf: () => ComplianceReportExporter.generateAndPreview(context),
          ),

          // ── Main Content ──
          Expanded(
            child: Column(
              children: [
                // ── Glassmorphism Header ──
                AdminHeader(
                  adminName: profile?.displayName ?? 'Dr. Alistair Vail',
                  adminRole: profile?.role.toUpperCase() ?? 'SUPER ADMIN',
                  onProfileTap: () => _showProfileDialog(context),
                  onSettingsTap: () => _showSettingsDialog(context),
                  onNotificationsTap: () => _showNotificationsDialog(context),
                ),

                // ── Back Navigation Bar (when not on Dashboard) ──
                if (_selectedIndex != 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 10),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border(
                        bottom: BorderSide(color: AppTheme.borderColor.withValues(alpha: 0.5)),
                      ),
                    ),
                    child: Row(
                      children: [
                        InkWell(
                          onTap: () => setState(() => _selectedIndex = 0),
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryColor.withValues(alpha: 0.08),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.arrow_back_rounded, size: 18, color: AppTheme.primaryColor),
                                const SizedBox(width: 6),
                                Text(
                                  'Back to Dashboard',
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: AppTheme.primaryColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '/ ${_sectionLabels[_selectedIndex] ?? 'Section'}',
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.textTertiaryColor,
                          ),
                        ),
                      ],
                    ),
                  ),

                // ── Body Content (switches by sidebar selection) ──
                Expanded(
                  child: _buildBody(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────
  // PROFILE DIALOG
  // ─────────────────────────────────────────────────────────────────────
  void _showProfileDialog(BuildContext context) {
    final profile = ref.read(userProfileProvider).value;
    final displayName = profile?.displayName ?? 'Dr. Alistair Vail';
    final email = profile?.email ?? 'admin@vailmeds.com';
    final role = profile?.role ?? 'super_admin';

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          width: 400,
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Avatar
              CircleAvatar(
                radius: 40,
                backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.12),
                child: const Icon(Icons.person_rounded, size: 42, color: AppTheme.primaryColor),
              ),
              const SizedBox(height: 16),
              Text(
                displayName,
                style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w800, color: AppTheme.textPrimaryColor),
              ),
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  role.toUpperCase().replaceAll('_', ' '),
                  style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w800, color: AppTheme.primaryColor, letterSpacing: 1),
                ),
              ),
              const SizedBox(height: 20),
              // Info rows
              _profileInfoRow(Icons.email_outlined, 'Email', email),
              _profileInfoRow(Icons.shield_outlined, 'Access Level', 'Full Administrative'),
              _profileInfoRow(Icons.schedule_outlined, 'Last Login', 'Today, ${TimeOfDay.now().format(context)}'),
              _profileInfoRow(Icons.verified_user_outlined, 'Status', 'Active'),
              const SizedBox(height: 24),
              // Actions
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppTheme.borderColor),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text('Close', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: AppTheme.textSecondaryColor)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        Navigator.pop(ctx);
                        await ref.read(authServiceProvider).signOut();
                        if (context.mounted) {
                          Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
                        }
                      },
                      icon: const Icon(Icons.logout_rounded, size: 18),
                      label: Text('Sign Out', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFEF4444),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _profileInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppTheme.textTertiaryColor),
          const SizedBox(width: 12),
          SizedBox(
            width: 100,
            child: Text(label, style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textTertiaryColor, fontWeight: FontWeight.w500)),
          ),
          Expanded(
            child: Text(value, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w600, color: AppTheme.textPrimaryColor)),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────
  // SETTINGS DIALOG
  // ─────────────────────────────────────────────────────────────────────
  void _showSettingsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => _SettingsDialog(
        onClose: () => Navigator.pop(ctx),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────
  // NOTIFICATIONS DIALOG
  // ─────────────────────────────────────────────────────────────────────
  void _showNotificationsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Container(
          width: 440,
          constraints: const BoxConstraints(maxHeight: 520),
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Notifications', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.textPrimaryColor)),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, size: 20, color: AppTheme.textTertiaryColor),
                    onPressed: () => Navigator.pop(ctx),
                  ),
                ],
              ),
              const Divider(),
              const SizedBox(height: 8),
              Flexible(
                child: ListView(
                  shrinkWrap: true,
                  children: [
                    _notificationItem(
                      icon: Icons.verified_user_outlined,
                      color: const Color(0xFF22C55E),
                      title: 'New Pharmacy Registration',
                      subtitle: 'CityMeds Central Hub submitted for verification',
                      time: '2m ago',
                    ),
                    _notificationItem(
                      icon: Icons.warning_amber_rounded,
                      color: const Color(0xFFF59E0B),
                      title: 'Low Stock Alert',
                      subtitle: 'Lisinopril 10mg below threshold at 3 pharmacies',
                      time: '14m ago',
                    ),
                    _notificationItem(
                      icon: Icons.support_agent_rounded,
                      color: const Color(0xFFEF4444),
                      title: 'Urgent Support Ticket',
                      subtitle: 'Marcus Holloway — prescription not syncing',
                      time: '18m ago',
                    ),
                    _notificationItem(
                      icon: Icons.analytics_outlined,
                      color: const Color(0xFF3B82F6),
                      title: 'Weekly Report Ready',
                      subtitle: 'Compliance report for Oct 18–24 generated',
                      time: '1h ago',
                    ),
                    _notificationItem(
                      icon: Icons.person_add_alt_1_rounded,
                      color: AppTheme.primaryColor,
                      title: 'New Patient Registration',
                      subtitle: '12 new patients registered today',
                      time: '3h ago',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    setState(() => _selectedIndex = 5); // Go to Support
                  },
                  child: Text('View All Activity', style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: AppTheme.primaryColor)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _notificationItem({
    required IconData icon,
    required Color color,
    required String title,
    required String subtitle,
    required String time,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w700, color: AppTheme.textPrimaryColor)),
                const SizedBox(height: 2),
                Text(subtitle, style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondaryColor)),
              ],
            ),
          ),
          Text(time, style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textTertiaryColor)),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────
  // BODY BUILDER
  // ─────────────────────────────────────────────────────────────────────
  Widget _buildBody() {
    switch (_selectedIndex) {
      case 0:
        return _buildDashboardView();
      case 1:
        return const AdminApprovalsScreen();
      case 2:
        return const AdminInventoryScreen();
      case 3:
        return const AdminAnalyticsScreen();
      case 4:
        return _buildStubView('Staff', Icons.people_outline_rounded);
      case 5:
        return const AdminSupportCenter();
      default:
        return _buildDashboardView();
    }
  }

  /// The main "Overview Dashboard" — Clinical Performance Hub
  Widget _buildDashboardView() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Page Title ──
          Text(
            'OVERVIEW DASHBOARD',
            style: GoogleFonts.inter(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: AppTheme.primaryColor,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Clinical Performance Hub',
            style: GoogleFonts.inter(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 24),

          // ── Bento Stats Grid ──
          AdminStatsGrid(
            onCardTap: (index) => setState(() => _selectedIndex = index),
          ),
          const SizedBox(height: 24),

          // ── Performance Chart + Activity Feed (side by side) ──
          LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth < 800) {
                return Column(
                  children: [
                    const AdminPerformanceChart(),
                    const SizedBox(height: 16),
                    AdminActivityFeed(
                      onViewAll: () => setState(() => _selectedIndex = 5),
                    ),
                  ],
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Expanded(flex: 3, child: AdminPerformanceChart()),
                  const SizedBox(width: 20),
                  Expanded(
                    flex: 1,
                    child: AdminActivityFeed(
                      onViewAll: () => setState(() => _selectedIndex = 5),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 24),

          // ── Pending Approvals Table ──
          AdminApprovalsTable(
            onViewDirectory: () => setState(() => _selectedIndex = 1),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildStubView(String title, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: AppTheme.textTertiaryColor.withValues(alpha: 0.4)),
          const SizedBox(height: 16),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'This module is coming soon.',
            style: GoogleFonts.inter(color: AppTheme.textSecondaryColor),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// SETTINGS DIALOG (StatefulWidget for toggle switches)
// ─────────────────────────────────────────────────────────────────────
class _SettingsDialog extends StatefulWidget {
  final VoidCallback onClose;
  const _SettingsDialog({required this.onClose});

  @override
  State<_SettingsDialog> createState() => _SettingsDialogState();
}

class _SettingsDialogState extends State<_SettingsDialog> {
  bool _emailNotifications = true;
  bool _smsAlerts = false;
  bool _darkMode = false;
  bool _maintenanceMode = false;
  bool _autoApprove = false;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        width: 440,
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Settings', style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.w800, color: AppTheme.textPrimaryColor)),
                IconButton(
                  icon: const Icon(Icons.close_rounded, size: 20, color: AppTheme.textTertiaryColor),
                  onPressed: widget.onClose,
                ),
              ],
            ),
            const Divider(),
            const SizedBox(height: 8),

            // Section: Notifications
            Text('NOTIFICATIONS', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w800, color: AppTheme.textTertiaryColor, letterSpacing: 1.0)),
            const SizedBox(height: 10),
            _settingsToggle('Email Notifications', 'Receive daily digest and alerts', _emailNotifications, (v) => setState(() => _emailNotifications = v)),
            _settingsToggle('SMS Alerts', 'Critical alerts via text message', _smsAlerts, (v) => setState(() => _smsAlerts = v)),
            const SizedBox(height: 16),

            // Section: Appearance
            Text('APPEARANCE', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w800, color: AppTheme.textTertiaryColor, letterSpacing: 1.0)),
            const SizedBox(height: 10),
            _settingsToggle('Dark Mode', 'Switch to dark theme', _darkMode, (v) => setState(() => _darkMode = v)),
            const SizedBox(height: 16),

            // Section: Administration
            Text('ADMINISTRATION', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w800, color: AppTheme.textTertiaryColor, letterSpacing: 1.0)),
            const SizedBox(height: 10),
            _settingsToggle('Maintenance Mode', 'Disable patient-facing features', _maintenanceMode, (v) => setState(() => _maintenanceMode = v)),
            _settingsToggle('Auto-Approve Pharmacies', 'Skip manual verification step', _autoApprove, (v) => setState(() => _autoApprove = v)),
            const SizedBox(height: 20),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  widget.onClose();
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Settings saved!', style: GoogleFonts.inter(fontWeight: FontWeight.w600)),
                      backgroundColor: const Color(0xFF22C55E),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: Text('Save Changes', style: GoogleFonts.inter(fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _settingsToggle(String title, String subtitle, bool value, ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textPrimaryColor)),
                Text(subtitle, style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textTertiaryColor)),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeTrackColor: AppTheme.primaryColor,
            thumbColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) return Colors.white;
              return null;
            }),
          ),
        ],
      ),
    );
  }
}
