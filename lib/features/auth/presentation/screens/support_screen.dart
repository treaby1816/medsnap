import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/theme.dart';
import '../../../../widgets/glass_app_bar.dart';

class SupportScreen extends StatelessWidget {
  const SupportScreen({super.key});

  Future<void> _launchUrl(BuildContext context, String url) async {
    final uri = Uri.parse(url);
    try {
      // Bypassing canLaunchUrl which fails on Android 11+ due to package visibility rules
      final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!launched && context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Could not open external app for this action.')),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error: No compatible app found.')),
        );
      }
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
          'Contact Support',
          style: GoogleFonts.inter(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimaryColor,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppTheme.pagePadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Hero Banner
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppTheme.primaryColor,
                    AppTheme.primaryColor.withValues(alpha: 0.8),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.primaryColor.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Icon(Icons.support_agent_rounded,
                      size: 56, color: Colors.white),
                  const SizedBox(height: 12),
                  Text(
                    'We\'re Here to Help',
                    style: GoogleFonts.inter(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Available Mon–Sat, 8AM – 8PM WAT',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Contact Options
            _buildSupportOption(
              icon: Icons.email_outlined,
              title: 'Email Support',
              subtitle: 'support@vailmeds.com',
              onTap: () => _launchUrl(context, 'mailto:support@vailmeds.com?subject=VailMeds%20Support%20Request'),
            ),
            const SizedBox(height: 16),
            _buildSupportOption(
              icon: Icons.phone_outlined,
              title: 'Phone Support',
              subtitle: '+234 801 234 5678',
              onTap: () => _launchUrl(context, 'tel:+2348012345678'),
            ),
            const SizedBox(height: 16),
            _buildSupportOption(
              icon: Icons.chat_bubble_outline,
              title: 'WhatsApp',
              subtitle: 'Chat with us instantly',
              onTap: () => _launchUrl(context, 'https://wa.me/2348012345678?text=Hello%20VailMeds%20Support'),
            ),
            const SizedBox(height: 32),

            // FAQ Section
            Text(
              'Frequently Asked Questions',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.textPrimaryColor,
              ),
            ),
            const SizedBox(height: 16),
            _buildFAQItem(
              'How do I reset my password?',
              'Go to the Login screen and tap "Forgot Password." Enter your registered email and we\'ll send a reset link within minutes.',
            ),
            _buildFAQItem(
              'Is my health data secure?',
              'Absolutely. All data is encrypted at rest and in transit using industry-standard 256-bit AES encryption. We comply with Nigerian NDPR regulations and international HIPAA guidelines.',
            ),
            _buildFAQItem(
              'How do I track my order?',
              'Go to your Orders tab to see real-time status of your medication deliveries. You\'ll also receive push notifications at every step.',
            ),
            _buildFAQItem(
              'Can I cancel or modify an order?',
              'You can cancel within 30 minutes of placing the order. After that, contact our support team via WhatsApp or phone for assistance.',
            ),
            _buildFAQItem(
              'How are pharmacies verified?',
              'Every pharmacy on VailMeds must submit a valid PCN license number and complete our access-token verification before they can list products.',
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildSupportOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.borderColor),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: AppTheme.primaryColor, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.textPrimaryColor,
                    ),
                  ),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: AppTheme.textSecondaryColor,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: AppTheme.textTertiaryColor),
          ],
        ),
      ),
    );
  }

  Widget _buildFAQItem(String question, String answer) {
    return ExpansionTile(
      tilePadding: const EdgeInsets.symmetric(horizontal: 4),
      childrenPadding: const EdgeInsets.only(left: 4, right: 4, bottom: 12),
      title: Text(
        question,
        style: GoogleFonts.inter(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: AppTheme.textPrimaryColor,
        ),
      ),
      children: [
        Text(
          answer,
          style: GoogleFonts.inter(
            fontSize: 14,
            color: AppTheme.textSecondaryColor,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}
