import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme.dart';
import '../../../../widgets/glass_app_bar.dart';

class PolicyScreen extends StatelessWidget {
  final String title;
  final bool isPrivacy;

  const PolicyScreen({
    super.key,
    required this.title,
    this.isPrivacy = true,
  });

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
          title,
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            Text(
              'Last Updated: April 2026',
              style: GoogleFonts.inter(
                fontSize: 14,
                color: AppTheme.textTertiaryColor,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 24),
            _buildEnrichedContent(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildEnrichedContent() {
    if (isPrivacy) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader('1. Data Security & HIPAA Compliance'),
          _buildParagraph('VailMeds is committed to protecting your privacy. We comply fully with the Health Insurance Portability and Accountability Act (HIPAA) to ensure that your protected health information (PHI) remains secure. We utilize end-to-end multi-layered encryption.'),
          _buildHeader('2. Information We Collect'),
          _buildParagraph('When you register for VailMeds, we collect basic account details including name, email, and phone number. Authorized pharmacies and doctors may attach prescription records to your secure Medical ID.'),
          _buildHeader('3. Usage of Information'),
          _buildParagraph('Your data is strictly used to facilitate the bridging of patients, clinical staff, and verified pharmacies. We NEVER sell your biological data, medical records, or personal demographics to unauthorized third parties.'),
          _buildHeader('4. Device Permissions'),
          _buildParagraph('We may request location access to discover Nearby Pharmacies and camera access to scan prescription QR codes. These permissions are entirely transparent and can be revoked at any time via your device settings.'),
          const SizedBox(height: 12),
          _buildParagraph('If you have any questions regarding how we process your data, please use our Support Chatbot to reach a compliance officer instantly.'),
        ],
      );
    } else {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader('1. Platform Facilitation'),
          _buildParagraph('By using VailMeds, you acknowledge that our platform serves entirely as a technology bridge. VailMeds itself is NOT a medical clinic and does not directly prescribe medication or issue diagnoses.'),
          _buildHeader('2. User Accountability'),
          _buildParagraph('Users must provide truthful, accurate documentation when registering. Falsifying prescription claims or impersonating a medical professional will lead to immediate account termination and reporting to the appropriate federal authorities.'),
          _buildHeader('3. Payment & Transactions'),
          _buildParagraph('Pharmacy purchases made through the App are processed by secure Stripe portals. VailMeds acts as an escrow intermediary to protect both the clinic and the patient. Refunds for controlled substances are subject to strict legal guidelines.'),
          _buildHeader('4. Service Disclaimers'),
          _buildParagraph('Our architecture guarantees 99.9% uptime. However, in the event of an outage, VailMeds is not liable for minor delays in non-critical automated pharmacy fulfillments. In medical emergencies, you must immediately dial your local emergency services (e.g., 911).'),
        ],
      );
    }
  }

  Widget _buildHeader(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 8),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 16,
          fontWeight: FontWeight.w700,
          color: AppTheme.textPrimaryColor,
        ),
      ),
    );
  }

  Widget _buildParagraph(String text) {
    return Text(
      text,
      style: GoogleFonts.inter(
        fontSize: 15,
        color: AppTheme.textSecondaryColor,
        height: 1.6,
      ),
    );
  }
}
