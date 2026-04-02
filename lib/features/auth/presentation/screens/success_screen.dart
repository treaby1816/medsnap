import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme.dart';
import '../../../../core/constants/enums.dart';

class SuccessScreen extends StatefulWidget {
  final UserType userType;

  const SuccessScreen({super.key, required this.userType});

  @override
  State<SuccessScreen> createState() => _SuccessScreenState();
}

class _SuccessScreenState extends State<SuccessScreen>
    with TickerProviderStateMixin {
  late AnimationController _progressController;
  late AnimationController _checkController;
  late Animation<double> _progressAnimation;
  late Animation<double> _checkAnimation;
  Timer? _timer;

  @override
  void initState() {
    super.initState();

    _checkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _checkAnimation = CurvedAnimation(
      parent: _checkController,
      curve: Curves.easeOutCirc,
    );

    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    );
    _progressAnimation = Tween<double>(begin: 0.1, end: 1.0).animate(
      CurvedAnimation(parent: _progressController, curve: Curves.easeInOut),
    );

    _timer = Timer(const Duration(seconds: 3), _navigateToDashboard);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkController.forward();
      _progressController.forward();
    });
  }

  void _navigateToDashboard() {
    if (!mounted) return;

    if (widget.userType == UserType.patient) {
      Navigator.pushNamedAndRemoveUntil(context, '/main', (route) => false);
    } else {
      Navigator.pushNamedAndRemoveUntil(context, '/pharmacy-dashboard', (route) => false);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _progressController.dispose();
    _checkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isPatient = widget.userType == UserType.patient;
    final headline = isPatient ? 'Login Successful!' : 'Application Received!';
    final subtext = isPatient 
      ? 'Securing your health portal and preparing your dashboard...' 
      : 'Redirecting to the verification portal. Our team will review your credentials shortly.';

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      body: Stack(
        children: [
          Positioned(
            top: -60,
            right: -60,
            child: _buildRadialGlow(),
          ),
          Positioned(
            bottom: -60,
            left: -60,
            child: _buildRadialGlow(),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  child: ConstrainedBox(
                    constraints:
                        BoxConstraints(minHeight: constraints.maxHeight),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppTheme.pagePadding,
                        vertical: AppTheme.pagePadding,
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 48),

                          // Custom Animated Checkmark
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

                          Text(
                            headline,
                            style: GoogleFonts.inter(
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                              color: AppTheme.textPrimaryColor,
                              letterSpacing: -0.5,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 16),

                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16),
                            child: Text(
                              subtext,
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                color: AppTheme.textSecondaryColor,
                                height: 1.5,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                          const SizedBox(height: 48),

                          // Image
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
                                  Image.network(
                                    isPatient
                                        ? 'https://images.unsplash.com/photo-1519494026892-80bbd2d6fd0d?q=80&w=1000&auto=format&fit=crop'
                                        : 'https://images.unsplash.com/photo-1585435557343-3b092031a831?q=80&w=1000&auto=format&fit=crop',
                                    fit: BoxFit.cover,
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

                          // Progress indicator
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
                                    isPatient ? 'Preparing Dashboard... ${(_progressAnimation.value * 100).toInt()}%' : 'Syncing Live Orders...',
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
      // Draw first segment
      final double ratio = currentLength / firstSegmentLength;
      final Offset endPoint = Offset(
        p1.dx + (p2.dx - p1.dx) * ratio,
        p1.dy + (p2.dy - p1.dy) * ratio,
      );
      path.lineTo(endPoint.dx, endPoint.dy);
    } else {
      // First segment is complete
      path.lineTo(p2.dx, p2.dy);
      // Draw second segment
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
