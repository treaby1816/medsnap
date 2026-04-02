import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme.dart';
import '../../../../widgets/glass_app_bar.dart';

class PharmacyNotificationsScreen extends StatefulWidget {
  const PharmacyNotificationsScreen({super.key});

  @override
  State<PharmacyNotificationsScreen> createState() => _PharmacyNotificationsScreenState();
}

class _PharmacyNotificationsScreenState extends State<PharmacyNotificationsScreen> {
  bool _newOrders = true;
  bool _statusChanges = true;
  bool _marketing = false;
  bool _securityAlerts = true;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: GlassAppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: AppTheme.textPrimaryColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Notifications',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimaryColor,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.close_rounded, color: AppTheme.textSecondaryColor),
            onPressed: () => Navigator.pop(context),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppTheme.pagePadding),
        children: [
          _buildSectionHeader('System Alerts'),
          _buildSwitchTile(
            'New Orders',
            'Get notified when a patient places a new order',
            _newOrders,
            (val) => setState(() => _newOrders = val),
          ),
          _buildSwitchTile(
            'Order Status Changes',
            'Alerts when delivery status is updated',
            _statusChanges,
            (val) => setState(() => _statusChanges = val),
          ),
          _buildSwitchTile(
            'Security Alerts',
            'Critical account and login notifications',
            _securityAlerts,
            (val) => setState(() => _securityAlerts = val),
          ),
          const SizedBox(height: 32),
          _buildSectionHeader('Other'),
          _buildSwitchTile(
            'Marketing & Tips',
            'News and tips to grow your pharmacy',
            _marketing,
            (val) => setState(() => _marketing = val),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 16),
      child: Text(
        title.toUpperCase(),
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: AppTheme.textTertiaryColor,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildSwitchTile(String title, String subtitle, bool value, ValueChanged<bool> onChanged) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          switchTheme: SwitchThemeData(
            thumbColor: WidgetStateProperty.all(AppTheme.primaryColor),
            trackColor: WidgetStateProperty.resolveWith((states) {
              if (states.contains(WidgetState.selected)) {
                return AppTheme.primaryColor.withValues(alpha: 0.5);
              }
              return null;
            }),
          ),
        ),
        child: SwitchListTile(
          value: value,
          onChanged: onChanged,
          title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          subtitle: Text(subtitle, style: const TextStyle(fontSize: 12, color: AppTheme.textSecondaryColor)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        ),
      ),
    );
  }
}
