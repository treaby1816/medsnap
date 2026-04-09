import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

// ─────────────────────────────────────────────────────────────────────
// Models
// ─────────────────────────────────────────────────────────────────────

class ChatMessage {
  final String id;
  final String senderId;
  final String receiverId;
  final String text;
  final DateTime timestamp;

  ChatMessage({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.text,
    required this.timestamp,
  });

  factory ChatMessage.fromMap(Map<String, dynamic> map, String docId) {
    return ChatMessage(
      id: docId,
      senderId: map['senderId'] ?? '',
      receiverId: map['receiverId'] ?? '',
      text: map['text'] ?? '',
      timestamp: (map['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'receiverId': receiverId,
      'text': text,
      'timestamp': FieldValue.serverTimestamp(),
    };
  }
}

class ChatConversation {
  final String chatId;
  final List<String> participants;
  final String lastMessage;
  final DateTime lastTimestamp;
  final int unreadCount;
  final String otherUserId;
  final String otherUserName;
  final String? otherUserPhoto;
  final bool isOtherUserOnline;

  ChatConversation({
    required this.chatId,
    required this.participants,
    required this.lastMessage,
    required this.lastTimestamp,
    this.unreadCount = 0,
    required this.otherUserId,
    required this.otherUserName,
    this.otherUserPhoto,
    this.isOtherUserOnline = false,
  });

  factory ChatConversation.fromMap(
    Map<String, dynamic> map,
    String docId,
    String currentUserId,
  ) {
    final participants = List<String>.from(map['participants'] ?? []);
    final otherUserId = participants.firstWhere(
      (id) => id != currentUserId,
      orElse: () => '',
    );
    
    // Unread count for current user
    final unreadMap = Map<String, dynamic>.from(map['unreadCount'] ?? {});
    final unread = (unreadMap[currentUserId] as int?) ?? 0;

    return ChatConversation(
      chatId: docId,
      participants: participants,
      lastMessage: map['lastMessage'] ?? '',
      lastTimestamp: (map['lastTimestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      unreadCount: unread,
      otherUserId: otherUserId,
      otherUserName: map['participantNames']?[otherUserId] ?? 'User',
      otherUserPhoto: map['participantPhotos']?[otherUserId],
      isOtherUserOnline: false, // Populated later from user doc
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// Service
// ─────────────────────────────────────────────────────────────────────

class ChatService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  String _getChatId(String user1, String user2) {
    var ids = [user1, user2];
    ids.sort();
    return ids.join('_');
  }

  // ── Messages ─────────────────────────────────────────────────────

  Stream<List<ChatMessage>> getMessages(String senderId, String receiverId) {
    final chatId = _getChatId(senderId, receiverId);
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .orderBy('timestamp', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ChatMessage.fromMap(doc.data(), doc.id))
            .toList());
  }

  Future<void> sendMessage(
    String senderId,
    String receiverId,
    String text, {
    String? senderName,
    String? senderPhoto,
    String? receiverName,
    String? receiverPhoto,
  }) async {
    final chatId = _getChatId(senderId, receiverId);
    try {
      // 1. Ensure the parent chat document exists first (crucial for security rules)
      await _firestore.collection('chats').doc(chatId).set({
        'lastMessage': text,
        'lastTimestamp': FieldValue.serverTimestamp(),
        'participants': [senderId, receiverId],
        'participantNames': {
          if (senderName != null) senderId: senderName,
          if (receiverName != null) receiverId: receiverName,
        },
        'participantPhotos': {
          if (senderPhoto != null) senderId: senderPhoto,
          if (receiverPhoto != null) receiverId: receiverPhoto,
        },
        'unreadCount': {
          receiverId: FieldValue.increment(1),
        },
      }, SetOptions(merge: true));

      // 2. Add the actual message to the subcollection
      final message = ChatMessage(
        id: '',
        senderId: senderId,
        receiverId: receiverId,
        text: text,
        timestamp: DateTime.now(),
      );
      await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .add(message.toMap());
      
    } catch (e) {
      debugPrint('Error sending message: $e');
    }
  }

  // ── Conversations ────────────────────────────────────────────────

  Stream<List<ChatConversation>> getConversations(String userId) {
    return _firestore
        .collection('chats')
        .where('participants', arrayContains: userId)
        .snapshots()
        .map((snapshot) {
      final conversations = snapshot.docs
          .map((doc) => ChatConversation.fromMap(doc.data(), doc.id, userId))
          .toList();
      // Sort by most recent message
      conversations.sort((a, b) => b.lastTimestamp.compareTo(a.lastTimestamp));
      return conversations;
    }).handleError((error) {
      debugPrint('Error fetching conversations: $error');
      return <ChatConversation>[];
    });
  }

  // ── Unread Count ─────────────────────────────────────────────────

  Stream<int> getTotalUnreadCount(String userId) {
    return _firestore
        .collection('chats')
        .where('participants', arrayContains: userId)
        .snapshots()
        .map((snapshot) {
      int total = 0;
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final unreadMap = Map<String, dynamic>.from(data['unreadCount'] ?? {});
        total += (unreadMap[userId] as int?) ?? 0;
      }
      return total;
    }).handleError((error) {
      debugPrint('Error fetching unread count: $error');
      return 0;
    });
  }

  // ── Mark As Read ─────────────────────────────────────────────────

  Future<void> markAsRead(String chatId, String userId) async {
    try {
      await _firestore.collection('chats').doc(chatId).update({
        'unreadCount.$userId': 0,
      });
    } catch (e) {
      debugPrint('Error marking as read: $e');
    }
  }

  // ── Online Status ────────────────────────────────────────────────

  Future<void> updateOnlineStatus(String userId, bool isOnline) async {
    try {
      await _firestore.collection('users').doc(userId).update({
        'isOnline': isOnline,
        'lastSeen': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error updating online status: $e');
    }
  }

  Stream<bool> getOnlineStatus(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .snapshots()
        .map((doc) => doc.data()?['isOnline'] ?? false);
  }
}
