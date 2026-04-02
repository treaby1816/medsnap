import 'package:flutter/material.dart'; 
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Firebase & Core
import 'firebase_options.dart';
import 'core/theme.dart';
import 'core/theme_provider.dart';
import 'core/app_router.dart';
import 'core/auth_gate.dart'; // <--- NEW: Added AuthGate import

void main() async {
  // Ensure Flutter is ready before initializing Firebase
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // --- GLOBAL ERROR WRAPPER ---
  // Catches framework errors and prevents the Red Screen of Death
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('FlutterError caught: ${details.exceptionAsString()}');
  };

  // Custom error widget for release builds
  ErrorWidget.builder = (FlutterErrorDetails details) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: const Color(0xFFF8F6F6),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEC5B13).withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.warning_amber_rounded,
                    size: 40,
                    color: Color(0xFFEC5B13),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Something went wrong',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'An unexpected error occurred.\nPlease restart the app.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 15,
                    color: Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  };

  runApp(
    // ProviderScope is required for Riverpod to work
    const ProviderScope(child: VailMedsApp()),
  );
}

class VailMedsApp extends ConsumerWidget {
  const VailMedsApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Watch the theme provider for live dark/light mode switching
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      title: 'VailMeds',
      debugShowCheckedModeBanner: false,
      
      // Theme Configuration
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      
      // Routing Setup
      // initialRoute is removed so the AuthGate can control the first screen
      home: const AuthGate(), 
      onGenerateRoute: AppRouter.onGenerateRoute,
    );
  }
}
