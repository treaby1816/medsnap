import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:vail_meds_v2/core/theme.dart';
import 'package:vail_meds_v2/widgets/vail_chat_interface.dart';
import 'package:url_launcher/url_launcher.dart';
import 'dart:developer' as developer;

// We track the current route here. 
final currentRouteProvider = StateProvider<String>((ref) => '/');

class AppRouteObserver extends NavigatorObserver {
  final WidgetRef ref;
  AppRouteObserver(this.ref);

  void _updateRoute(Route<dynamic>? route) {
    if (route == null) return;
    final name = route.settings.name;
    if (name != null) {
      // Ensure we don't trigger a build during a build
      Future.microtask(() {
        try {
          ref.read(currentRouteProvider.notifier).state = name;
        } catch (e) {
          developer.log('AppRouteObserver error: $e', name: 'VailMeds');
        }
      });
    }
  }

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _updateRoute(route);
  }

  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _updateRoute(previousRoute);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    _updateRoute(newRoute);
  }
}

class GlobalFloatingChatbot extends ConsumerStatefulWidget {
  final Widget child;

  const GlobalFloatingChatbot({super.key, required this.child});

  @override
  ConsumerState<GlobalFloatingChatbot> createState() => _GlobalFloatingChatbotState();
}

class _GlobalFloatingChatbotState extends ConsumerState<GlobalFloatingChatbot> with TickerProviderStateMixin {
  Offset? _position;
  bool _isHovering = false;
  late final AnimationController _hoverController;
  late final AnimationController _blinkController;
  late final Animation<double> _hoverAnimation;
  bool _isChatOpen = false;
  Offset? _chatPosition;

  @override
  void initState() {
    super.initState();
    
    _hoverController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);

    _hoverAnimation = Tween<double>(begin: -5, end: 5).animate(
      CurvedAnimation(parent: _hoverController, curve: Curves.easeInOut),
    );

