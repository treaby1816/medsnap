import 'package:flutter/material.dart';

// Core & Enums
import 'package:vail_meds_v2/core/constants/enums.dart';
import 'package:vail_meds_v2/core/models/product_model.dart';

// Features - Auth
import 'package:vail_meds_v2/features/auth/presentation/screens/login_screen.dart'; 

// Features - Navigation
import 'package:vail_meds_v2/features/home/presentation/screens/main_navigation_screen.dart';
import 'package:vail_meds_v2/features/patient/presentation/screens/health_news_screen.dart';
import 'package:vail_meds_v2/features/screens.dart';
import 'package:vail_meds_v2/core/auth_gate.dart';



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
  static const String orderHistory = '/order-history';
  static const String chat = '/chat';
  static const String checkout = '/checkout';
  static const String healthNews = '/health-news';
  static const String jobBoard = '/job-board';

  // --- PHARMACY ROUTES ---
  static const String pharmacyDashboard = '/pharmacy-dashboard';
  static const String pharmacyOrders = '/pharmacy-orders';

  // --- ADMIN ROUTES ---
  static const String adminDashboard = '/admin-dashboard';
  static const String adminApprovals = '/admin-approvals';
  static const String adminSupport = '/admin-support';

  /// Maps a role string from route arguments to the [UserType] enum.
  static UserType _roleToUserType(String role) {
    switch (role.toLowerCase()) {
      case 'pharmacy':
        return UserType.pharmacy;
      case 'admin':
        return UserType.admin;
      case 'super_admin':
        return UserType.super_admin;
      default:
        return UserType.patient;
    }
  }

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      // --- Auth & Core ---
      case splash:
        return MaterialPageRoute(builder: (_) => const AuthGate(), settings: settings);
      case '/admin': // Deep link entry point
        return MaterialPageRoute(builder: (_) => const AdminDashboardScreen(), settings: settings);
      case welcome:
        return MaterialPageRoute(builder: (_) => const WelcomeScreen(), settings: settings);
      case gateway:
        return MaterialPageRoute(builder: (_) => const GatewayScreen(), settings: settings);
      case login:
        return MaterialPageRoute(builder: (_) => const LoginScreen(), settings: settings);
      case registration:
        String? roleArg;
        if (settings.arguments is String) {
          roleArg = settings.arguments as String;
        } else if (settings.arguments is Map) {
          roleArg = (settings.arguments as Map)['role'] as String?;
        }
        return MaterialPageRoute(builder: (_) => RegistrationScreen(initialRole: roleArg ?? 'patient'), settings: settings);
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
            isPrivacy: true,
          ),
        );
      case terms:
        return MaterialPageRoute(
          builder: (_) => const PolicyScreen(
            title: 'Terms of Service',
            isPrivacy: false,
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

      case orderHistory:
        return MaterialPageRoute(builder: (_) => const OrderHistoryScreen(), settings: settings);
      case chat:
        final args = settings.arguments;
        if (args is Map) {
          return MaterialPageRoute(
            builder: (_) => ChatScreen(
              receiverId: args['receiverId'] ?? '',
              receiverName: args['receiverName'] ?? 'Support',
            ),
            settings: settings,
          );
        }
        return MaterialPageRoute(builder: (_) => const Scaffold(body: Center(child: Text("Invalid Chat Arguments"))));
      case checkout:
        return MaterialPageRoute(builder: (_) => const CheckoutScreen(), settings: settings);
      case healthNews:
        return MaterialPageRoute(builder: (_) => const HealthNewsScreen(), settings: settings);
      case jobBoard:
        return MaterialPageRoute(builder: (_) => const JobBoardScreen(), settings: settings);
      
      // --- Dynamic Routes ---
      case product:
        if (settings.arguments is Product) {
          return MaterialPageRoute(
            builder: (_) => ProductScreen(product: settings.arguments as Product),
            settings: settings,
          );
        }
        return MaterialPageRoute(builder: (_) => const Scaffold(body: Center(child: Text("Product not found"))));

      case success:
        var userType = UserType.patient;
        var isReturningUser = false;
        if (settings.arguments is String) {
          userType = _roleToUserType(settings.arguments as String);
        } else if (settings.arguments is UserType) {
          userType = settings.arguments as UserType;
        } else if (settings.arguments is Map) {
          final args = settings.arguments as Map;
          final role = (args['role'] as String?) ?? 'patient';
          userType = _roleToUserType(role);
          isReturningUser = (args['isReturningUser'] as bool?) ?? false;
        }
        
        return MaterialPageRoute(
          builder: (_) => SuccessScreen(userType: userType, isReturningUser: isReturningUser),
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
        // Intercept Supabase OAuth Web Redirect fragments
        if (settings.name != null && (settings.name!.contains('access_token=') || settings.name!.contains('id_token=') || settings.name!.contains('error='))) {
          return MaterialPageRoute(builder: (_) => const AuthGate(), settings: settings);
        }
        
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
