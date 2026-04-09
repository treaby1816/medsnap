import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vail_meds_v2/core/providers.dart';
import 'package:vail_meds_v2/core/theme.dart';

class WelcomeScreen extends ConsumerStatefulWidget {
  const WelcomeScreen({super.key});

  @override
  ConsumerState<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends ConsumerState<WelcomeScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  Timer? _timer;
  int _tapCount = 0; 

  final List<Map<String, String>> _valueProps = [
    {
      'title': 'Meds Delivered Fast',
      'subtitle': 'Get your vital prescriptions delivered safely to your doorstep within hours.',
    },
    {
      'title': 'Nearby Doctors & Labs',
      'subtitle': 'Easily locate top-rated medical facilities and book appointments instantly.',
    },
    {
      'title': 'Secure Health Vault',
      'subtitle': 'Your medical records and prescriptions stored with enterprise-grade security.',
    },
  ];

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 4), (Timer timer) {
      if (_currentPage < _valueProps.length - 1) {
        _currentPage++;
      } else {
        _currentPage = 0;
      }
      if (_pageController.hasClients) {
        _pageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 600),
          curve: Curves.fastOutSlowIn,
        );
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  // --- ADMIN SHORTCUT LOGIC ---

  void _handleSecretTap() {
    setState(() {
      _tapCount++;
    });
    if (_tapCount >= 5) {
      _tapCount = 0;
      HapticFeedback.vibrate();
      _showAccessCodeDialog();
    }
  }

  void _showAccessCodeDialog() {
    final TextEditingController controller = TextEditingController();
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF0F172A),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Row(
          children: [
            const Icon(Icons.security_rounded, color: AppTheme.primaryColor),
            const SizedBox(width: 12),
            Text(
              'SuperAdmin Access',
              style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Please enter the master verification code to proceed to the Admin Command Center.',
              style: GoogleFonts.inter(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: controller,
              obscureText: true,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Enter Code',
                hintStyle: const TextStyle(color: Colors.white24),
                fillColor: Colors.white.withValues(alpha: 0.05),
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                prefixIcon: const Icon(Icons.key_rounded, color: Colors.white38),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: TextStyle(color: Colors.grey.shade400)),
          ),
          ElevatedButton(
            onPressed: () async {
              final enteredCode = controller.text.trim();
              if (enteredCode.isEmpty) return;

              // 1. Capture services before the async gap to satisfy the linter
              final navigator = Navigator.of(context);
              final messenger = ScaffoldMessenger.of(context);

              // 2. Fetch Dynamic Key from Firestore
              final authService = ref.read(authServiceProvider);
              final masterKey = await authService.getAdminMasterKey();

              // 3. Verify
              if (masterKey != null && enteredCode == masterKey) {
                HapticFeedback.mediumImpact();
                if (!mounted) return;
                navigator.pop(); // Close dialog
                
                // Elevate Session Role
                ref.read(userRoleProvider.notifier).setRole('admin');
                
                // Direct Route to Dashboard
                navigator.pushNamedAndRemoveUntil('/admin-dashboard', (route) => false);
                
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text('Admin Access Granted. Welcome back.'),
                    backgroundColor: AppTheme.primaryColor,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              } else {
                HapticFeedback.heavyImpact();
                if (!mounted) return;
                messenger.showSnackBar(
                  const SnackBar(
                    content: Text('Invalid Access Code or Connection Error'),
                    backgroundColor: Colors.redAccent,
                    behavior: SnackBarBehavior.floating,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryColor,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Verify & Enter', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/pharmacist_patient2.jpg',
              fit: BoxFit.cover,
              color: Colors.black.withValues(alpha: 0.6),
              colorBlendMode: BlendMode.darken,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  color: const Color(0xFF1E293B),
                  child: const Center(
                    child: Icon(Icons.image_not_supported, color: Colors.white24, size: 50),
                  ),
                );
              },
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.2),
                    Colors.black.withValues(alpha: 0.7),
                    Colors.black.withValues(alpha: 0.95),
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
              ),
            ),
          ),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Top: Logo
                        Padding(
                          padding: const EdgeInsets.only(top: 24),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Image.asset(
                                'assets/images/logo2.png',
                                height: 32,
                                width: 32,
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) => const Icon(
                                  Icons.local_hospital_rounded,
                                  color: AppTheme.primaryColor,
                                  size: 32,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'VailMeds',
                                style: GoogleFonts.inter(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  letterSpacing: -0.8,
                                ),
                              ),
                            ],
                          ),
                        ),

                        // Middle: Value Props + Dots
                        Column(
                          children: [
                            SizedBox(
                              height: 160,
                              child: PageView.builder(
                                controller: _pageController,
                                onPageChanged: (int page) {
                                  setState(() {
                                    _currentPage = page;
                                  });
                                },
                                itemCount: _valueProps.length,
                                itemBuilder: (context, index) {
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(horizontal: 32.0),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        Text(
                                          _valueProps[index]['title']!,
                                          textAlign: TextAlign.center,
                                          style: GoogleFonts.inter(
                                            fontSize: 32,
                                            fontWeight: FontWeight.w800,
                                            color: Colors.white,
                                            height: 1.2,
                                            letterSpacing: -0.5,
                                          ),
                                        ),
                                        const SizedBox(height: 12),
                                        Text(
                                          _valueProps[index]['subtitle']!,
                                          textAlign: TextAlign.center,
                                          style: GoogleFonts.inter(
                                            fontSize: 16,
                                            color: Colors.white70,
                                            height: 1.5,
                                          ),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 24),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: List.generate(
                                _valueProps.length,
                                (index) => AnimatedContainer(
                                  duration: const Duration(milliseconds: 300),
                                  margin: const EdgeInsets.symmetric(horizontal: 4),
                                  height: 6,
                                  width: _currentPage == index ? 24 : 6,
                                  decoration: BoxDecoration(
                                    color: _currentPage == index ? AppTheme.primaryColor : Colors.white38,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),

                        // Bottom: Buttons + Version
                        Padding(
                          padding: const EdgeInsets.fromLTRB(24, 32, 24, 16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              ElevatedButton(
                                onPressed: () {
                                  HapticFeedback.lightImpact();
                                  ref.read(onboardingStageProvider.notifier).state = 'auth';
                                },
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppTheme.primaryColor,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(vertical: 18),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  elevation: 0,
                                ),
                                child: Text(
                                  'Get Started',
                                  style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w800),
                                ),
                              ),
                              const SizedBox(height: 12),
                              TextButton(
                                onPressed: () {
                                  HapticFeedback.lightImpact();
                                  ref.read(onboardingStageProvider.notifier).state = 'auth';
                                  Navigator.of(context).pushNamed('/login');
                                },
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(vertical: 16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16),
                                    side: const BorderSide(color: Colors.white24, width: 1.5),
                                  ),
                                ),
                                child: Text(
                                  'Sign In',
                                  style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white),
                                ),
                              ),
                              const SizedBox(height: 16),
                              Center(
                                child: GestureDetector(
                                  onTap: _handleSecretTap,
                                  child: Text(
                                    'v2.0.1+8',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      color: Colors.white38,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 8),
                            ],
                          ),
                        ),
                      ],
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
}
