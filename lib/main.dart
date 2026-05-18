import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/material.dart'; 
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// VailMeds Core Imports
import 'firebase_options.dart';
import 'core/theme.dart';
import 'core/theme_provider.dart';
import 'core/app_router.dart';
import 'widgets/global_floating_chatbot.dart';
import 'core/services/security_service.dart';
import 'core/services/notification_service.dart';

void main() {
  runZonedGuarded(() async {
    WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
    
    // Load environment variables
    await dotenv.load(fileName: '.env');

    // Initialize Supabase (Primary Database + Auth)
    await Supabase.initialize(
      url: dotenv.env['SUPABASE_URL']!,
      anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
    );
    
    if (!kIsWeb) {
      FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
    }

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
      // 1. Firebase MUST go first — other services depend on it
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      ).timeout(const Duration(seconds: 15));

      // 2. Security (Root check & Screenshot block) — already web-safe
      await SecurityService.initialize();

      // 3. Notifications — skip on web (FCM push requires native)
      if (!kIsWeb) {
        await NotificationService.initialize();
      }

      if (mounted) {
        setState(() {
          _initialized = true;
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
          // Still allow the app to render on error so user isn't stuck
          _initialized = true;
          if (!kIsWeb) {
            FlutterNativeSplash.remove();
          }
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized && !kIsWeb) {
      // On mobile, the native splash is already visible via FlutterNativeSplash.preserve()
      return const SizedBox.shrink();
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
      navigatorObservers: [AppRouteObserver(ref)],
      initialRoute: AppRouter.splash,
      onGenerateRoute: AppRouter.onGenerateRoute,
      builder: (context, child) {
        return Overlay(
          initialEntries: [
            OverlayEntry(builder: (context) => child ?? const SizedBox.shrink()),
            OverlayEntry(
              builder: (context) => Directionality(
                textDirection: TextDirection.ltr,
                child: GlobalFloatingChatbot(child: const SizedBox.shrink()),
              ),
            ),
          ],
        );
      },
    );
  }
}