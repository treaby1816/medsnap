import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/material.dart'; 
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// Firebase & Core
import 'firebase_options.dart';
import 'core/theme.dart';
import 'core/theme_provider.dart';
import 'core/app_router.dart';
import 'core/auth_gate.dart';
import 'widgets/global_floating_chatbot.dart';
import 'core/utils/web_logger.dart';

import 'package:flutter_native_splash/flutter_native_splash.dart';

void main() async {
  try {
    // Ensure Flutter is ready before doing anything else
    WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
    
    // 1. Native Splash: Only preserve on mobile to avoid web hanging
    if (!kIsWeb) {
      FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
    }
    
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
                  Text(
                    'Error details:\n${details.exceptionAsString()}',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 12,
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
      const ProviderScope(child: BootstrapApp()),
    );
    
  } catch (e, stacktrace) {
    debugPrint('FATAL INITIALIZATION ERROR: $e\n$stacktrace');
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Text(
                'Initialization Error: $e',
                style: const TextStyle(color: Colors.red, fontSize: 16),
              ),
            ),
          ),
        ),
      ),
    );
    FlutterNativeSplash.remove();
  }
}

class BootstrapApp extends StatefulWidget {
  const BootstrapApp({super.key});

  @override
  State<BootstrapApp> createState() => _BootstrapAppState();
}

class _BootstrapAppState extends State<BootstrapApp> {
  bool _initialized = false;
  bool _error = false;
  Object? _errorDetails;

  @override
  void initState() {
    super.initState();
    _initializeFirebase();
  }

  Future<void> _initializeFirebase() async {
    Timer? heartbeatTimer;
    try {
      // 1. Diagnostic Heartbeat (100ms)
      heartbeatTimer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
        developer.log('Heartbeat: Initialization pulse...', name: 'VailMedsBoot');
        WebLogger.log('Heartbeat: Critical URL/API Handshake active...');
      });

      // 2. Circuit Breaker Routing (Increased to 5 seconds)
      // EXPLICIT WEB CHECK to prevent "google-services.json missing" errors on Chrome
      if (kIsWeb) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.web,
        ).timeout(const Duration(seconds: 5));
      } else {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        ).timeout(const Duration(seconds: 5));
      }

      heartbeatTimer.cancel();
      if (mounted) {
        setState(() {
          _initialized = true;
        });
      }
      
      // Notify web boot system to clear timeout
      WebLogger.dispatchStartEvent();
      
      // Guarantee the web shield is removed exactly as the main app boots!
      if (!kIsWeb) {
        FlutterNativeSplash.remove();
      }
    } catch (e) {
      heartbeatTimer?.cancel();
      if (mounted) {
        setState(() {
          _error = true;
          _errorDetails = e;
        });
      }
      FlutterNativeSplash.remove();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(32.0),
              child: Text(
                'Failed to initialize system resources: $_errorDetails',
                style: const TextStyle(color: Colors.red),
              ),
            ),
          ),
        ),
      );
    }

    if (!_initialized) {
      // Keeps a dummy solid frame behind the splash screen so Flutter can hook in.
      return const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          backgroundColor: Color(0xFFEC5B13),
          body: SizedBox.shrink(),
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
    // Watch the theme provider for live dark/light mode switching
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      title: 'VailMeds',
      debugShowCheckedModeBanner: false,
      
      // Theme Configuration
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      
      // Global Chatbot Overlay & Tracking
      navigatorObservers: [AppRouteObserver(ref)],
      builder: (context, child) {
        return GlobalFloatingChatbot(child: child!);
      },
      
      // Routing Setup
      // initialRoute is removed so the AuthGate can control the first screen
      home: const AuthGate(), 
      onGenerateRoute: AppRouter.onGenerateRoute,
    );
  }
}
