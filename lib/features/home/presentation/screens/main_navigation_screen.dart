import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// --- THE ONLY EXPORT YOU NEED ---
// This now provides access to PatientSearchScreen, OrdersScreen, PatientProfileScreen, etc.
import 'package:vail_meds_v2/features/screens.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;

  // The list of screens your BottomNavigationBar will toggle through
  final List<Widget> _pages = [
    const HomeScreen(), // NEW: Uses the stabilized version
    const NearbyFacilitiesScreen(),
    const OrdersScreen(),
    const PatientProfileScreen(), // NEW: Uses the stabilized version
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    // FIXED: Changed 'final' to 'const' for the constant Color value
    const Color primaryColor = Color(0xFFEC5B13);

    return Scaffold(
      extendBody: true, // Allows scroll behind the nav bar
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        child: BackdropFilter(
          filter: ui.ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.85),
              border: Border(top: BorderSide(color: Colors.grey.withValues(alpha: 0.2), width: 0.5)),
            ),
            child: BottomNavigationBar(
              currentIndex: _selectedIndex,
              onTap: _onItemTapped,
              type: BottomNavigationBarType.fixed,
              elevation: 0,
              backgroundColor: Colors.transparent,
              selectedItemColor: primaryColor,
              unselectedItemColor: Colors.grey,
              selectedLabelStyle: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 12),
              unselectedLabelStyle: GoogleFonts.inter(fontSize: 12),
              items: const [
                BottomNavigationBarItem(icon: Icon(Icons.home_outlined), activeIcon: Icon(Icons.home), label: 'Home'),
                BottomNavigationBarItem(icon: Icon(Icons.location_on_outlined), activeIcon: Icon(Icons.location_on), label: 'Nearby'),
                BottomNavigationBarItem(icon: Icon(Icons.shopping_bag_outlined), activeIcon: Icon(Icons.shopping_bag), label: 'Orders'),
                BottomNavigationBarItem(icon: Icon(Icons.person_outline), activeIcon: Icon(Icons.person), label: 'Profile'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}