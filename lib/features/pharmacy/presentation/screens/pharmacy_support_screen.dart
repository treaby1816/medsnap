import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme.dart';
import '../../../../widgets/glass_app_bar.dart';

class PharmacySupportScreen extends StatefulWidget {
  const PharmacySupportScreen({super.key});

  @override
  State<PharmacySupportScreen> createState() => _PharmacySupportScreenState();
}

class _PharmacySupportScreenState extends State<PharmacySupportScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: GlassAppBar(
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
                    'Our team is available to assist you with any pharmacy-related queries.',
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
                  label: 'Live Chat',
                  color: const Color(0xFF3B82F6),
                  onTap: () {},
                ),
                const SizedBox(width: 12),
                _buildContactCard(
                  icon: Icons.email_outlined,
                  label: 'Email Us',
                  color: const Color(0xFFF59E0B),
                  onTap: () {},
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
            _buildFaqItem('How do I manage low stock alerts?'),
            _buildFaqItem('Can I export my monthly revenue logs?'),
            _buildFaqItem('How to update pharmacy business hours?'),
            _buildFaqItem('Adding new staff to the dashboard'),
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

  Widget _buildFaqItem(String question) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.inputRadius),
        boxShadow: AppTheme.floatingShadow,
      ),
      child: ListTile(
        title: Text(
          question,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: AppTheme.textSecondaryColor,
          ),
        ),
        trailing: const Icon(Icons.add,
            size: 18, color: AppTheme.textTertiaryColor),
        onTap: () {},
      ),
    );
  }
}