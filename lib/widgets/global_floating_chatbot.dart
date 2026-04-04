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

  bool _isChatOpen = false;
  final List<Map<String, String>> _messages = [
    {'role': 'bot', 'content': 'Hello! I\'m VailBot. How can I assist you today?'}
  ];
  final TextEditingController _chatController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

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
      final size = MediaQuery.of(context).size;
      _position = Offset(size.width - 100, size.height - 130);
      _isInit = true;
    }
  }

  @override
  void dispose() {
    _hoverController.dispose();
    _blinkController.dispose();
    _chatController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _handleSendMessage() {
    final text = _chatController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add({'role': 'user', 'content': text});
      _chatController.clear();
    });

    _scrollToBottom();
    
    // Simulate AI Response
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) _addBotResponse(text);
    });
  }

  void _addBotResponse(String userMessage) {
    String response = "I'm still learning, but I can help you with orders, pharmacy verification, or technical support. Would you like to speak with a human agent?";
    
    final msg = userMessage.toLowerCase();
    if (msg.contains('order')) {
      response = "You can track your orders in the 'Orders' tab. Is there a specific order ID you're inquiring about?";
    } else if (msg.contains('pharmacy') || msg.contains('verified')) {
      response = "All our pharmacies undergo a multi-step license verification process before they can list medications.";
    } else if (msg.contains('hello') || msg.contains('hi')) {
      response = "Hi there! How can VailMeds help you today?";
    }

    setState(() {
      _messages.add({'role': 'bot', 'content': response});
    });
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentRoute = ref.watch(currentRouteProvider);

    // Routes where the chatbot should be visible
    final visibleRoutes = [
      '/',
      '/welcome',
      '/gateway',
      '/registration',
      '/login',
      '/patient-dashboard',
      '/pharmacy-dashboard',
      '/admin-dashboard',
    ];

    final bool shouldShow = visibleRoutes.contains(currentRoute);

    return Stack(
      children: [
        widget.child,

        if (shouldShow) ...[
          // The Chat Overlay Window
          if (_isChatOpen) _buildChatOverlay(),

          Positioned(
            left: _position.dx,
            top: _position.dy,
            child: Draggable(
              feedback: _buildChatbotWidget(isDragging: true),
              childWhenDragging: const SizedBox.shrink(),
              onDragEnd: (details) {
                final size = MediaQuery.of(context).size;
                setState(() {
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
      ],
    );
  }

  Widget _buildChatOverlay() {
    final size = MediaQuery.of(context).size;
    final bool isSmallScreen = size.width < 600;

    return Positioned(
      right: isSmallScreen ? 20 : (size.width - _position.dx - 40),
      bottom: size.height - _position.dy + 10,
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: isSmallScreen ? size.width - 40 : 350,
          height: 450,
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
              // Chat Header
              Container(
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
                            'VailBot AI Assistant',
                            style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          Text(
                            'Always Active',
                            style: GoogleFonts.inter(color: Colors.greenAccent, fontSize: 10, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded, color: Colors.white, size: 20),
                      onPressed: () => setState(() => _isChatOpen = false),
                    ),
                  ],
                ),
              ),
              // Message List
              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    final msg = _messages[index];
                    final isBot = msg['role'] == 'bot';
                    return Align(
                      alignment: isBot ? Alignment.centerLeft : Alignment.centerRight,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: isBot ? const Color(0xFFF1F5F9) : const Color(0xFFEC5B13),
                          borderRadius: BorderRadius.only(
                            topLeft: const Radius.circular(16),
                            topRight: const Radius.circular(16),
                            bottomLeft: Radius(isBot ? 0 : 16) as Radius,
                            bottomRight: Radius(isBot ? 16 : 0) as Radius,
                          ),
                        ),
                        constraints: BoxConstraints(maxWidth: size.width * 0.6),
                        child: Text(
                          msg['content']!,
                          style: GoogleFonts.inter(
                            color: isBot ? const Color(0xFF1E293B) : Colors.white,
                            fontSize: 13,
                            height: 1.4,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              // Support Links Shortcut
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    _buildQuickAction(Icons.phone_rounded, 'Call', () => Navigator.pushNamed(context, '/support')),
                    const SizedBox(width: 8),
                    _buildQuickAction(Icons.chat_rounded, 'WhatsApp', () => Navigator.pushNamed(context, '/support')),
                  ],
                ),
              ),
              // Chat Input
              Container(
                padding: const EdgeInsets.all(12),
                decoration: const BoxDecoration(
                  border: Border(top: BorderSide(color: Color(0xFFF1F5F9), width: 1)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _chatController,
                        style: GoogleFonts.inter(fontSize: 13),
                        decoration: InputDecoration(
                          hintText: 'Type a message...',
                          hintStyle: GoogleFonts.inter(color: Colors.grey, fontSize: 13),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12),
                        ),
                        onSubmitted: (_) => _handleSendMessage(),
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.send_rounded, color: Color(0xFFEC5B13)),
                      onPressed: _handleSendMessage,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickAction(IconData icon, String label, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFFF1F5F9)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 14, color: const Color(0xFF64748B)),
              const SizedBox(width: 4),
              Text(label, style: GoogleFonts.inter(fontSize: 11, color: const Color(0xFF64748B), fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChatbotWidget({required bool isDragging}) {
    return Material(
      color: Colors.transparent,
      child: GestureDetector(
        onTap: () {
          setState(() {
            _isChatOpen = !_isChatOpen;
          });
        },
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (!_isChatOpen)
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
      ),
    );
  }
}

