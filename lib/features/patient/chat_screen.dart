import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/theme.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final String userId = FirebaseAuth.instance.currentUser?.uid ?? "anonymous";

  void _sendMessage() {
    if (_controller.text.trim().isEmpty) return;

    FirebaseFirestore.instance.collection('chats').add({
      'text': _controller.text.trim(),
      'createdAt': FieldValue.serverTimestamp(),
      'senderId': userId,
      'pharmacyId': 'vail_main_branch',
    });

    _controller.clear();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Pharmacist Chat", style: TextStyle(color: Colors.black)),
        backgroundColor: Colors.white,
        elevation: 0.5,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('chats')
                  .orderBy('createdAt', descending: true)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                final docs = snapshot.data!.docs;

                return ListView.builder(
                  reverse: true,
                  padding: const EdgeInsets.all(20),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    bool isMe = data['senderId'] == userId;
                    return _buildMessage(data['text'] ?? "", isMe);
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

  Widget _buildMessage(String text, bool isMe) {
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 5),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isMe ? AppTheme.primaryColor : Colors.grey[200],
          borderRadius: BorderRadius.circular(15),
        ),
        child: Text(text, style: TextStyle(color: isMe ? Colors.white : Colors.black)),
      ),
    );
  }

  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(20),
      color: Colors.white,
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              decoration: InputDecoration(
                hintText: "Ask a question...",
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(30), borderSide: BorderSide.none),
              ),
            ),
          ),
          const SizedBox(width: 10),
          IconButton(
            icon: const Icon(Icons.send, color: AppTheme.primaryColor),
            onPressed: _sendMessage,
          ),
        ],
      ),
    );
  }
}
