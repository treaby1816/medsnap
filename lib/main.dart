import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/material.dart'; 
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

// Firebase & Core
import 'firebase_options.dart';
import 'core/theme.dart';
import 'core/theme_provider.dart';
import 'core/app_router.dart';
import 'widgets/global_floating_chatbot.dart';
import 'core/services/security_service.dart';
import 'core/services/notification_service.dart';

void main() {
  runZonedGuarded(() async {
    // 1. Core Native Binding (Crucial for first frame)
    WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
    
    // 2. Native Splash Preservation (Android-specific boot smoothness)
    if (!kIsWeb) {
      FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
    }

    // 3. Global Framework Error Reporting
    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.presentError(details);
      developer.log('Framework Error: ${details.exceptionAsString()}', name: 'VailMedsGuard');
    };

    // 4. Release-Mode Error Screen (Anti-Abrupt Exit)
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
                  const Icon(Icons.refresh_rounded, size: 60, color: Color(0xFF42A5F5)),
                  const SizedBox(height: 24),
                  const Text(
                    'System Refreshing',
                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1E293B)),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'We\'re restoring your session. Please hold on.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
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
    developer.log('ASYNC ERROR CAUGHT BY ZONE: $error', name: 'VailMedsGuard', error: error, stackTrace: stack);
  });
}

class BootstrapApp extends StatefulWidget {
  const BootstrapApp({super.key});

  @override
  State<BootstrapApp> createState() => _BootstrapAppState();
}

class _BootstrapAppState extends State<BootstrapApp> {
  // ignore: unused_field
  bool _initialized = false;
  // ignore: unused_field
  bool _error = false;
  // ignore: unused_field
  Object? _errorDetails;

  @override
  void initState() {
    super.initState();
    _bootSequence();
  }

  Future<void> _bootSequence() async {
    try {
      // 1. Initialise Security (Root check & Screenshot block)
      await SecurityService.initialize();

      // 2. Initialise Notifications (Permissions & FCM)
      await NotificationService.initialize();

      // 3. Circuit-Breaking Firebase Init
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      ).timeout(const Duration(seconds: 15));

      if (mounted) {
        setState(() {
          _initialized = true;
          // After a short delay, remove native splash
          if (!kIsWeb) {
            FlutterNativeSplash.remove();
          }
        });
      }
    } catch (e) {
      developer.log('BOOT ERROR: $e', name: 'VailMedsGuard');
      if (mounted) {
        setState(() {
          _error = true;
          _errorDetails = e;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return const VailMedsApp();
  }
}

class VailMedsApp extends ConsumerWidget {
  const VailMedsApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      title: 'VailMeds v2',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      initialRoute: AppRouter.splash,
      onGenerateRoute: AppRouter.onGenerateRoute,
      builder: (context, child) {
        return GlobalFloatingChatbot(child: child!);
      },
    );
  }
}
