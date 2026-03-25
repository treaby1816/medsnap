import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// 1. Core Providers
import 'package:vail_meds_v2/core/providers.dart';

// 2. Auth Feature Screens 
// UPDATED: Added /presentation/screens/ to the paths to match Flutter structure
import 'package:vail_meds_v2/features/auth/presentation/screens/splash_screen.dart';
import 'package:vail_meds_v2/features/auth/presentation/screens/welcome_screen.dart';
import 'package:vail_meds_v2/features/auth/presentation/screens/gateway_screen.dart';  

// 3. Home Feature Screens
import 'package:vail_meds_v2/features/home/presentation/screens/main_navigation_screen.dart'; 

class AuthGate extends ConsumerWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the onboarding stage ('splash', 'welcome', or 'auth')
    final stage = ref.watch(onboardingStageProvider);
    
    // Watch the Firebase Auth status
    final authState = ref.watch(authStateProvider);

    // --- STAGE 1: THE SPLASH SCREEN ---
    if (stage == 'splash') {
      return const SplashScreen();
    }

    // --- STAGE 2: THE WELCOME SCREEN ---
    if (stage == 'welcome') {
      return const WelcomeScreen();
    }

    // --- STAGE 3: THE AUTHENTICATION GATE ---
    return authState.when(
      data: (user) {
        if (user != null) {
          return const MainNavigationScreen(); 
        } else {
          return const GatewayScreen(); 
        }
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