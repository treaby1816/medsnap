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
import 'core/services/cache_service.dart';
import 'widgets/global_floating_chatbot.dart';
import 'core/services/security_service.dart';
import 'core/services/notification_service.dart';

void main() {
  runZonedGuarded(() async {
    final WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
    
    // Load environment variables
    await dotenv.load(fileName: '.env');

    // Initialize Supabase (Primary Database + Auth)
    await Supabase.initialize(
      url: dotenv.env['SUPABASE_URL']!,
      anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
      authOptions: FlutterAuthClientOptions(
        authFlowType: kIsWeb ? AuthFlowType.implicit : AuthFlowType.pkce,
      ),
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
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _bootSequence();
  }

  Future<void> _bootSequence() async {
    try {
      // Firebase — only required on native platforms (FCM, Analytics, etc.)
      if (!kIsWeb) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        ).timeout(const Duration(seconds: 15));
      }

      // Initialize Cache
      await CacheService.initialize();

      // Security (Root check & Screenshot block) — already web-safe (no-ops)
      await SecurityService.initialize();

      // Push Notifications — skip on web (FCM push requires native)
      if (!kIsWeb) {
        await NotificationService.initialize();
      }
    } catch (e) {
      developer.log('BOOT ERROR: $e', name: 'VailMedsGuard');
    } finally {
      if (mounted) {
        setState(() {
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
    // On web, render the app immediately — Supabase is already initialized in main().
    // On mobile, wait for Firebase + services before removing native splash.
    if (!_initialized && !kIsWeb) {
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
        return Stack(
          children: [
            if (child != null) child,
            const Directionality(
              textDirection: TextDirection.ltr,
              child: GlobalFloatingChatbot(child: SizedBox.shrink()),
            ),
          ],
        );
      },
    );
  }
}