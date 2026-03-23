import 'package:flutter/material.dart';
import 'home_screen.dart';
// Import your Search and Prescription screens here

class PatientMainWrapper extends StatefulWidget {
  const PatientMainWrapper({super.key});

  @override
  State<PatientMainWrapper> createState() => _PatientMainWrapperState();
}

class _PatientMainWrapperState extends State<PatientMainWrapper> {
  int _currentIndex = 0;

  // LIST YOUR SCREENS HERE: This is the "Master List" for testing
  final List<Widget> _pages = [
    const HomeScreen(),
    const Center(child: Text('Search Screen Implementation')), // Replace with SearchScreen()
    const Center(child: Text('Prescriptions Screen')), // Replace with PrescriptionScreen()
    const Center(child: Text('Profile Screen')),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Search'),
          BottomNavigationBarItem(icon: Icon(Icons.receipt_long), label: 'Orders'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}