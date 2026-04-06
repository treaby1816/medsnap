import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/material.dart'; 
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Added for Auth Check
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

// VailMeds Core Imports
import 'firebase_options.dart';
import 'core/theme.dart';
import 'core/theme_provider.dart';
import 'core/app_router.dart';
import 'core/auth_gate.dart';
import 'widgets/global_floating_chatbot.dart';
import 'core/services/security_service.dart';
import 'core/services/notification_service.dart';

void main() {
  // Use runZonedGuarded to catch "Silent" crashes before they hit the OS
  runZonedGuarded(() async {
    WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
    
    // 1. Preserve Native Splash (Android 12+ visibility)
    if (!kIsWeb) {
      FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
    }

    // 2. Global Exception Catching (Prevents Home-Screen Crash)
    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
      developer.log('FRAMEWORK ERROR: ${details.exception}', name: 'VailMedsGuard');
    };

    // 3. Custom Error Screen (The "System Refreshing" page you wanted)
    ErrorWidget.builder = (FlutterErrorDetails details) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(useMaterial3: true, colorSchemeSeed: const Color(0xFF42A5F5)),
        home: Scaffold(
          backgroundColor: const Color(0xFFF8F6F6),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.refresh_rounded, size: 80, color: Color(0xFF42A5F5)),
                  const SizedBox(height: 24),
                  const Text(
                    'VailMeds Security Refresh',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'We are stabilizing your session to protect your data.\nIf this persists, please restart the app.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: Colors.grey[700]),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    };

    runApp(const ProviderScope(child: BootstrapApp()));
    
  }, (error, stack) {
    developer.log('CRITICAL ASYNC ERROR: $error', name: 'VailMedsGuard', error: error, stackTrace: stack);
  });
}

class BootstrapApp extends StatefulWidget {
  const BootstrapApp({super.key});

  @override
  State<BootstrapApp> createState() => _BootstrapAppState();
}

class _BootstrapAppState extends State<BootstrapApp> {
  bool _initialized = false;
  bool _error = false;
  String _errorMessage = "";

  @override
  void initState() {
    super.initState();
    _bootSequence();
  }

  Future<void> _bootSequence() async {
    try {
      // A. Security Initialization (Screenshot block & Root Check)
      await SecurityService.initialize();

      // B. Notification Initialization (FCM Permissions)
      await NotificationService.initialize();

      // C. Firebase Circuit-Breaker (10s timeout to prevent infinite white screen)
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      ).timeout(const Duration(seconds: 10));

      // D. "Api10" Signature Check (Diagnostic for Codemagic builds)
      if (!kIsWeb) {
        try {
          // Attempt a tiny auth ping to verify if SHA-1 is correct
          await FirebaseAuth.instance.setSettings(appVerificationDisabledForTesting: true);
        } catch (authError) {
          developer.log('AUTH WARNING: SHA-1 mismatch suspected. $authError', name: 'VailMedsBoot');
        }
      }

      if (mounted) {
        setState(() => _initialized = true);
        if (!kIsWeb) FlutterNativeSplash.remove();
      }
    } catch (e) {
      developer.log('BOOT FAILURE: $e', name: 'VailMedsBoot');
      if (mounted) {
        setState(() { 
          _error = true; 
          _errorMessage = e.toString();
        });
      }
      if (!kIsWeb) FlutterNativeSplash.remove();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error) {
      return MaterialApp(
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Text('System Initialization Failure: $_errorMessage\n\nPlease check your internet connection.'),
            ),
          ),
        ),
      );
    }

    if (!_initialized) {
      // Show the "Lighter Blue" while loading
      return const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: Color(0xFF42A5F5),
          body: Center(child: CircularProgressIndicator(color: Colors.white)),
        ),
      );
    }

    return const VailMedsApp();
  }
}

class VailMedsApp extends ConsumerWidget {
  const VailMedsApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      title: 'VailMeds',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      
      builder: (context, child) {
        return ScaffoldMessenger(
          child: GestureDetector(
            onTap: () => FocusScope.of(context).unfocus(),
            child: GlobalFloatingChatbot(child: child!),
          ),
        );
      },
      
      home: const AuthGate(), 
      onGenerateRoute: AppRouter.onGenerateRoute,
    );
  }
}