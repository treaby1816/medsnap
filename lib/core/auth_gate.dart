import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// 1. Core Providers
import 'package:vail_meds_v2/core/providers.dart';

// 2. Auth Feature Screens 
// UPDATED: Added /presentation/screens/ to the paths to match Flutter structure
import 'package:vail_meds_v2/features/auth/presentation/screens/splash_screen.dart';
import 'package:vail_meds_v2/features/auth/presentation/screens/welcome_screen.dart';
import 'package:vail_meds_v2/features/auth/presentation/screens/gateway_screen.dart';  
import 'package:vail_meds_v2/core/theme.dart';

// 3. Home & Pharmacy Feature Screens
import 'package:vail_meds_v2/features/home/presentation/screens/main_navigation_screen.dart'; 
import 'package:vail_meds_v2/features/pharmacy/presentation/screens/pharmacy_main_screen.dart';
import 'package:vail_meds_v2/features/pharmacy/presentation/screens/pharmacy_verification_screen.dart';
import 'package:vail_meds_v2/features/admin/presentation/screens/admin_dashboard_screen.dart';

class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // --- STAGE 0: ADMIN BYPASS CHECK (Highest Priority for Developers/Auditors) ---
    final localRole = ref.watch(userRoleProvider);
    if (localRole == 'admin') return const AdminDashboardScreen();

    // --- STAGE 1: AUTHENTICATION STATUS ---
    final authState = ref.watch(authStateProvider);

    return authState.when(
      data: (user) {
        if (user != null) {
          // If authenticated, skip splash/welcome and go straight to profile-based routing
          final profileAsync = ref.watch(userProfileProvider);
          
          return profileAsync.when(
            data: (profile) {
              if (profile == null) return const GatewayScreen();
              if (profile.role == 'admin' || localRole == 'admin') return const AdminDashboardScreen();
              if (profile.role == 'pharmacy') {
                return !profile.isAdminApproved 
                    ? const PharmacyVerificationScreen() 
                    : const PharmacyMainScreen();
              }
              return const MainNavigationScreen();
            },
            loading: () => const Scaffold(
              body: Center(child: CircularProgressIndicator(color: AppTheme.primaryColor)),
            ),
            error: (err, stack) => Scaffold(
              body: Center(child: Text('Profile Sync Error: $err')),
            ),
          );
        }

        // --- STAGE 2: ONBOARDING FLOW (Only if NOT authenticated) ---
        final stage = ref.watch(onboardingStageProvider);
        if (stage == 'splash') return const SplashScreen();
        if (stage == 'welcome') return const WelcomeScreen();

        // --- STAGE 3: LOGIN/GATEWAY ---
        return const GatewayScreen();
      },
      loading: () => const Scaffold(
        body: Center(
          child: CircularProgressIndicator(
            color: Colors.blueAccent,
            strokeWidth: 3,
          ),
        ),
      ),
      error: (error, stack) => Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Text(
              'Authentication Error: $error',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
          ),
        ),
      ),
    );
  }
}
