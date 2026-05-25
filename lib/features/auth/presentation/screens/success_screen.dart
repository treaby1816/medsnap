import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/app_router.dart';
import '../../../../core/theme.dart';
import '../../../../core/constants/enums.dart';

/// SuccessScreen — shown after every successful signup or login.
///
/// Displays a branded confirmation with an animated checkmark and progress bar,
/// then auto-redirects to the correct dashboard after [_kAutoRedirectDuration].
///
/// Routing matrix:
///   • Patient (new)       → MainNavigationScreen (/main)
///   • Patient (returning) → MainNavigationScreen (/main)
///   • Pharmacy (new)      → PharmacyVerificationScreen (/pharmacy-verification)
///   • Pharmacy (returning)→ PharmacyDashboard (/pharmacy-dashboard)
///   • Admin               → AdminDashboardScreen (/admin-dashboard)
class SuccessScreen extends ConsumerStatefulWidget {
  final UserType userType;
  final bool isReturningUser;

  const SuccessScreen({
    super.key,
    required this.userType,
    this.isReturningUser = false,
  });

  @override
  ConsumerState<SuccessScreen> createState() => _SuccessScreenState();
}

class _SuccessScreenState extends ConsumerState<SuccessScreen>
    with TickerProviderStateMixin {
  /// Duration before auto-redirect fires.
  static const _kAutoRedirectDuration = Duration(seconds: 3);

  /// Duration for the fade-out transition before navigation.
  static const _kFadeOutDuration = Duration(milliseconds: 400);

  late final AnimationController _progressController;
  late final AnimationController _checkController;
  late final AnimationController _fadeOutController;

  late final Animation<double> _progressAnimation;
  late final Animation<double> _checkAnimation;
  late final Animation<double> _fadeOutAnimation;

  Timer? _redirectTimer;
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();

    // Checkmark draw animation
    _checkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _checkAnimation = CurvedAnimation(
      parent: _checkController,
      curve: Curves.easeOutCirc,
    );

    // Progress bar animation
    _progressController = AnimationController(
      vsync: this,
      duration: _kAutoRedirectDuration,
    );
    _progressAnimation = Tween<double>(begin: 0.1, end: 1.0).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeInOut),
    );

    // Fade-out animation (fires just before navigation)
    _fadeOutController = AnimationController(
      vsync: this,
      duration: _kFadeOutDuration,
    );
    _fadeOutAnimation = Tween<double>(begin: 1.0, end: 0.0).animate(
      CurvedAnimation(parent: _fadeOutController, curve: Curves.easeIn),
    );

    // Schedule the auto-redirect
    _redirectTimer = Timer(_kAutoRedirectDuration, _beginFadeAndNavigate);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkController.forward();
      _progressController.forward();
    });
  }

  /// Resolves the target route based on [userType] and [isReturningUser].
  String _resolveTargetRoute() {
    switch (widget.userType) {
      case UserType.admin:
      case UserType.super_admin:
        return AppRouter.adminDashboard;

      case UserType.pharmacy:
        // New pharmacies must go through verification first.
        // Returning (already-verified) pharmacies go straight to dashboard.
        return widget.isReturningUser
            ? AppRouter.pharmacyDashboard
            : AppRouter.pharmacyVerification;

      case UserType.patient:
        return AppRouter.mainNav;
    }
  }

  /// Plays a quick fade-out, then navigates.
  void _beginFadeAndNavigate() {
    if (!mounted || _hasNavigated) return;

    _fadeOutController.forward().then((_) {
      _navigateToDashboard();
    });
  }

  void _navigateToDashboard() {
    if (!mounted || _hasNavigated) return;
    _hasNavigated = true;

    // Pop everything until we reach the root (AuthGate), which will 
    // automatically render the correct dashboard based on the updated auth state.
    Navigator.of(context).popUntil((route) => route.isFirst);
  }

  @override
  void dispose() {
    _redirectTimer?.cancel();
    _progressController.dispose();
    _checkController.dispose();
    _fadeOutController.dispose();
    super.dispose();
  }

  // ─── Headline / Subtext Helpers ────────────────────────────────────

  String get _headline {
    final isReturning = widget.isReturningUser;

    switch (widget.userType) {
      case UserType.admin:
      case UserType.super_admin:
        return isReturning ? 'Welcome Back, Admin!' : 'Admin Access Granted!';

      case UserType.pharmacy:
        return isReturning ? 'Welcome Back!' : 'Application Received!';

      case UserType.patient:
        return isReturning ? 'Welcome Back!' : 'Account Created!';
    }
  }

  String get _subtext {
    final isReturning = widget.isReturningUser;

    switch (widget.userType) {
      case UserType.admin:
      case UserType.super_admin:
        return 'Loading the command center…';

      case UserType.pharmacy:
        return isReturning
            ? 'Syncing your pharmacy data and loading your command center…'
            : 'Redirecting to the verification portal. Our team will review your credentials shortly.';

      case UserType.patient:
        return isReturning
            ? 'Great to see you again! Loading your health dashboard…'
            : 'Your secure health portal is ready. Preparing your dashboard…';
    }
  }

  String get _progressLabel {
    switch (widget.userType) {
      case UserType.admin:
      case UserType.super_admin:
        return 'Loading Admin Console…';
      case UserType.pharmacy:
        return widget.isReturningUser ? 'Syncing Live Orders…' : 'Submitting Application…';
      case UserType.patient:
        return 'Preparing Dashboard…';
    }
  }

  String get _heroAssetPath {
    switch (widget.userType) {
      case UserType.admin:
      case UserType.super_admin:
        return 'assets/images/patient_success.jpg'; // Reuse for admin
      case UserType.pharmacy:
        return 'assets/images/pharmacy_success.jpg';
      case UserType.patient:
        return 'assets/images/patient_success.jpg';
    }
  }

  // ─── BUILD ─────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: FadeTransition(
        opacity: _fadeOutAnimation.value == 1.0
            ? const AlwaysStoppedAnimation(1.0)
            : _fadeOutAnimation,
        child: Stack(
          children: [
            Positioned(top: -60, right: -60, child: _buildRadialGlow()),
            Positioned(bottom: -60, left: -60, child: _buildRadialGlow()),
            SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(minHeight: constraints.maxHeight),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppTheme.pagePadding,
                          vertical: AppTheme.pagePadding,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const SizedBox(height: 48),

                            // ── Animated Checkmark ──
                            Container(
                              width: 120,
                              height: 120,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: AppTheme.primaryColor.withValues(alpha: 0.1),
                                boxShadow: [
                                  BoxShadow(
                                    color: AppTheme.primaryColor.withValues(alpha: 0.15),
                                    blurRadius: 40,
                                    spreadRadius: 10,
                                  ),
                                ],
                              ),
                              child: AnimatedBuilder(
                                animation: _checkAnimation,
                                builder: (context, child) {
                                  return CustomPaint(
                                    painter: _CheckmarkPainter(
                                      progress: _checkAnimation.value,
                                      color: AppTheme.primaryColor,
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 40),

                            // ── Headline ──
                            Text(
                              _headline,
                              style: GoogleFonts.inter(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: AppTheme.textPrimaryColor,
                                letterSpacing: -0.5,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 16),

                            // ── Subtext ──
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              child: Text(
                                _subtext,
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  color: AppTheme.textSecondaryColor,
                                  height: 1.5,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                            const SizedBox(height: 48),

                            // ── Hero Image ──
                            Container(
                              height: 220,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(24),
                                color: Colors.white,
                                boxShadow: const [
                                  BoxShadow(
                                    color: Colors.black12,
                                    blurRadius: 20,
                                    offset: Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(24),
                                child: Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    Image.asset(
                                      _heroAssetPath,
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) => Container(
                                        color: AppTheme.primaryColor.withValues(alpha: 0.08),
                                        child: const Center(
                                          child: Icon(
                                            Icons.check_circle_outline_rounded,
                                            size: 64,
                                            color: AppTheme.primaryColor,
                                          ),
                                        ),
                                      ),
                                    ),
                                    Container(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                          colors: [
                                            Colors.white.withValues(alpha: 0.1),
                                            AppTheme.primaryColor.withValues(alpha: 0.2),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(height: 60),

                            // ── Progress Indicator ──
                            AnimatedBuilder(
                              animation: _progressAnimation,
                              builder: (context, child) {
                                return Column(
                                  children: [
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(4),
                                      child: LinearProgressIndicator(
                                        value: _progressAnimation.value,
                                        minHeight: 6,
                                        backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                                        valueColor: const AlwaysStoppedAnimation<Color>(
                                          AppTheme.primaryColor,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 16),
                                    Text(
                                      '$_progressLabel ${(_progressAnimation.value * 100).toInt()}%',
                                      style: GoogleFonts.inter(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        color: AppTheme.primaryColor,
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                            const SizedBox(height: 32),

                            // ── Fallback Manual Continue ──
                            // Safety net: if auto-redirect fails or user wants to skip.
                            TextButton(
                              onPressed: _hasNavigated ? null : _navigateToDashboard,
                              child: Text(
                                'Continue to Dashboard →',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  color: AppTheme.primaryColor.withValues(alpha: 0.6),
                                ),
                              ),
                            ),
                            const SizedBox(height: 24),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRadialGlow() {
    return Container(
      width: 200,
      height: 200,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppTheme.primaryColor.withValues(alpha: 0.08),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 80, sigmaY: 80),
        child: Container(color: Colors.transparent),
      ),
    );
  }
}

// ─── Custom Checkmark Painter ────────────────────────────────────────

class _CheckmarkPainter extends CustomPainter {
  final double progress;
  final Color color;

  _CheckmarkPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (progress == 0) return;

    final Paint paint = Paint()
      ..color = color
      ..strokeWidth = 8.0
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final Path path = Path();

    // Starting point
    final p1 = Offset(size.width * 0.25, size.height * 0.55);
    // Bottom point
    final p2 = Offset(size.width * 0.45, size.height * 0.75);
    // Top right point
    final p3 = Offset(size.width * 0.75, size.height * 0.35);

    path.moveTo(p1.dx, p1.dy);

    final double firstSegmentLength = (p2 - p1).distance;
    final double secondSegmentLength = (p3 - p2).distance;
    final double totalLength = firstSegmentLength + secondSegmentLength;

    final double currentLength = totalLength * progress;

    if (currentLength <= firstSegmentLength) {
      final double ratio = currentLength / firstSegmentLength;
      final Offset endPoint = Offset(
        p1.dx + (p2.dx - p1.dx) * ratio,
        p1.dy + (p2.dy - p1.dy) * ratio,
      );
      path.lineTo(endPoint.dx, endPoint.dy);
    } else {
      path.lineTo(p2.dx, p2.dy);
      final double remainingLength = currentLength - firstSegmentLength;
      final double ratio = remainingLength / secondSegmentLength;
      final Offset endPoint = Offset(
        p2.dx + (p3.dx - p2.dx) * ratio,
        p2.dy + (p3.dy - p2.dy) * ratio,
      );
      path.lineTo(endPoint.dx, endPoint.dy);
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant _CheckmarkPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.color != color;
  }
}
