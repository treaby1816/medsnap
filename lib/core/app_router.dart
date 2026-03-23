import 'package:flutter/material.dart';

// Core & Enums
import '../core/constants/enums.dart';

// Features - Auth
import '../features/auth/login_screen.dart'; 

// Features - Navigation
import '../features/main_navigation_screen.dart';

// Features - Barrel File (Make sure your screens are exported here)
import '../features/screens.dart' hide ProductScreen, OrdersScreen; 

// Features - Patient (Direct Imports to avoid conflicts)
import '../features/patient/job_board_screen.dart';
import '../features/patient/product_screen.dart'; 
import '../features/patient/orders_screen.dart';
import '../features/patient/order_history_screen.dart';

// Features - Pharmacy
import '../features/pharmacy/pharmacy_orders_screen.dart';

class AppRouter {
  // --- AUTH & CORE ROUTES ---
  static const String splash = '/';
  static const String welcome = '/welcome';
  static const String gateway = '/gateway';
  static const String registration = '/registration';
  static const String verification = '/verification';
  static const String pharmacyVerification = '/pharmacy-verification';
  static const String login = '/login';
  static const String onboarding = '/onboarding';
  static const String mainNav = '/main';
  static const String support = '/support';
  static const String privacy = '/privacy';
  static const String terms = '/terms';

  // --- PATIENT ROUTES ---
  static const String home = '/home';
  static const String patientDashboard = '/patient-dashboard';
  static const String patientSearch = '/patient-search';
  static const String scan = '/scan';
  static const String nearby = '/nearby'; // THIS POINTS TO NEARBY FACILITIES
  static const String profile = '/profile';
  static const String orders = '/orders'; 
  static const String product = '/product';
  static const String success = '/success';
  static const String jobBoard = '/job-board';
  static const String orderHistory = '/order-history';
  static const String chat = '/chat';

  // --- PHARMACY ROUTES ---
  static const String pharmacyDashboard = '/pharmacy-dashboard';
  static const String pharmacyOrders = '/pharmacy-orders';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      // --- Auth & Core ---
      case splash:
        return MaterialPageRoute(builder: (_) => const SplashScreen());
      case welcome:
        return MaterialPageRoute(builder: (_) => const WelcomeScreen());
      case gateway:
        return MaterialPageRoute(builder: (_) => const GatewayScreen());
      case login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case registration:
        return MaterialPageRoute(builder: (_) => const RegistrationScreen());
      case verification:
        return MaterialPageRoute(builder: (_) => const VerificationScreen());
      case pharmacyVerification:
        return MaterialPageRoute(builder: (_) => const PharmacyVerificationScreen());
      case onboarding:
        return MaterialPageRoute(builder: (_) => const OnboardingScreen());
      case mainNav:
        return MaterialPageRoute(builder: (_) => const MainNavigationScreen());
      case support:
        return MaterialPageRoute(builder: (_) => const SupportScreen());
      case privacy:
        return MaterialPageRoute(
          builder: (_) => const PolicyScreen(
            title: 'Privacy Policy',
            content: 'VailMeds is committed to protecting your privacy. This policy explains how we collect, use, and safeguard your data, including health information protected under HIPAA. We use your data to provide medical services and ensure a secure experience. We never sell your personal information to third parties.',
          ),
        );
      case terms:
        return MaterialPageRoute(
          builder: (_) => const PolicyScreen(
            title: 'Terms of Service',
            content: 'By using VailMeds, you agree to our terms and conditions. Our platform provides bridge services between patients and pharmacies. We are not a medical provider but a technology facilitator. Users must provide accurate information and comply with local medical regulations.',
          ),
        );

      // --- Patient Features ---
      case home:
        return MaterialPageRoute(builder: (_) => const MainNavigationScreen());
      case patientDashboard:
        return MaterialPageRoute(builder: (_) => const MainNavigationScreen());
      case patientSearch:
        return MaterialPageRoute(builder: (_) => const PatientSearchScreen());
      case scan:
        return MaterialPageRoute(builder: (_) => const ScanPrescriptionScreen());
      
      // LINKING TO YOUR BEST SCREEN
      case nearby:
        return MaterialPageRoute(builder: (_) => const NearbyFacilitiesScreen());
        
      case profile:
        return MaterialPageRoute(builder: (_) => const PatientProfileScreen());
      case orders:
        return MaterialPageRoute(builder: (_) => const OrdersScreen());
      case jobBoard:
        return MaterialPageRoute(builder: (_) => const JobBoardScreen());
      case orderHistory:
        return MaterialPageRoute(builder: (_) => const OrderHistoryScreen());
      case chat:
        return MaterialPageRoute(builder: (_) => const ChatScreen());
      
      // --- Dynamic Routes ---
      case product:
        final medData = settings.arguments as Map<String, dynamic>? ?? {};
        return MaterialPageRoute(
          builder: (_) => ProductScreen(productData: medData),
        );

      case success:
        final userType = settings.arguments as UserType? ?? UserType.patient;
        return MaterialPageRoute(
          builder: (_) => SuccessScreen(userType: userType),
        );

      // --- Pharmacy Features ---
      case pharmacyDashboard:
        return PageRouteBuilder(
          pageBuilder: (context, animation, secondaryAnimation) => const PharmacyDashboardScreen(),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            const begin = Offset(1.0, 0.0);
            const end = Offset.zero;
            const curve = Curves.easeOutQuart;
            var tween = Tween(begin: begin, end: end).chain(CurveTween(curve: curve));
            return SlideTransition(
              position: animation.drive(tween),
              child: child,
            );
          },
          transitionDuration: const Duration(milliseconds: 600),
        );
      case pharmacyOrders:
        return MaterialPageRoute(builder: (_) => const PharmacyOrdersScreen());

      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            appBar: AppBar(title: const Text("Navigation Error")),
            body: Center(child: Text('No route defined for ${settings.name}')),
          ),
        );
    }
  }
}