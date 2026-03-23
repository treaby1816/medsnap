import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme.dart';
import '../../../../widgets/glass_app_bar.dart';
import '../../../../core/models/job_model.dart';
import 'package:intl/intl.dart';

class JobBoardScreen extends StatelessWidget {
  const JobBoardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Mock jobs for now - in production these would come from Firestore
    final List<JobModel> mockJobs = [
      JobModel(
        id: '1',
        pharmacyId: 'p1',
        pharmacyName: 'HealthPlus Pharmacy',
        title: 'Senior Pharmacist',
        description: 'Looking for a licensed pharmacist with 5+ years experience...',
        location: 'Lekki, Lagos',
        salary: 350000,
        createdAt: DateTime.now().subtract(const Duration(days: 2)),
      ),
      JobModel(
        id: '2',
        pharmacyId: 'p2',
        pharmacyName: 'MedPlus',
        title: 'Pharmacy Technician',
        description: 'Assisting in drug dispensing and inventory management...',
        location: 'Ikeja, Lagos',
        salary: 120000,
        createdAt: DateTime.now().subtract(const Duration(days: 5)),
      ),
    ];

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: GlassAppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimaryColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Pharmacy Job Board',
          style: GoogleFonts.inter(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppTheme.textPrimaryColor,
          ),
        ),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(24),
        itemCount: mockJobs.length,
        itemBuilder: (context, index) {
          final job = mockJobs[index];
          return _buildJobCard(context, job);
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => HapticFeedback.mediumImpact(), // Add Job logic for Pharmacies
        backgroundColor: AppTheme.primaryColor,
        icon: const Icon(Icons.add, color: Colors.white),
        label: Text('Post a Job', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white)),
      ),
    );
  }

  Widget _buildJobCard(BuildContext context, JobModel job) {
    final currencyFormat = NumberFormat.currency(symbol: '₦', decimalDigits: 0);

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: AppTheme.floatingShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      job.title,
                      style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.bold, color: AppTheme.textPrimaryColor),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      job.pharmacyName,
                      style: GoogleFonts.inter(fontSize: 14, color: AppTheme.primaryColor, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  currencyFormat.format(job.salary),
                  style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.location_on_outlined, size: 16, color: AppTheme.textSecondaryColor),
              const SizedBox(width: 4),
              Text(job.location, style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textSecondaryColor)),
              const SizedBox(width: 16),
              const Icon(Icons.access_time, size: 16, color: AppTheme.textSecondaryColor),
              const SizedBox(width: 4),
              Text(
                '${DateTime.now().difference(job.createdAt).inDays}d ago',
                style: GoogleFonts.inter(fontSize: 13, color: AppTheme.textSecondaryColor),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            job.description,
            style: GoogleFonts.inter(fontSize: 14, color: AppTheme.textSecondaryColor, height: 1.5),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF1F5F9),
                foregroundColor: AppTheme.textPrimaryColor,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: Text('View Details', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }
}
