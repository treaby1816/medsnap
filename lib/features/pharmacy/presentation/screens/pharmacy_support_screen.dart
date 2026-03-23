import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme.dart';
import '../../../../widgets/glass_app_bar.dart';

class PharmacySupportScreen extends StatelessWidget {
  const PharmacySupportScreen({super.key});

  Future<void> _launchUrl(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: GlassAppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimaryColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Help & Support',
          style: GoogleFonts.inter(
            color: AppTheme.textPrimaryColor,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.pagePadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Banner
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(AppTheme.pagePadding),
              decoration: BoxDecoration(
                color: const Color(0xFF16A34A).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                boxShadow: AppTheme.floatingShadow,
              ),
              child: Column(
                children: [
                  const Icon(Icons.support_agent_rounded,
                      size: 64, color: Color(0xFF16A34A)),
                  const SizedBox(height: 16),
                  Text(
                    'How can we help you?',
                    style: GoogleFonts.inter(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimaryColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Our pharmacy support team is available to assist with inventory, orders, and verification queries.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: AppTheme.textSecondaryColor,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Quick Contact
            Text(
              'Quick Contact',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimaryColor,
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                _buildContactCard(
                  icon: Icons.chat_bubble_outline_rounded,
                  label: 'WhatsApp',
                  color: const Color(0xFF25D366),
                  onTap: () => _launchUrl(
                      'https://wa.me/2348012345678?text=Hello%20VailMeds%20Pharmacy%20Support'),
                ),
                const SizedBox(width: 12),
                _buildContactCard(
                  icon: Icons.email_outlined,
                  label: 'Email Us',
                  color: const Color(0xFFF59E0B),
                  onTap: () => _launchUrl(
                      'mailto:pharmacy-support@vailmeds.com?subject=Pharmacy%20Support%20Request'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _buildContactCard(
                  icon: Icons.phone_outlined,
                  label: 'Call Us',
                  color: const Color(0xFF3B82F6),
                  onTap: () => _launchUrl('tel:+2348012345678'),
                ),
                const SizedBox(width: 12),
                _buildContactCard(
                  icon: Icons.language,
                  label: 'Help Center',
                  color: const Color(0xFF8B5CF6),
                  onTap: () => _launchUrl('https://vailmeds.com/help'),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // FAQs
            Text(
              'Frequently Asked Questions',
              style: GoogleFonts.inter(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimaryColor,
              ),
            ),
            const SizedBox(height: 16),
            _buildFaqItem(
              'How do I manage low stock alerts?',
              'Navigate to your Inventory screen and enable notifications for items below a set threshold. You\'ll receive push alerts when stock runs low.',
            ),
            _buildFaqItem(
              'Can I export my monthly revenue logs?',
              'Yes! Go to the Logs tab in your dashboard and tap the export button. We support CSV and PDF formats for your records.',
            ),
            _buildFaqItem(
              'How to update pharmacy business hours?',
              'Go to your Pharmacy Profile from the dashboard sidebar and tap "Edit Hours." Changes are reflected immediately on the marketplace.',
            ),
            _buildFaqItem(
              'Adding new staff to the dashboard',
              'Currently, each pharmacy has a single admin login. Multi-staff access with role management is coming in a future update.',
            ),
            _buildFaqItem(
              'How is my verification reviewed?',
              'Our team verifies your PCN license number and access token within 24–48 hours. You\'ll receive an in-app notification once approved.',
            ),
            const SizedBox(height: AppTheme.pagePadding),
          ],
        ),
      ),
    );
  }

  Widget _buildContactCard({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.cardRadius),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppTheme.cardRadius),
            boxShadow: AppTheme.floatingShadow,
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 28),
              const SizedBox(height: 8),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.textPrimaryColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFaqItem(String question, String answer) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.inputRadius),
        boxShadow: AppTheme.floatingShadow,
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16),
        childrenPadding:
            const EdgeInsets.only(left: 16, right: 16, bottom: 16),
        title: Text(
          question,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppTheme.textSecondaryColor,
          ),
        ),
        children: [
          Text(
            answer,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppTheme.textTertiaryColor,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}