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

class _GlobalFloatingChatbotState extends ConsumerState<GlobalFloatingChatbot> with SingleTickerProviderStateMixin {
  Offset _position = const Offset(0, 0); // Need to initialize in didChangeDependencies
  bool _isInit = false;
  late final AnimationController _hoverController;
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
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInit) {
      // Default position: bottom right corner
      final size = MediaQuery.of(context).size;
      _position = Offset(size.width - 80, size.height - 100);
      _isInit = true;
    }
  }

  @override
  void dispose() {
    _hoverController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentRoute = ref.watch(currentRouteProvider);

    // Routes where we hide the chatbot (auth screens, dashboards with their own chat, etc.)
    final hiddenRoutes = [
      '/',                    // Splash screen
      '/welcome',             // Welcome screen
      '/gateway',             // Gateway/portal selection
      '/login',               // Login screen
      '/registration',        // Registration screen
      '/onboarding',          // Onboarding screen
      '/success',             // Success/transition screen
      '/verification',        // Verification screen
      '/pharmacy-verification', // Pharmacy verification
      '/privacy',             // Privacy policy
      '/terms',               // Terms of service
      '/main',                // Patient dashboard (has its own FloatingChatButton)
      '/patient-dashboard',   // Patient dashboard alias
      '/pharmacy-dashboard',  // Pharmacy dashboard (has its own chat)
      '/admin-dashboard',     // Admin dashboard
      '/chat',                // Chat screen itself
    ];

    final bool shouldHide = hiddenRoutes.contains(currentRoute);

    return Stack(
      children: [
        widget.child,

        if (!shouldHide)
          Positioned(
            left: _position.dx,
            top: _position.dy,
            child: Draggable(
              feedback: _buildChatbotWidget(isDragging: true),
              childWhenDragging: const SizedBox.shrink(),
              onDragEnd: (details) {
                final size = MediaQuery.of(context).size;
                setState(() {
                  // Clamp bounds so it doesn't get dragged off-screen
                  double dx = details.offset.dx.clamp(0, size.width - 80);
                  double dy = details.offset.dy.clamp(0, size.height - 100);
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
            // The Cartoon Avatar
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFFEC5B13), Color(0xFFFF8C33)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFEC5B13).withValues(alpha: 0.3),
                    blurRadius: 15,
                    spreadRadius: 5,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: isDragging 
                ? const Icon(Icons.pan_tool_alt_rounded, color: Colors.white, size: 32)
                : const Icon(Icons.support_agent_rounded, size: 40, color: Colors.white),
            ),
          ],
        ),
      ),
    );
  }
}
