import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/theme.dart';

class ChatScreen extends StatefulWidget {
  final String receiverId;
  final String receiverName;

  const ChatScreen({
    super.key,
    required this.receiverId,
    required this.receiverName,
  });

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final String userId = FirebaseAuth.instance.currentUser?.uid ?? "anonymous";
  bool _needsIndex = false;

  String get chatId {
    List<String> ids = [userId, widget.receiverId];
    ids.sort();
    return ids.join('_');
  }

  /// The primary stream uses the composite index (chatId + createdAt).
  /// If the index doesn't exist yet, we fall back to client-side sorting.
  Stream<QuerySnapshot> get _chatStream {
    if (_needsIndex) {
      // Fallback: query by chatId only, sort on the client side
      return FirebaseFirestore.instance
          .collection('chats')
          .where('chatId', isEqualTo: chatId)
          .snapshots();
    }
    // Primary: uses Firestore composite index
    return FirebaseFirestore.instance
        .collection('chats')
        .where('chatId', isEqualTo: chatId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  void _sendMessage() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    FirebaseFirestore.instance.collection('chats').add({
      'text': text,
      'createdAt': FieldValue.serverTimestamp(),
      'senderId': userId,
      'receiverId': widget.receiverId,
      'receiverName': widget.receiverName,
      'senderName': FirebaseAuth.instance.currentUser?.displayName ?? "Patient",
      'chatId': chatId,
      'participants': [userId, widget.receiverId],
    });

    _controller.clear();
  }

  @override
  void dispose() {
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
              child: Text(
                widget.receiverName.isNotEmpty ? widget.receiverName[0].toUpperCase() : 'P',
                style: const TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.receiverName, style: const TextStyle(color: Colors.black, fontSize: 16, fontWeight: FontWeight.w600)),
                  const Text('Online', style: TextStyle(color: Colors.green, fontSize: 12)),
                ],
              ),
            ),
          ],
        ),
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _chatStream,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  final errorMsg = snapshot.error.toString();
                  // Detect the missing index error and fall back
                  if (errorMsg.contains('failed-precondition') ||
                      errorMsg.contains('requires an index') ||
                      errorMsg.contains('FAILED_PRECONDITION')) {
                    if (!_needsIndex) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (mounted) setState(() => _needsIndex = true);
                      });
                    }
                    return const Center(child: CircularProgressIndicator());
                  }
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error_outline, size: 48, color: Colors.red[300]),
                          const SizedBox(height: 16),
                          Text(
                            'Could not load messages.\n$errorMsg',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.grey[600], fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                final docs = snapshot.data?.docs ?? [];

                // If using fallback mode, sort client-side
                if (_needsIndex && docs.isNotEmpty) {
                  docs.sort((a, b) {
                    final aTime = (a.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
                    final bTime = (b.data() as Map<String, dynamic>)['createdAt'] as Timestamp?;
                    if (aTime == null && bTime == null) return 0;
                    if (aTime == null) return 1;
                    if (bTime == null) return -1;
                    return bTime.compareTo(aTime); // descending
                  });
                }

                if (docs.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(Icons.chat_bubble_outline, size: 48, color: AppTheme.primaryColor.withValues(alpha: 0.5)),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          "Start a conversation",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: Colors.grey[800]),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Say hello to ${widget.receiverName}!\nAsk about medications, services, or availability.",
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.grey[500], fontSize: 14),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  controller: _scrollController,
                  reverse: true,
                  padding: const EdgeInsets.all(20),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final isMe = data['senderId'] == userId;
                    final timestamp = data['createdAt'] as Timestamp?;
                    return _buildMessage(data['text'] ?? "", isMe, timestamp);
                  },
                );
              },
            ),
          ),
          _buildInputArea(),
        ],
      ),
    );
  }

  Widget _buildMessage(String text, bool isMe, Timestamp? timestamp) {
    String timeStr = '';
    if (timestamp != null) {
      final dt = timestamp.toDate();
      final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
      final period = dt.hour >= 12 ? 'PM' : 'AM';
      timeStr = '$hour:${dt.minute.toString().padLeft(2, '0')} $period';
    }

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isMe ? AppTheme.primaryColor : Colors.grey[100],
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 16),
          ),
        ),
        child: Column(
          crossAxisAlignment: isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(text, style: TextStyle(color: isMe ? Colors.white : Colors.black, fontSize: 15)),
            if (timeStr.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(timeStr, style: TextStyle(color: isMe ? Colors.white70 : Colors.grey[500], fontSize: 10)),
            ],
          ],
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
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 10, offset: const Offset(0, -2)),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              onSubmitted: (_) => _sendMessage(),
              textInputAction: TextInputAction.send,
              decoration: InputDecoration(
                hintText: "Type a message...",
                hintStyle: TextStyle(color: Colors.grey[400]),
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Container(
            decoration: const BoxDecoration(
              color: AppTheme.primaryColor,
              shape: BoxShape.circle,
            ),
            child: IconButton(
              icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
              onPressed: _sendMessage,
            ),
          ),
        ],
      ),
    );
  }
}
