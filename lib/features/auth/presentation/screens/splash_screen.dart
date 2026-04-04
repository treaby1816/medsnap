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
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );

    _controller.forward();
    _handleNavigation();
  }

  Future<void> _handleNavigation() async {
    // 1. Show the beautiful animation without unnecessary artificial delay
    await _controller.forward();

    if (!mounted) return;

    // 2. STATE TRANSITION: We update the onboarding stage to 'welcome'.
    // The AuthGate (watching this provider) will automatically swap 
    // this SplashScreen for the WelcomeScreen.
    ref.read(onboardingStageProvider.notifier).state = 'welcome';
  }

  @override
  void dispose() {
    _controller.dispose();
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
                  child: Image.asset(
                    'assets/images/logo.png',
                    width: 140,
                    height: 140,
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
                    const SizedBox(height: 12),
                    // Optional: Loading indicator to signal progress
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
