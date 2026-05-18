import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/support_ticket.dart';

class SupportService {
  final _supabase = Supabase.instance.client;

  /// Stream of all tickets, optionally filtered by userType (PATIENT/PHARMACY).
  Stream<List<SupportTicket>> getTicketsStream({String? userTypeFilter}) {
    var query = _supabase.from('tickets').stream(primaryKey: ['id']).order('updatedAt', ascending: false);
    
    if (userTypeFilter != null && userTypeFilter != 'all') {
      // Stream filtering in Supabase is slightly different, usually eq()
      query = _supabase.from('tickets').stream(primaryKey: ['id']).eq('userType', userTypeFilter.toUpperCase()).order('updatedAt', ascending: false);
    }

    return query.map((maps) => maps
        .map((doc) => SupportTicket.fromMap(doc, doc['id'].toString()))
        .toList());
  }

  /// Stream of messages for a specific ticket.
  Stream<List<TicketMessage>> getMessagesStream(String ticketId) {
    return _supabase
        .from('ticket_messages')
        .stream(primaryKey: ['id'])
        .eq('ticketId', ticketId)
        .order('timestamp', ascending: true)
        .map((maps) => maps
            .map((doc) => TicketMessage.fromMap(doc, doc['id'].toString()))
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
    // In Supabase, we can use RPC or perform concurrent inserts
    final message = TicketMessage(
      id: '',
      senderName: senderName,
      senderId: senderId,
      role: UserRole.admin,
      content: content,
      timestamp: DateTime.now(),
      isInternal: isInternal,
    );

    final msgData = message.toMap();
    msgData['ticketId'] = ticketId;

    await _supabase.from('ticket_messages').insert(msgData);

    await _supabase.from('tickets').update({
      'lastMessage': content,
      'updatedAt': DateTime.now().toIso8601String(),
      'status': 'open',
    }).eq('id', ticketId);
  }

  /// Creates a system-generated ticket (e.g. for Low Stock).
  Future<void> createSystemTicket({
    required String category,
    required String snippet,
    required String content,
  }) async {
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

    final response = await _supabase.from('tickets').insert(ticket.toMap()).select();
    if (response.isNotEmpty) {
      final ticketId = response.first['id'].toString();
      
      final message = TicketMessage(
        id: '',
        senderName: 'System Automator',
        senderId: 'system',
        role: UserRole.system,
        content: content,
        timestamp: DateTime.now(),
      );
      
      final msgData = message.toMap();
      msgData['ticketId'] = ticketId;
      await _supabase.from('ticket_messages').insert(msgData);
    }
  }
}
