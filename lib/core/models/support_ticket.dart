// Supabase returns timestamps as strings
enum TicketStatus { open, closed }
enum TicketPriority { low, normal, urgent }
enum UserRole { patient, pharmacy, admin, system }

class SupportTicket {
  final String id;
  final String userName;
  final String userId;
  final String userType; // 'PATIENT', 'PHARMACY', 'SYSTEM'
  final String category;
  final String snippet;
  final TicketStatus status;
  final TicketPriority priority;
  final DateTime updatedAt;
  final String? lastMessage;

  SupportTicket({
    required this.id,
    required this.userName,
    required this.userId,
    required this.userType,
    required this.category,
    required this.snippet,
    this.status = TicketStatus.open,
    this.priority = TicketPriority.normal,
    required this.updatedAt,
    this.lastMessage,
  });

  factory SupportTicket.fromMap(Map<String, dynamic> map, String docId) {
    return SupportTicket(
      id: docId,
      userName: map['userName'] ?? 'Anonymous',
      userId: map['userId'] ?? '',
      userType: map['userType'] ?? 'PATIENT',
      category: map['category'] ?? 'General Inquiry',
      snippet: map['snippet'] ?? '',
      status: map['status'] == 'closed' ? TicketStatus.closed : TicketStatus.open,
      priority: _parsePriority(map['priority']),
      updatedAt: map['updatedAt'] != null ? (map['updatedAt'] is String ? DateTime.parse(map['updatedAt']) : map['updatedAt'] as DateTime) : DateTime.now(),
      lastMessage: map['lastMessage'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'userName': userName,
      'userId': userId,
      'userType': userType,
      'category': category,
      'snippet': snippet,
      'status': status == TicketStatus.closed ? 'closed' : 'open',
      'priority': priority.name,
      'updatedAt': DateTime.now().toIso8601String(),
      'lastMessage': lastMessage,
    };
  }

  static TicketPriority _parsePriority(String? p) {
    if (p == 'urgent') return TicketPriority.urgent;
    if (p == 'low') return TicketPriority.low;
    return TicketPriority.normal;
  }
}

class TicketMessage {
  final String id;
  final String senderName;
  final String senderId;
  final UserRole role;
  final String content;
  final DateTime timestamp;
  final bool isInternal;

  TicketMessage({
    required this.id,
    required this.senderName,
    required this.senderId,
    required this.role,
    required this.content,
    required this.timestamp,
    this.isInternal = false,
  });

  factory TicketMessage.fromMap(Map<String, dynamic> map, String docId) {
    return TicketMessage(
      id: docId,
      senderName: map['senderName'] ?? 'System',
      senderId: map['senderId'] ?? '',
      role: _parseRole(map['role']),
      content: map['content'] ?? '',
      timestamp: map['timestamp'] != null ? (map['timestamp'] is String ? DateTime.parse(map['timestamp']) : map['timestamp'] as DateTime) : DateTime.now(),
      isInternal: map['isInternal'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'senderName': senderName,
      'senderId': senderId,
      'role': role.name,
      'content': content,
      'timestamp': DateTime.now().toIso8601String(),
      'isInternal': isInternal,
    };
  }

  static UserRole _parseRole(String? r) {
    if (r == 'admin') return UserRole.admin;
    if (r == 'pharmacy') return UserRole.pharmacy;
    if (r == 'system') return UserRole.system;
    return UserRole.patient;
  }
}
