import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme.dart';

class AdminChatbotOverlay extends StatefulWidget {
  const AdminChatbotOverlay({super.key});

  @override
  State<AdminChatbotOverlay> createState() => _AdminChatbotOverlayState();
}

class _AdminChatbotOverlayState extends State<AdminChatbotOverlay> {
  bool _isExpanded = false;
  Offset _position = const Offset(20, 20); // From bottom-right
  final List<Map<String, String>> _messages = [
    {'role': 'assistant', 'text': 'Welcome to VailMeds Command Center. How can I assist with your clinical operations today?'},
  ];
  final TextEditingController _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: _position.dy,
      right: _position.dx,
      child: Material(
        color: Colors.transparent,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (_isExpanded) _buildChatWindow(),
            const SizedBox(height: 12),
            _buildFab(),
          ],
        ),
      ),
    );
  }

  Widget _buildFab() {
    return Draggable(
      feedback: _buildFabIcon(isDragging: true),
      childWhenDragging: const SizedBox.shrink(),
      onDragEnd: (details) {
        setState(() {
          // Constrain position within reasonable bounds
          double newDx = MediaQuery.of(context).size.width - details.offset.dx - 60;
          double newDy = MediaQuery.of(context).size.height - details.offset.dy - 60;
          _position = Offset(
            newDx.clamp(20, MediaQuery.of(context).size.width - 80),
            newDy.clamp(20, MediaQuery.of(context).size.height - 120),
          );
        });
      },
      child: _buildFabIcon(),
    );
  }

  Widget _buildFabIcon({bool isDragging = false}) {
    return InkWell(
      onTap: isDragging ? null : () => setState(() => _isExpanded = !_isExpanded),
      borderRadius: BorderRadius.circular(30),
      child: Container(
        width: 60,
        height: 60,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [AppTheme.primaryColor, Color(0xFFFF8C42)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppTheme.primaryColor.withValues(alpha: 0.3),
              blurRadius: 15,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Icon(
          _isExpanded ? Icons.close_rounded : Icons.auto_awesome_rounded,
          color: Colors.white,
          size: 28,
        ),
      ),
    );
  }

  Widget _buildChatWindow() {
    return Container(
      width: 320,
      height: 420,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppTheme.primaryColor.withValues(alpha: 0.9),
                      const Color(0xFFFF8C42).withValues(alpha: 0.8),
                    ],
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.medication_liquid_rounded, color: Colors.white, size: 20),
                    const SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'VailMeds Assistant',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          'Clinical AI Concierge',
                          style: GoogleFonts.inter(
                            color: Colors.white.withValues(alpha: 0.8),
                            fontSize: 10,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Body
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _messages.length,
                  itemBuilder: (context, index) {
                    final msg = _messages[index];
                    final isMe = msg['role'] == 'user';
                    return Align(
                      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                      child: Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                        decoration: BoxDecoration(
                          color: isMe 
                            ? AppTheme.primaryColor 
                            : Colors.white.withValues(alpha: 0.6),
                          borderRadius: BorderRadius.circular(16).copyWith(
                            bottomRight: isMe ? const Radius.circular(4) : null,
                            bottomLeft: !isMe ? const Radius.circular(4) : null,
                          ),
                          border: isMe ? null : Border.all(color: AppTheme.borderColor),
                        ),
                        child: Text(
                          msg['text']!,
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            color: isMe ? Colors.white : AppTheme.textPrimaryColor,
                            fontWeight: isMe ? FontWeight.w600 : FontWeight.w500,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              // Input
              Padding(
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                child: Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14),
                        decoration: BoxDecoration(
                          color: AppTheme.backgroundColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppTheme.borderColor),
                        ),
                        child: TextField(
                          controller: _controller,
                          style: GoogleFonts.inter(fontSize: 13),
                          decoration: InputDecoration(
                            hintText: 'Type an insight...',
                            hintStyle: GoogleFonts.inter(fontSize: 12, color: AppTheme.textTertiaryColor),
                            border: InputBorder.none,
                          ),
                          onSubmitted: _handleSend,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.send_rounded, color: AppTheme.primaryColor),
                      onPressed: () => _handleSend(_controller.text),
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

  void _handleSend(String text) {
    if (text.isEmpty) return;
    setState(() {
      _messages.add({'role': 'user', 'text': text});
      _controller.clear();
      // Simulate AI response
      Future.delayed(const Duration(milliseconds: 600), () {
        if (mounted) {
          setState(() {
            _messages.add({
              'role': 'assistant',
              'text': 'Processing medical insight for "$text". I am currently monitoring 42 active pharmacy streams.'
            });
          });
        }
      });
    });
  }
}