    _blinkController = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 150)
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      try {
        final size = MediaQuery.of(context).size;
        if (size.width > 0 && size.height > 0) {
          setState(() {
            _position = const Offset(24, 100);
            _chatPosition = const Offset(24, 200); // Initial chat window position
          });
        }
      } catch (e) {
        developer.log('Chatbot position init error: $e', name: 'VailMeds');
      }
    });

    _startBlinkCycle();
  }

  void _startBlinkCycle() async {
    while (mounted) {
      await Future.delayed(Duration(seconds: 2 + (DateTime.now().millisecond % 4)));
      if (mounted) {
        await _blinkController.forward();
        await _blinkController.reverse();
      }
    }
  }

  @override
  void dispose() {
    _hoverController.dispose();
    _blinkController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentRoute = ref.watch(currentRouteProvider);

    final visibleRoutes = [
      '/', '/welcome', '/gateway', '/registration', '/login', '/admin-dashboard',
    ];

    final bool shouldShow = visibleRoutes.contains(currentRoute);

    return Stack(
      children: [
        widget.child,

        if (shouldShow) ...[
          if (_isChatOpen) _buildChatOverlay(),

          Positioned(
            left: _position?.dx ?? 24,
            bottom: _position?.dy ?? 100,
            child: GestureDetector(
              onPanUpdate: (details) {
                final size = MediaQuery.of(context).size;
                setState(() {
                  const widgetSize = 88.0; 
                  double relLeft = details.globalPosition.dx - (widgetSize / 2);
                  double relBottom = size.height - details.globalPosition.dy - (widgetSize / 2);
                  relLeft = relLeft.clamp(24.0, size.width - widgetSize - 24.0);
                  relBottom = relBottom.clamp(20.0, size.height - widgetSize - 50.0);
                  _position = Offset(relLeft, relBottom);
                });
              },
              child: MouseRegion(
                onEnter: (_) => setState(() => _isHovering = true),
                onExit: (_) => setState(() => _isHovering = false),
                child: RepaintBoundary(
                  child: AnimatedBuilder(
                    animation: _hoverAnimation,
                    builder: (context, child) {
                      return Transform.translate(
                        offset: Offset(0, _hoverAnimation.value),
                        child: MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _isChatOpen = !_isChatOpen;
                                if (_isChatOpen) {
                                  // Reset chat position near the button
                                  _chatPosition = Offset(
                                    (_position?.dx ?? 24) + 10,
                                    (_position?.dy ?? 100) + 80,
                                  );
                                }
                              });
                            },
                            child: _buildChatbotWidget(isDragging: false),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildChatOverlay() {
    final size = MediaQuery.of(context).size;
    final bool isSmallScreen = size.width < 600;

    return Positioned(
      left: isSmallScreen ? 10 : (_chatPosition?.dx ?? 24),
      bottom: isSmallScreen ? null : (_chatPosition?.dy ?? 180),
      top: isSmallScreen ? 100 : null,
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: isSmallScreen ? size.width - 20 : 350,
          height: 500,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 30,
                spreadRadius: 5,
                offset: const Offset(0, 10),
              ),
            ],
            border: Border.all(color: const Color(0xFFF1F5F9), width: 1),
          ),
          child: Column(
            children: [
              GestureDetector(
                onPanUpdate: (details) {
                  final size = MediaQuery.of(context).size;
                  setState(() {
                    double relLeft = details.globalPosition.dx - 175; // Half of chat width
                    double relBottom = size.height - details.globalPosition.dy - 25; // Half of header height
                    relLeft = relLeft.clamp(10.0, size.width - 360.0);
                    relBottom = relBottom.clamp(10.0, size.height - 510.0);
                    _chatPosition = Offset(relLeft, relBottom);
                  });
                },
                child: MouseRegion(
                  cursor: SystemMouseCursors.move,
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFF0F172A), Color(0xFF1E293B)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(24),
                        topRight: Radius.circular(24),
                      ),
                    ),
                    child: Row(
                      children: [
                        const CircleAvatar(
                          radius: 18,
                          backgroundColor: Colors.white24,
                          child: Icon(Icons.support_agent_rounded, size: 20, color: Colors.white),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'VailBot AI Support',
                                style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              Text(
                                'Hardware Accelerated',
                                style: GoogleFonts.inter(color: Colors.greenAccent, fontSize: 10, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                        MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: GestureDetector(
                            onTap: () => _launchHumanContact(),
                            child: const Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Icon(Icons.phone_in_talk_rounded, color: Colors.greenAccent, size: 18),
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: GestureDetector(
                            onTap: () => setState(() => _isChatOpen = false),
                            child: const Padding(
                              padding: EdgeInsets.all(8.0),
                              child: Icon(Icons.close_rounded, color: Colors.white, size: 20),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const Expanded(
                child: VailChatInterface(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _launchHumanContact() async {
    final uri = Uri.parse('tel:+2348012345678');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Widget _buildChatbotWidget({required bool isDragging}) {
    return Material(
      color: Colors.transparent,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!_isChatOpen)
            AnimatedOpacity(
              duration: const Duration(milliseconds: 300),
              opacity: _isHovering ? 1.0 : 0.0,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                margin: const EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: const BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                    bottomLeft: Radius.circular(4),
                    bottomRight: Radius.circular(20),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryColor.withValues(alpha: 0.15),
                      blurRadius: 15,
                      offset: const Offset(0, 5),
                    ),
                  ],
                  border: Border.all(color: AppTheme.primaryColor.withValues(alpha: 0.2), width: 1),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.auto_awesome, color: AppTheme.primaryColor, size: 14),
                    const SizedBox(width: 8),
                    Text(
                      'Chat with VailBot (v2.2-L)',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF0F172A),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          AnimatedBuilder(
            animation: _hoverAnimation,
            builder: (context, child) {
              final hoverNormalized = (_hoverAnimation.value + 5) / 10;
              final scaleValue = 1.0 + (0.05 * hoverNormalized);
              
              return Transform.scale(
                scale: _isChatOpen ? 0.9 : scaleValue,
                child: Container(
                  width: 68,
                  height: 68,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: _isChatOpen 
                        ? [const Color(0xFF0F172A), const Color(0xFF1E293B)]
                        : [const Color(0xFFEC5B13), const Color(0xFFFACC15)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: (_isChatOpen ? const Color(0xFF0F172A) : const Color(0xFFFACC15)).withValues(alpha: 0.2 + (0.4 * hoverNormalized)),
                        blurRadius: 15 + (10 * hoverNormalized),
                        spreadRadius: 2 + (4 * hoverNormalized),
                        offset: const Offset(0, 8),
                      ),
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.2),
                        blurRadius: 10,
                        offset: const Offset(0, 5),
                      ),
                    ],
                    border: Border.all(
                      color: Colors.white,
                      width: 3,
                    ),
                  ),
                  child: isDragging 
                    ? Container(
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.5),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.pan_tool_alt_rounded, color: Colors.white, size: 24),
                      )
                    : Stack(
                        alignment: Alignment.center,
                        children: [
                          Icon(
                            _isChatOpen ? Icons.close_rounded : Icons.support_agent_rounded,
                            size: 36,
                            color: Colors.white,
                          ),
                        ],
                      ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
