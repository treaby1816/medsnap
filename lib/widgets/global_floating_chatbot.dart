import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:vail_meds_v2/core/theme.dart';

// We track the current route here. 
final currentRouteProvider = StateProvider<String>((ref) => '/');

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
  
  late final WebViewController _webController;

  @override
  void initState() {
    super.initState();
    _hoverController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _blinkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    );

    _hoverAnimation = Tween<double>(begin: 0, end: 15).animate(
      CurvedAnimation(parent: _hoverController, curve: Curves.easeInOut),
    );

    _webController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..loadRequest(Uri.parse('https://vail-meds-v2-support.web.app')); // Point to your support bot url
  }

  @override
  void dispose() {
    _hoverController.dispose();
    _blinkController.dispose();
    super.dispose();
  }

  void _toggleChat() {
    setState(() {
      _isChatOpen = !_isChatOpen;
    });
  }

  @override
  Widget build(BuildContext context) {
    // Hidden on Login, Splash, etc if you prefer, or global.
    // For now, let's keep it global but positioned safely.
    
    final size = MediaQuery.of(context).size;
    
    // Initialize position only when size is available (to avoid 0,0 offscreen)
    if (_position == null && size.width > 0) {
      _position = Offset(size.width - 90, size.height - 180);
    }
    
    final currentPos = _position ?? const Offset(20, 20);

    return Stack(
      children: [
        widget.child,
        if (_isChatOpen)
          Positioned(
            right: 20,
            bottom: 100,
            child: Material(
              elevation: 20,
              borderRadius: BorderRadius.circular(24),
              clipBehavior: Clip.antiAlias,
              child: Container(
                width: 380,
                height: 600,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 30,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _buildChatHeader(),
                    Expanded(
                      child: WebViewWidget(controller: _webController),
                    ),
                  ],
                ),
              ),
            ),
          ),
        
        Positioned(
          left: currentPos.dx,
          top: currentPos.dy,
          child: GestureDetector(
            onPanUpdate: (details) {
              setState(() {
                _position = Offset(
                  (currentPos.dx + details.delta.dx).clamp(0.0, size.width - 70),
                  (currentPos.dy + details.delta.dy).clamp(0.0, size.height - 70),
                );
              });
            },
            onTap: _toggleChat,
            child: MouseRegion(
              onEnter: (_) => setState(() => _isHovering = true),
              onExit: (_) => setState(() => _isHovering = false),
              child: AnimatedBuilder(
                animation: _hoverAnimation,
                builder: (context, child) {
                  return Transform.translate(
                    offset: Offset(0, -_hoverAnimation.value),
                    child: _buildVailBotMascot(),
                  );
                },
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildChatHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.primaryColor, AppTheme.primaryColor.withOpacity(0.8)],
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: Colors.white24,
              shape: Box_Circle,
            ),
            child: const Icon(Icons.support_agent_rounded, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'VailBot Support',
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              Text(
                'Always online',
                style: GoogleFonts.outfit(
                  color: Colors.white70,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.close_rounded, color: Colors.white),
            onPressed: () => setState(() => _isChatOpen = false),
          ),
        ],
      ),
    );
  }

  Widget _buildVailBotMascot() {
    return Container(
      width: 70,
      height: 70,
      decoration: BoxDecoration(
        color: AppTheme.primaryColor,
        shape: Box_Circle,
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.4),
            blurRadius: 20,
            spreadRadius: 2,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Inner glow
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: Box_Circle,
              gradient: RadialGradient(
                colors: [
                  Colors.white.withOpacity(0.2),
                  Colors.transparent,
                ],
              ),
            ),
          ),
          // Eyes
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildEye(),
              const SizedBox(width: 8),
              _buildEye(),
            ],
          ),
          // Interactive Ring
          if (_isHovering)
            _buildAnimatedRing(),
        ],
      ),
    );
  }

  Widget _buildEye() {
    return Container(
      width: 10,
      height: 10,
      decoration: const BoxDecoration(
        color: Colors.white,
        shape: Box_Circle,
      ),
    );
  }

  Widget _buildAnimatedRing() {
    return Container(
      width: 68,
      height: 68,
      decoration: BoxDecoration(
        shape: Box_Circle,
        border: Border.all(color: Colors.white.withOpacity(0.5), width: 2),
      ),
    );
  }
}

// Fixed constant for circle shape to avoid common linting errors with older flutter versions
const Box_Circle = BoxShape.circle;
