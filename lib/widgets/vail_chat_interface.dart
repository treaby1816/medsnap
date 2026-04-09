import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import '../core/theme.dart';
import '../core/services/chatbot_service.dart';

class VailChatInterface extends ConsumerStatefulWidget {
  const VailChatInterface({super.key});

  @override
  ConsumerState<VailChatInterface> createState() => _VailChatInterfaceState();
}

class _VailChatInterfaceState extends ConsumerState<VailChatInterface> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  void _handleSendMessage() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    
    ref.read(chatbotProvider.notifier).sendMessage(text);
    _controller.clear();
    
    // Auto scroll to bottom
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0, // Because it's a reversed list 
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final messages = ref.watch(chatbotProvider);
    final reversedMessages = messages.reversed.toList();

    return Column(
      children: [
        // AI Header / Bridge to Human Support
        _buildSupportBridge(),
        
        // Chat History
        Expanded(
          child: Container(
            color: const Color(0xFFF8FAFC),
            child: ListView.builder(
              controller: _scrollController,
              reverse: true,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              itemCount: reversedMessages.length,
              itemBuilder: (context, index) {
                final msg = reversedMessages[index];
                return _buildMessageBubble(msg);
              },
            ),
          ),
        ),
        
        // Input Area
        _buildInputArea(),
      ],
    );
  }

  Widget _buildSupportBridge() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.live_help_outlined, size: 14, color: AppTheme.primaryColor.withValues(alpha: 0.6)),
          const SizedBox(width: 8),
          Text(
            "AI not helping?",
            style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textSecondaryColor),
          ),
          TextButton(
            onPressed: () => _launchHumanContact(),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: Text(
              "Talk to a Human",
              style: GoogleFonts.inter(
                fontSize: 11, 
                fontWeight: FontWeight.bold, 
                color: AppTheme.primaryColor,
                decoration: TextDecoration.underline,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatbotMessage msg) {
    return Align(
      alignment: msg.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: msg.isUser ? AppTheme.primaryColor : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(msg.isUser ? 20 : 4),
            bottomRight: Radius.circular(msg.isUser ? 4 : 20),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Text(
          msg.text,
          style: GoogleFonts.inter(
            color: msg.isUser ? Colors.white : AppTheme.textPrimaryColor,
            fontSize: 14,
            height: 1.4,
          ),
        ),
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: _controller,
                style: GoogleFonts.inter(fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Ask VailBot...',
                  hintStyle: GoogleFonts.inter(color: AppTheme.textTertiaryColor, fontSize: 13),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                ),
                onSubmitted: (_) => _handleSendMessage(),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _handleSendMessage,
            child: Container(
              width: 48,
              height: 48,
              decoration: const BoxDecoration(
                color: AppTheme.primaryColor,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _launchHumanContact() async {
    final uri = Uri.parse('tel:+2348012345678');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }
}
