import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme.dart';
import '../../../../core/providers.dart';
import '../../../../core/services/chat_service.dart';
import '../../../../widgets/glass_app_bar.dart';

class ChatScreen extends ConsumerStatefulWidget {
  final String receiverId;
  final String receiverName;

  const ChatScreen({super.key, required this.receiverId, required this.receiverName});

  @override
  ConsumerState<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends ConsumerState<ChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;
    final user = ref.read(authProvider);
    if (user == null) return;

    HapticFeedback.lightImpact();
    
    ref.read(chatServiceProvider).sendMessage(
      user.id,
      widget.receiverId,
      _messageController.text.trim(),
    );
    _messageController.clear();
  }
  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider);
    if (user == null) {
      return const Scaffold(body: Center(child: Text('Please log in to chat.')));
    }
    
    final currentUserId = user.id;
    final messagesStream = ref.watch(chatServiceProvider).getMessages(currentUserId, widget.receiverId);

    return Scaffold(
      backgroundColor: AppTheme.backgroundColor,
      appBar: GlassAppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppTheme.textPrimaryColor),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          children: [
            const CircleAvatar(radius: 16, backgroundColor: AppTheme.primaryColor, child: Icon(Icons.person, size: 16, color: Colors.white)),
            const SizedBox(width: 12),
            Text(
              widget.receiverName,
              style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: AppTheme.textPrimaryColor),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<ChatMessage>>(
              stream: messagesStream,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: AppTheme.primaryColor));
                }
                final messages = snapshot.data ?? [];
                
                if (messages.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.chat_bubble_outline, size: 48, color: Colors.grey.withValues(alpha: 0.3)),
                        const SizedBox(height: 16),
                        Text('No messages yet', style: TextStyle(color: Colors.grey.withValues(alpha: 0.5))),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  padding: const EdgeInsets.all(20),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    final isMe = message.senderId == currentUserId;
                    return _buildMessageBubble(message, isMe);
                  },
                );
              },
            ),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message, bool isMe) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: isMe ? AppTheme.primaryColor : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(isMe ? 20 : 0),
            bottomRight: Radius.circular(isMe ? 0 : 20),
          ),
          boxShadow: AppTheme.floatingShadow,
        ),
        child: Text(
          message.text,
          style: GoogleFonts.inter(
            color: isMe ? Colors.white : AppTheme.textPrimaryColor,
            fontSize: 14,
            height: 1.4,
          ),
        ),
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -4))],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: _messageController,
                decoration: const InputDecoration(
                  hintText: 'Type a message...',
                  border: InputBorder.none,
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: () {
              HapticFeedback.mediumImpact();
              _sendMessage();
            },
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: const BoxDecoration(color: AppTheme.primaryColor, shape: BoxShape.circle),
              child: const Icon(Icons.send, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}
