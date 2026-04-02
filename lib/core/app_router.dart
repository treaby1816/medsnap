import 'package:flutter/material.dart';

// Core & Enums
import 'package:vail_meds_v2/core/constants/enums.dart';
import 'package:vail_meds_v2/core/models/product_model.dart';

// Features - Auth
import 'package:vail_meds_v2/features/auth/presentation/screens/login_screen.dart'; 

// Features - Navigation
import 'package:vail_meds_v2/features/home/presentation/screens/main_navigation_screen.dart';
import 'package:vail_meds_v2/features/screens.dart';

// Features - Pharmacy
import 'package:vail_meds_v2/features/pharmacy/pharmacy_orders_screen.dart';

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
  static const String checkout = '/checkout';

  // --- PHARMACY ROUTES ---
  static const String pharmacyDashboard = '/pharmacy-dashboard';
  static const String pharmacyOrders = '/pharmacy-orders';

  // --- ADMIN ROUTES ---
  static const String adminDashboard = '/admin-dashboard';
  static const String adminApprovals = '/admin-approvals';
  static const String adminSupport = '/admin-support';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      // --- Auth & Core ---
      case splash:
        return MaterialPageRoute(builder: (_) => const SplashScreen(), settings: settings);
      case welcome:
        return MaterialPageRoute(builder: (_) => const WelcomeScreen(), settings: settings);
      case gateway:
        return MaterialPageRoute(builder: (_) => const GatewayScreen(), settings: settings);
      case login:
        return MaterialPageRoute(builder: (_) => const LoginScreen(), settings: settings);
      case registration:
        final roleArg = (settings.arguments as String?) ?? 'patient';
        return MaterialPageRoute(builder: (_) => RegistrationScreen(initialRole: roleArg), settings: settings);
      case verification:
        return MaterialPageRoute(builder: (_) => const VerificationScreen(), settings: settings);
      case pharmacyVerification:
        return MaterialPageRoute(builder: (_) => const PharmacyVerificationScreen(), settings: settings);
      case onboarding:
        return MaterialPageRoute(builder: (_) => const OnboardingScreen(), settings: settings);
      case mainNav:
        return MaterialPageRoute(builder: (_) => const MainNavigationScreen(), settings: settings);
      case support:
        return MaterialPageRoute(builder: (_) => const SupportScreen(), settings: settings);
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
          settings: settings,
        );

      // --- Patient Features ---
      case home:
        return MaterialPageRoute(builder: (_) => const MainNavigationScreen(), settings: settings);
      case patientDashboard:
        return MaterialPageRoute(builder: (_) => const MainNavigationScreen(), settings: settings);
      case patientSearch:
        return MaterialPageRoute(builder: (_) => const PatientSearchScreen(), settings: settings);
      case scan:
        return MaterialPageRoute(builder: (_) => const ScanPrescriptionScreen(), settings: settings);
      
      // LINKING TO YOUR BEST SCREEN
      case nearby:
        return MaterialPageRoute(builder: (_) => const NearbyFacilitiesScreen(), settings: settings);
        
      case profile:
        return MaterialPageRoute(builder: (_) => const PatientProfileScreen(), settings: settings);
      case orders:
        return MaterialPageRoute(builder: (_) => const OrdersScreen(), settings: settings);
      case jobBoard:
        return MaterialPageRoute(builder: (_) => const JobBoardScreen(), settings: settings);
      case orderHistory:
        return MaterialPageRoute(builder: (_) => const OrderHistoryScreen(), settings: settings);
      case chat:
        final args = settings.arguments as Map<String, dynamic>;
        return MaterialPageRoute(
          builder: (_) => ChatScreen(
            receiverId: args['receiverId'],
            receiverName: args['receiverName'],
          ),
          settings: settings,
        );
      case checkout:
        return MaterialPageRoute(builder: (_) => const CheckoutScreen(), settings: settings);
      
      // --- Dynamic Routes ---
      case product:
        final productArg = settings.arguments as Product;
        return MaterialPageRoute(
          builder: (_) => ProductScreen(product: productArg),
          settings: settings,
        );

      case success:
        var userType = UserType.patient;
        if (settings.arguments is String) {
          userType = (settings.arguments as String).toLowerCase() == 'pharmacy' ? UserType.pharmacy : UserType.patient;
        } else if (settings.arguments is UserType) {
          userType = settings.arguments as UserType;
        }
        
        return MaterialPageRoute(
          builder: (_) => SuccessScreen(userType: userType),
          settings: settings,
        );

      // --- Pharmacy Features ---
      case pharmacyDashboard:
        return PageRouteBuilder(
          settings: settings,
          pageBuilder: (context, animation, secondaryAnimation) => const PharmacyMainScreen(),
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
        return MaterialPageRoute(builder: (_) => const PharmacyOrdersScreen(), settings: settings);

      // --- Admin Features ---
      case adminDashboard:
        return MaterialPageRoute(builder: (_) => const AdminDashboardScreen(), settings: settings);
      case adminApprovals:
        return MaterialPageRoute(builder: (_) => const PendingApprovalsScreen(), settings: settings);
      case adminSupport:
        return MaterialPageRoute(builder: (_) => const AdminSupportScreen(), settings: settings);

      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            appBar: AppBar(title: const Text("Navigation Error")),
            body: Center(child: Text('No route defined for ${settings.name}')),
          ),
          settings: settings,
        );
    }
  }
}
