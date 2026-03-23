import 'package:flutter/material.dart';

// --- AUTH & ONBOARDING ---
export 'auth/presentation/screens/splash_screen.dart';
export 'auth/presentation/screens/welcome_screen.dart';
export 'auth/presentation/screens/gateway_screen.dart';
export 'auth/presentation/screens/registration_screen.dart';
export 'auth/presentation/screens/onboarding_screen.dart';
export 'auth/presentation/screens/success_screen.dart';
export 'auth/presentation/screens/support_screen.dart';
export 'auth/presentation/screens/policy_screen.dart';

// --- PHARMACY SCREENS ---
export 'pharmacy/presentation/screens/verification_screen.dart';
export 'pharmacy/presentation/screens/pharmacy_verification_screen.dart';
export 'pharmacy/presentation/screens/pharmacy_dashboard_screen.dart';
export 'pharmacy/presentation/screens/pharmacy_main_screen.dart';
export 'pharmacy/presentation/screens/pharmacy_logs_screen.dart';
export 'pharmacy/presentation/screens/pharmacy_support_screen.dart';
export 'pharmacy/presentation/screens/pharmacy_profile_screen.dart';

// --- PATIENT & FEATURE SCREENS ---
export 'patient/presentation/screens/home_screen.dart'; // Exporting HomeScreen
export 'patient/presentation/screens/product_screen.dart';
export 'patient/patient_search_screen.dart'; // Added Search export
export 'patient/presentation/screens/patient_profile_screen.dart'; // Added Profile export
export 'patient/orders_screen.dart'; // Added Orders export
export 'scan/scan_prescription_screen.dart';

// --- UPDATED NEARBY PATH ---
export 'patient/nearby_facilities_screen.dart'; 
export 'patient/chat_screen.dart';

// --- GLOBAL PLACEHOLDERS (Keep these only if the actual files aren't ready) ---
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});
  @override
  Widget build(BuildContext context) => const Scaffold(body: Center(child: Text('Dashboard Screen')));
}

// Note: I'm keeping this here, but your 'PatientProfileScreen' export above will take priority 
// if you've created that file.
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});
  @override
  Widget build(BuildContext context) => const Scaffold(body: Center(child: Text('Profile Screen')));
}