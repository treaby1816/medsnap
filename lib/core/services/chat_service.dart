import 'package:supabase_flutter/supabase_flutter.dart';
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
      timestamp: map['timestamp'] != null ? DateTime.parse(map['timestamp']) : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'receiverId': receiverId,
      'text': text,
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
      lastTimestamp: map['lastTimestamp'] != null ? DateTime.parse(map['lastTimestamp']) : DateTime.now(),
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
  final _supabase = Supabase.instance.client;

  String _getChatId(String user1, String user2) {
    var ids = [user1, user2];
    ids.sort();
    return ids.join('_');
  }

  // ── Messages ─────────────────────────────────────────────────────

  Stream<List<ChatMessage>> getMessages(String senderId, String receiverId) {
    final chatId = _getChatId(senderId, receiverId);
    return _supabase
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('chat_id', chatId)
        .order('timestamp', ascending: false)
        .map((maps) => maps
            .map((map) => ChatMessage.fromMap(map, map['id'].toString()))
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
      // Create message
      await _supabase.from('messages').insert({
        'chat_id': chatId,
        'senderId': senderId,
        'receiverId': receiverId,
        'text': text,
      });

      // Assuming a trigger updates the `chats` summary or we manually update it here.
      // Supabase implementation usually handles this differently from Firestore.
    } catch (e) {
      debugPrint('Error sending message: $e');
    }
  }

  // ── Conversations ────────────────────────────────────────────────

  Stream<List<ChatConversation>> getConversations(String userId) {
    return _supabase
        .from('chats')
        .stream(primaryKey: ['id'])
        .map((maps) {
      final filtered = maps.where((m) => (m['participants'] as List<dynamic>? ?? []).contains(userId)).toList();
      final conversations = filtered
          .map((map) => ChatConversation.fromMap(map, map['id'].toString(), userId))
          .toList();
      conversations.sort((a, b) => b.lastTimestamp.compareTo(a.lastTimestamp));
      return conversations;
    }).handleError((error) {
      debugPrint('Error fetching conversations: $error');
      return <ChatConversation>[];
    });
  }

  // ── Unread Count ─────────────────────────────────────────────────

  Stream<int> getTotalUnreadCount(String userId) {
    return _supabase
        .from('chats')
        .stream(primaryKey: ['id'])
        .map((maps) {
      final filtered = maps.where((m) => (m['participants'] as List<dynamic>? ?? []).contains(userId)).toList();
      int total = 0;
      for (final doc in filtered) {
        final unreadMap = Map<String, dynamic>.from(doc['unreadCount'] ?? {});
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
      // In Supabase, if unreadCount is JSONB, we can update it this way, 
      // or set it to 0 specifically for the user. We assume a simple RPC or direct update.
      // E.g., setting the specific key in the jsonb object to 0
      await _supabase.rpc('reset_unread_count', params: {
        'p_chat_id': chatId,
        'p_user_id': userId,
      });
    } catch (e) {
      debugPrint('Error marking as read: $e');
    }
  }

  // ── Online Status ────────────────────────────────────────────────

  Future<void> updateOnlineStatus(String userId, bool isOnline) async {
    try {
      await _supabase.from('users').update({
        'isOnline': isOnline,
        // Supabase auto-updates updated_at usually
      }).eq('id', userId);
    } catch (e) {
      debugPrint('Error updating online status: $e');
    }
  }

  Stream<bool> getOnlineStatus(String userId) {
    return _supabase
        .from('users')
        .stream(primaryKey: ['id'])
        .eq('id', userId)
        .map((maps) => maps.isNotEmpty ? (maps.first['isOnline'] ?? false) : false);
  }
}
