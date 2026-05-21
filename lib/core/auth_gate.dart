import 'dart:developer' as developer;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:vail_meds_v2/core/models/user_profile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// 1. Core Providers
import 'package:vail_meds_v2/core/providers.dart';

// 2. Auth Feature Screens 
import 'package:vail_meds_v2/features/auth/presentation/screens/splash_screen.dart';
import 'package:vail_meds_v2/features/auth/presentation/screens/welcome_screen.dart';
import 'package:vail_meds_v2/features/auth/presentation/screens/gateway_screen.dart';  
import 'package:vail_meds_v2/core/theme.dart';

// 3. Home & Pharmacy Feature Screens
import 'package:vail_meds_v2/features/home/presentation/screens/main_navigation_screen.dart'; 
import 'package:vail_meds_v2/features/pharmacy/presentation/screens/pharmacy_main_screen.dart';
import 'package:vail_meds_v2/features/pharmacy/presentation/screens/pharmacy_verification_screen.dart';
import 'package:vail_meds_v2/features/admin/presentation/screens/admin_dashboard_screen.dart';

/// AuthGate is the root routing widget. It reactively watches auth + profile state
/// and renders the correct screen. No imperative Navigator calls are used here —
/// the Riverpod stream drives all transitions.
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
          // User is authenticated — resolve their profile to determine destination.
          final profileAsync = ref.watch(userProfileProvider);
          
          return profileAsync.when(
            data: (profile) {
              if (profile == null) {
                // Profile doesn't exist yet (e.g. first OAuth login on web).
                // Show ProfileSetupGate which will create it, then the stream
                // will emit the new profile and this .when() reruns automatically.
                return ProfileSetupGate(user: user);
              }
              if (profile.role == 'admin' || localRole == 'admin') {
                return const AdminDashboardScreen();
              }
              if (profile.role == 'pharmacy') {
                return !profile.isAdminApproved 
                    ? const PharmacyVerificationScreen() 
                    : const PharmacyMainScreen();
              }
              return const MainNavigationScreen();
            },
            loading: () => const Scaffold(
              backgroundColor: Colors.white,
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
        backgroundColor: Colors.white,
        body: Center(
          child: CircularProgressIndicator(color: AppTheme.primaryColor),
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

/// ProfileSetupGate handles the one-time profile creation for users who
/// authenticate via OAuth redirect (e.g. Google Sign-In on Web).
///
/// After the profile is created, the `userProfileProvider` stream automatically
/// emits the new profile, which causes AuthGate to rebuild and route the user
/// to their correct dashboard. No imperative navigation is needed.
class ProfileSetupGate extends ConsumerStatefulWidget {
  final User user;
  const ProfileSetupGate({super.key, required this.user});

  @override
  ConsumerState<ProfileSetupGate> createState() => _ProfileSetupGateState();
}

class _ProfileSetupGateState extends ConsumerState<ProfileSetupGate> {
  bool _creating = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _createProfileIfNeeded();
  }

  Future<void> _createProfileIfNeeded() async {
    if (_creating) return;
    setState(() {
      _creating = true;
      _errorMessage = null;
    });
    
    try {
      final authService = ref.read(authServiceProvider);
      final user = widget.user;
      
      developer.log(
        'ProfileSetupGate: Creating profile for ${user.email}',
        name: 'VailMeds',
      );
      
      // Read the pending role saved before the OAuth redirect
      String pendingRole = 'patient';
      if (kIsWeb) {
        pendingRole = authService.getWebPendingRole() ?? 'patient';
      } else {
        pendingRole = await authService.getPendingRole() ?? 'patient';
      }
      
      // Auto-detect admin emails
      if (user.email?.endsWith('@vailmeds.com') ?? false) {
        pendingRole = 'admin';
      }
      
      final profile = UserProfile(
        uid: user.id,
        email: user.email ?? '',
        name: (user.userMetadata?['full_name'] ?? user.userMetadata?['name']) ?? 'New User',
        role: pendingRole,
        isVerified: pendingRole == 'patient' || pendingRole == 'admin',
      );
      
      await authService.createUserProfile(profile);
      
      // Clean up stored pending role
      if (kIsWeb) {
        authService.clearWebPendingRole();
      } else {
        await authService.clearPendingRole();
      }
      
      // Update the local role notifier so AuthGate picks it up immediately
      if (mounted) {
        ref.read(userRoleProvider.notifier).setRole(pendingRole);
      }
      
      developer.log(
        'ProfileSetupGate: Profile created successfully (role: $pendingRole)',
        name: 'VailMeds',
      );
      // No navigation needed — the userProfileProvider stream will emit
      // the new profile and AuthGate will rebuild automatically.
      
    } catch (e) {
      developer.log('ProfileSetupGate error: $e', name: 'VailMeds');
      if (mounted) {
        setState(() => _errorMessage = e.toString());
      }
    } finally {
      if (mounted) {
        setState(() => _creating = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (_errorMessage != null) ...[
              const Icon(Icons.error_outline_rounded, color: Colors.redAccent, size: 48),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  'Profile setup failed. Please try again.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: _createProfileIfNeeded,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Retry'),
              ),
            ] else ...[
              const CircularProgressIndicator(color: AppTheme.primaryColor),
              const SizedBox(height: 20),
              Text(
                'Setting up your profile...',
                style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
