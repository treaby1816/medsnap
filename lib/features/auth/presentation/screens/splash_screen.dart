import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart'; 
import 'package:google_fonts/google_fonts.dart';
import 'package:vail_meds_v2/core/theme.dart';
import 'package:vail_meds_v2/core/providers.dart'; 

class SplashScreen extends ConsumerStatefulWidget { 
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  bool _precached = false;

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500), // Fast & snappy
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );

    _pulseController = AnimationController(
        vsync: this, 
        duration: const Duration(milliseconds: 1800)
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _controller.forward();
    _handleNavigation();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_precached) {
      _precached = true;
      // Precache all assets asynchronously to prevent transition lag
      precacheImage(const AssetImage('assets/images/logo2.png'), context).catchError((_) {});
      precacheImage(const AssetImage('assets/images/mobile1.jpg'), context).catchError((_) {});
      precacheImage(const AssetImage('assets/images/mobile2.jpg'), context).catchError((_) {});
      precacheImage(const AssetImage('assets/images/mobile3.jpg'), context).catchError((_) {});
      precacheImage(const AssetImage('assets/images/pharmacist_patient2.jpg'), context).catchError((_) {});
      precacheImage(const AssetImage('assets/images/desktop2.jpg'), context).catchError((_) {});
      precacheImage(const AssetImage('assets/images/desktop3.jpg'), context).catchError((_) {});
    }
  }

  Future<void> _handleNavigation() async {
    // 1. Wait for the beautiful 2-second logo build animation to complete
    await _controller.forward();

    // Add a pause to let the user admire the splash screen before transitioning
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    // 2. STATE TRANSITION: We update the onboarding stage to 'welcome'.
    // The AuthGate (watching this provider) will automatically swap 
    // this SplashScreen for the WelcomeScreen.
    ref.read(onboardingStageProvider.notifier).state = 'welcome';
  }

  @override
  void dispose() {
    _controller.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.primaryColor,
      body: Stack(
        children: [
          // Background decorative rings
          Positioned(
            top: -120,
            right: -80,
            child: _buildRing(300),
          ),
          Positioned(
            bottom: -100,
            left: -60,
            child: _buildRing(250),
          ),

          Center(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: ScaleTransition(
                scale: _scaleAnimation,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                // High-Fidelity Logo (Bare for Professional Appearance)
                Center(
                  child: ScaleTransition(
                    scale: _pulseAnimation,
                    child: Image.asset(
                      'assets/images/logo2.png',
                      width: 180,
                      height: 180,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => Center(
                        child: Text(
                          'V',
                          style: GoogleFonts.inter(
                            fontSize: 64,
                            fontWeight: FontWeight.w900,
                            color: AppTheme.primaryColor,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                    const SizedBox(height: 32),
                    Text(
                      'VailMeds',
                      style: GoogleFonts.inter(
                        fontSize: 42,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        letterSpacing: -1.0,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Premium Healthcare Delivery',
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                        fontStyle: FontStyle.italic,
                        color: Colors.white.withValues(alpha: 0.85),
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 20),
                    // Loading indicator
                    const SizedBox(
                      width: 40,
                      child: LinearProgressIndicator(
                        backgroundColor: Colors.white24,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                        minHeight: 2,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRing(double size) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(
          // UPDATED: Using withOpacity for backward compatibility
          color: Colors.white.withValues(alpha: 0.1),
          width: 2,
        ),
      ),
    );
  }
}
