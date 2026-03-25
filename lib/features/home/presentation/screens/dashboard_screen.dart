import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween, // Fixed
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Welcome back,', 
                        style: GoogleFonts.inter(fontSize: 14, color: Colors.grey[600])), // Fixed
                      Text('Adewole Felix 👋', 
                        style: GoogleFonts.inter(fontSize: 20, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const CircleAvatar(
                    backgroundColor: Colors.white,
                    child: Icon(Icons.notifications_none_rounded, color: Colors.black),
                  ),
                ],
              ),
              const SizedBox(height: 25),

              // Search Bar
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.03), // Fixed deprecation
                      blurRadius: 10,
                    )
                  ],
                ),
                child: const TextField(
                  decoration: InputDecoration(
                    icon: Icon(Icons.search, color: Colors.grey),
                    hintText: 'Search medicines...',
                    border: InputBorder.none,
                  ),
                ),
              ),
              const SizedBox(height: 25),

              // Quick Actions
              Text('Quick Services', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
              const SizedBox(height: 15),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildActionCard(Icons.upload_file, 'Upload Rx', Colors.blue),
                  _buildActionCard(Icons.medical_services, 'Refill', Colors.green),
                  _buildActionCard(Icons.support_agent, 'Support', Colors.orange),
                ],
              ),
              
              const SizedBox(height: 30),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Nearby Pharmacies', style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                  TextButton(onPressed: () {}, child: const Text('See all')),
                ],
              ),
              Container(
                height: 100,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey.shade200), // Fixed
                ),
                child: const Center(child: Text('Pharmacy list loading...')),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildActionCard(IconData icon, String label, Color color) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1), // Fixed deprecation
            borderRadius: BorderRadius.circular(15),
          ),
          child: Icon(icon, color: color),
        ),
        const SizedBox(height: 8),
        Text(label, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500)),
      ],
    );
  }
}