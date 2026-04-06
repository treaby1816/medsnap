import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/support_ticket.dart';

class SupportService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Stream of all tickets, optionally filtered by userType (PATIENT/PHARMACY).
  Stream<List<SupportTicket>> getTicketsStream({String? userTypeFilter}) {
    Query query = _firestore.collection('tickets').orderBy('updatedAt', descending: true);
    
    if (userTypeFilter != null && userTypeFilter != 'all') {
      query = query.where('userType', isEqualTo: userTypeFilter.toUpperCase());
    }

    return query.snapshots().map((snapshot) => snapshot.docs
        .map((doc) => SupportTicket.fromMap(doc.data() as Map<String, dynamic>? ?? {}, doc.id))
        .toList());
  }

  /// Stream of messages for a specific ticket.
  Stream<List<TicketMessage>> getMessagesStream(String ticketId) {
    return _firestore
        .collection('tickets')
        .doc(ticketId)
        .collection('messages')
        .orderBy('timestamp', descending: false)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => TicketMessage.fromMap(doc.data(), doc.id))
            .toList());
  }

  /// Sends a reply to a ticket and updates the ticket's lastMessage/updatedAt.
  Future<void> sendReply({
    required String ticketId,
    required String senderName,
    required String senderId,
    required String content,
    bool isInternal = false,
  }) async {
    final batch = _firestore.batch();
    final ticketRef = _firestore.collection('tickets').doc(ticketId);
    final messageRef = ticketRef.collection('messages').doc();

    final message = TicketMessage(
      id: '',
      senderName: senderName,
      senderId: senderId,
      role: UserRole.admin,
      content: content,
      timestamp: DateTime.now(),
      isInternal: isInternal,
    );

    // 1. Add Message
    batch.set(messageRef, message.toMap());

    // 2. Update Ticket Header
    batch.update(ticketRef, {
      'lastMessage': content,
      'updatedAt': FieldValue.serverTimestamp(),
      'status': 'open', // Re-open if it was closed
    });

    await batch.commit();
  }

  /// Creates a system-generated ticket (e.g. for Low Stock).
  Future<void> createSystemTicket({
    required String category,
    required String snippet,
    required String content,
  }) async {
    final ticketRef = _firestore.collection('tickets').doc();
    final messageRef = ticketRef.collection('messages').doc();

    final ticket = SupportTicket(
      id: '',
      userName: 'System Monitor',
      userId: 'system',
      userType: 'SYSTEM',
      category: category,
      snippet: snippet,
      updatedAt: DateTime.now(),
      lastMessage: content.split('\n').first,
    );

    await ticketRef.set(ticket.toMap());
    
    final message = TicketMessage(
      id: '',
      senderName: 'System Automator',
      senderId: 'system',
      role: UserRole.system,
      content: content,
      timestamp: DateTime.now(),
    );

    await messageRef.set(message.toMap());
  }
}

