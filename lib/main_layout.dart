// ⚠️ DEPRECATED: This file is no longer used.
// The active navigation wrapper is features/main_navigation_screen.dart
// Kept for reference only — safe to delete.

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// --- ALL FEATURES NOW INTEGRATED ---
import 'features/patient/patient_home_screen.dart'; 
import 'features/patient/patient_search_screen.dart'; 
import 'features/scan/scan_prescription_screen.dart'; 
import 'features/patient/nearby_facilities_screen.dart'; 
import 'features/patient/patient_profile_screen.dart'; // New Profile Screen Import

class MainNavigationWrapper extends StatefulWidget {
  const MainNavigationWrapper({super.key});

  @override
  State<MainNavigationWrapper> createState() => _MainNavigationWrapperState();
}

class _MainNavigationWrapperState extends State<MainNavigationWrapper> {
  int _selectedIndex = 0; 
  final Color primaryColor = const Color(0xFFEC5B13);

  // --- FINALIZED SCREEN LIST (ALL 5 TABS READY) ---
  late final List<Widget> _screens = [
    const PatientHomeScreen(), 
    const PatientSearchScreen(),
    const ScanPrescriptionScreen(), 
    const NearbyFacilitiesScreen(), 
    const PatientProfileScreen(), // Real Profile Screen integrated
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // --- HAMBURGER MENU (DRAWER) ---
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: BoxDecoration(color: primaryColor),
              child: Text('VailMeds Menu', 
                style: GoogleFonts.inter(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
            ),
            ListTile(
              leading: const Icon(Icons.history),
              title: const Text('Order History'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text('Settings'),
              onTap: () => Navigator.pop(context),
            ),
            ListTile(
              leading: const Icon(Icons.help_outline),
              title: const Text('Help & Support'),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),

      // --- SHARED APP BAR ---
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(color: primaryColor), 
        centerTitle: true,
        title: Text('VailMeds', 
          style: GoogleFonts.inter(color: Colors.black, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle, color: Colors.black, size: 30),
            onPressed: () => setState(() => _selectedIndex = 4), // Jumps to Profile Tab
          ),
        ],
      ),

      // IndexedStack preserves the state of your search results and map
      body: IndexedStack(
        index: _selectedIndex,
        children: _screens,
      ),

      // --- BOTTOM NAVIGATION BAR ---
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        type: BottomNavigationBarType.fixed,
        selectedItemColor: primaryColor,
        unselectedItemColor: Colors.grey,
        selectedLabelStyle: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 11),
        unselectedLabelStyle: GoogleFonts.inter(fontSize: 11),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home_outlined), label: 'HOME'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'SEARCH'),
          BottomNavigationBarItem(icon: Icon(Icons.document_scanner_outlined), label: 'SCAN'),
          BottomNavigationBarItem(icon: Icon(Icons.location_on_outlined), label: 'NEARBY'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'PROFILE'),
        ],
      ),
    );
  }
}