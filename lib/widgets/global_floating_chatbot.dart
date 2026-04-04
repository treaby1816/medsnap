import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

// We track the current route here. 
final currentRouteProvider = StateProvider<String>((ref) => '/');

class AppRouteObserver extends NavigatorObserver {
  final WidgetRef ref;
  AppRouteObserver(this.ref);

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (route.settings.name != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(currentRouteProvider.notifier).state = route.settings.name!;
      });
    }
  }
  @override
  void didPop(Route<dynamic> route, Route<dynamic>? previousRoute) {
    if (previousRoute?.settings.name != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(currentRouteProvider.notifier).state = previousRoute!.settings.name!;
      });
    }
  }
  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    if (newRoute?.settings.name != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(currentRouteProvider.notifier).state = newRoute!.settings.name!;
      });
    }
  }
}

class GlobalFloatingChatbot extends ConsumerStatefulWidget {
  final Widget child;

  const GlobalFloatingChatbot({super.key, required this.child});

  @override
  ConsumerState<GlobalFloatingChatbot> createState() => _GlobalFloatingChatbotState();
}

class _GlobalFloatingChatbotState extends ConsumerState<GlobalFloatingChatbot> with TickerProviderStateMixin {
  Offset _position = const Offset(0, 0); // Need to initialize in didChangeDependencies
  bool _isInit = false;
  late final AnimationController _hoverController;
  late final AnimationController _blinkController;
  late final Animation<double> _hoverAnimation;

  @override
  void initState() {
    super.initState();
    _hoverController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    
    _hoverAnimation = Tween<double>(begin: -5, end: 5).animate(
      CurvedAnimation(parent: _hoverController, curve: Curves.easeInOut),
    );

    _blinkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    // Blinking trigger timer
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
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInit) {
      // Improved default position: further inward so it's fully visible without zooming
      final size = MediaQuery.of(context).size;
      _position = Offset(size.width - 120, size.height - 150);
      _isInit = true;
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

    // Routes where the chatbot should be visible (Unified Registration & Registration Form)
    final visibleRoutes = [
      '/gateway',        // Unified Registration selection
      '/registration',   // Patient & Pharmacy Registration form
    ];

    final bool shouldShow = visibleRoutes.contains(currentRoute);

    return Stack(
      children: [
        widget.child,

        if (shouldShow)
          Positioned(
            left: _position.dx,
            top: _position.dy,
            child: Draggable(
              feedback: _buildChatbotWidget(isDragging: true),
              childWhenDragging: const SizedBox.shrink(),
              onDragEnd: (details) {
                final size = MediaQuery.of(context).size;
                setState(() {
                  // Clamp bounds with comfortable margins
                  double dx = details.offset.dx.clamp(0, size.width - 110);
                  double dy = details.offset.dy.clamp(0, size.height - 130);
                  _position = Offset(dx, dy);
                });
              },
              child: AnimatedBuilder(
                animation: _hoverAnimation,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0, _hoverAnimation.value),
                    child: _buildChatbotWidget(isDragging: false),
                  );
                },
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildChatbotWidget({required bool isDragging}) {
    return Material(
      color: Colors.transparent,
      child: GestureDetector(
        onTap: () {
          // Route to contact support
          Navigator.of(context).pushNamed('/support');
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            // The Tooltip Bubble (Glassmorphic)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.95),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(20),
                  topRight: Radius.circular(20),
                  bottomLeft: Radius.circular(20),
                  bottomRight: Radius.circular(4),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 20,
                    spreadRadius: 2,
                    offset: const Offset(0, 8),
                  ),
                ],
                border: Border.all(color: Colors.white, width: 1),
              ),
              child: Text(
                'How can I help you?',
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF0F172A),
                ),
              ),
            ),
            // The Dynamic 3D Avatar
            AnimatedBuilder(
              animation: _hoverAnimation,
              builder: (context, child) {
                // Creates a value between 0.0 and 1.0 from the hover tween (-5 to 5)
                final hoverNormalized = (_hoverAnimation.value + 5) / 10;
                final scaleValue = 1.0 + (0.05 * hoverNormalized); // Gentle breathing scale
                
                return Transform.scale(
                  scale: scaleValue,
                  child: Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      image: const DecorationImage(
                        image: AssetImage('assets/images/chatbot_avatar.png'),
                        fit: BoxFit.cover,
                      ),
                      boxShadow: [
                        BoxShadow(
                          // Dynamic glowing aura
                          color: const Color(0xFFFACC15).withValues(alpha: 0.2 + (0.4 * hoverNormalized)),
                          blurRadius: 15 + (10 * hoverNormalized),
                          spreadRadius: 2 + (4 * hoverNormalized),
                          offset: const Offset(0, 8),
                        ),
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.3),
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
                          child: const Icon(Icons.pan_tool_alt_rounded, color: Colors.white, size: 36),
                        )
                      : null,
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
