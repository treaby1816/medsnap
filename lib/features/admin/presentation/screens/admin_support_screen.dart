import 'package:flutter/material.dart';
import '../../../../widgets/glass_app_bar.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme.dart';

class AdminSupportScreen extends StatelessWidget {
  const AdminSupportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: GlassAppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: AppTheme.textPrimaryColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'System Support',
          style: GoogleFonts.inter(
            fontSize: 18,
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
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.support_agent_rounded, size: 80, color: AppTheme.textTertiaryColor),
            const SizedBox(height: 20),
             Text(
              'No active tickets',
              style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimaryColor),
            ),
            Text(
              'All users are operating smoothly.',
              style: GoogleFonts.inter(color: AppTheme.textSecondaryColor),
            ),
          ],
        ),
      ),
    );
  }
}
