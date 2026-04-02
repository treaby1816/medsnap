import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme.dart';
import '../../../../core/providers/admin_providers.dart';

// ─────────────────────────────────────────────────────────────────────
// ADMIN SUPPORT CENTER — Dual-pane ticket management hub
// ─────────────────────────────────────────────────────────────────────

/// Mock data models for the Support Center
class _SupportTicket {
  final String id;
  final String userName;
  final String category;
  final String snippet;
  final String timeAgo;
  final String userType; // 'PATIENT' or 'PHARMACY'
  final String priority; // 'urgent', 'normal', 'low'
  final List<_TicketMessage> messages;

  const _SupportTicket({
    required this.id,
    required this.userName,
    required this.category,
    required this.snippet,
    required this.timeAgo,
    required this.userType,
    this.priority = 'normal',
    this.messages = const [],
  });
}

class _TicketMessage {
  final String sender;
  final String role; // 'user', 'admin', 'system'
  final String content;
  final String timestamp;

  const _TicketMessage({
    required this.sender,
    required this.role,
    required this.content,
    required this.timestamp,
  });
}

// Mock data
const _mockTickets = [
  _SupportTicket(
    id: 'TK-8821',
    userName: 'Marcus Holloway',
    category: 'URGENT REFILL',
    snippet: '"My prescription hasn\'t arrived at the Aspen branch yet. I need this by tonight."',
    timeAgo: '2m ago',
    userType: 'PATIENT',
    priority: 'urgent',
    messages: [
      _TicketMessage(
        sender: 'Marcus Holloway',
        role: 'user',
        content: 'Hello, I am currently at the Aspen mountain branch and they don\'t have my prescription record for the refill I ordered yesterday. I need this medication before my flight tonight at 8 PM. Can you please check the status and coordinate with the pharmacist here?',
        timestamp: 'Oct 24, 08:10 AM',
      ),
      _TicketMessage(
        sender: 'System Automator',
        role: 'system',
        content: 'Ticket created and assigned to High Priority queue. Automated notification sent to Aspen Branch Pharmacy.',
        timestamp: 'Oct 24, 08:12 AM',
      ),
      _TicketMessage(
        sender: 'Marcus Holloway',
        role: 'user',
        content: 'I\'m standing at the counter now. Pharmacist Sarah says the system isn\'t syncing.',
        timestamp: 'Oct 24, 08:15 AM',
      ),
      _TicketMessage(
        sender: 'You (Support Specialist)',
        role: 'admin',
        content: 'Good morning Marcus. I\'m investigating the sync lag between our HQ and the Aspen branch. Please give me 5 minutes.',
        timestamp: 'Oct 24, 08:18 AM',
      ),
    ],
  ),
  _SupportTicket(
    id: 'TK-8819',
    userName: 'Elena Rodriguez',
    category: 'DOSAGE QUERY',
    snippet: '"Can I take this medication with food? The label is slightly torn."',
    timeAgo: '14m ago',
    userType: 'PATIENT',
  ),
  _SupportTicket(
    id: 'TK-8815',
    userName: 'James Chen',
    category: 'BILLING DISPUTE',
    snippet: '"I was charged twice for my last concierge delivery. Please investigate."',
    timeAgo: '1h ago',
    userType: 'PATIENT',
  ),
  _SupportTicket(
    id: 'TK-8790',
    userName: 'Central Valley Pharmacy',
    category: 'STOCK UPDATE',
    snippet: '"Lisinopril 10mg is currently backordered. Adjusting digital fulfillment."',
    timeAgo: '2h ago',
    userType: 'PHARMACY',
  ),
];

class AdminSupportCenter extends ConsumerStatefulWidget {
  const AdminSupportCenter({super.key});

  @override
  ConsumerState<AdminSupportCenter> createState() => _AdminSupportCenterState();
}

class _AdminSupportCenterState extends ConsumerState<AdminSupportCenter> {
  int _selectedTicketIndex = 0;
  String _activeFilter = 'all'; // 'all', 'patient', 'pharmacy'
  bool _isInternalNote = false;
  final _replyController = TextEditingController();

  List<_SupportTicket> get _filteredTickets {
    if (_activeFilter == 'patient') {
      return _mockTickets.where((t) => t.userType == 'PATIENT').toList();
    } else if (_activeFilter == 'pharmacy') {
      return _mockTickets.where((t) => t.userType == 'PHARMACY').toList();
    }
    return _mockTickets;
  }

  @override
  void dispose() {
    _replyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var tickets = List<_SupportTicket>.from(_filteredTickets);
    
    // Inject Automated "Critical Stock" Alert if necessary
    final urgentList = ref.watch(adminUrgentInventoryProvider).value ?? [];
    if (urgentList.isNotEmpty) {
      final names = urgentList.map((p) => p.name).join(', ');
      tickets.insert(0, _SupportTicket(
        id: 'SYS-ALERT',
        userName: 'System Monitor',
        category: 'CRITICAL STOCK',
        snippet: '"Low stock detected for: $names. Replenishment required immediately."',
        timeAgo: 'Just now',
        userType: 'SYSTEM',
        priority: 'urgent',
        messages: [
          _TicketMessage(
            sender: 'System Automator',
            role: 'system',
            content: 'CRITICAL ALERT: The following medications have dropped below the safe threshold (< 10 units):\n\n'
                     '${urgentList.map((p) => '• ${p.name} (${p.stockCount} remaining) at ${p.pharmacyName}').join('\n')}'
                     '\n\nPlease contact the respective pharmacies to pause marketplace fulfillment or restock immediately.',
            timestamp: 'Just now',
          ),
        ],
      ));
    }

    final selected = tickets.isNotEmpty && _selectedTicketIndex < tickets.length
        ? tickets[_selectedTicketIndex]
        : null;

    return Padding(
      padding: const EdgeInsets.all(28),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Left: Support Queue (flex 4) ──
          Expanded(
            flex: 4,
            child: _buildSupportQueue(tickets),
          ),
          const SizedBox(width: 20),

          // ── Right: Active Interaction (flex 6) ──
          Expanded(
            flex: 6,
            child: selected != null
                ? _buildActiveInteraction(selected)
                : _buildEmptyInteraction(),
          ),
        ],
      ),
    );
  }

  // ── Support Queue (Left Pane) ──────────────────────────────────
  Widget _buildSupportQueue(List<_SupportTicket> tickets) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Support Queue',
                  style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700, color: AppTheme.textPrimaryColor),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF22C55E).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${tickets.length} ACTIVE',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF22C55E),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Filter Tabs
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                _filterChip('Patient Issues', 'patient'),
                const SizedBox(width: 8),
                _filterChip('Pharmacy Support', 'pharmacy'),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // Ticket List
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.zero,
              itemCount: tickets.length,
              itemBuilder: (context, index) => _buildTicketCard(tickets[index], index),
            ),
          ),
        ],
      ),
    );
  }

  Widget _filterChip(String label, String filter) {
    final isActive = _activeFilter == filter;
    return InkWell(
      onTap: () => setState(() => _activeFilter = _activeFilter == filter ? 'all' : filter),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: isActive ? AppTheme.primaryColor : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isActive ? AppTheme.primaryColor : AppTheme.borderColor),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isActive ? Colors.white : AppTheme.textSecondaryColor,
          ),
        ),
      ),
    );
  }

  Widget _buildTicketCard(_SupportTicket ticket, int index) {
    final isSelected = index == _selectedTicketIndex;
    final isUrgent = ticket.priority == 'urgent';

    return Material(
      color: isSelected ? AppTheme.primaryColor.withValues(alpha: 0.04) : Colors.transparent,
      child: InkWell(
        onTap: () => setState(() => _selectedTicketIndex = index),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          decoration: BoxDecoration(
            border: Border(
              left: isSelected
                  ? const BorderSide(color: AppTheme.primaryColor, width: 3)
                  : BorderSide.none,
              bottom: BorderSide(color: AppTheme.borderColor.withValues(alpha: 0.5)),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Category + Time
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    ticket.category,
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5,
                      color: isUrgent ? Colors.red : AppTheme.primaryColor,
                    ),
                  ),
                  Text(ticket.timeAgo, style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textTertiaryColor)),
                ],
              ),
              const SizedBox(height: 4),

              // User Name
              Text(
                ticket.userName,
                style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w700, color: AppTheme.textPrimaryColor),
              ),
              const SizedBox(height: 2),

              // Snippet
              Text(
                ticket.snippet,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondaryColor, fontStyle: FontStyle.italic),
              ),
              const SizedBox(height: 6),

              // User Type Badge + Ticket ID
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: ticket.userType == 'PATIENT'
                          ? const Color(0xFF3B82F6).withValues(alpha: 0.1)
                          : AppTheme.primaryColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      ticket.userType,
                      style: GoogleFonts.inter(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: ticket.userType == 'PATIENT' ? const Color(0xFF3B82F6) : AppTheme.primaryColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '#${ticket.id}',
                    style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textTertiaryColor),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Active Interaction (Right Pane) ────────────────────────────
  Widget _buildActiveInteraction(_SupportTicket ticket) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Column(
        children: [
          // ── Profile Header ──
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              border: Border(bottom: BorderSide(color: AppTheme.borderColor)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 22,
                  backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.15),
                  child: const Icon(Icons.person, color: AppTheme.primaryColor, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            ticket.userName,
                            style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textPrimaryColor),
                          ),
                          const SizedBox(width: 6),
                          const Icon(Icons.verified, color: Color(0xFF3B82F6), size: 16),
                        ],
                      ),
                      Text(
                        'Patient ID: #VM-${ticket.id.replaceAll('TK-', '')} • Member since 2022',
                        style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondaryColor),
                      ),
                    ],
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.folder_shared_outlined, size: 16),
                  label: Text('Patient File', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppTheme.borderColor),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.phone, size: 16),
                  label: Text('Voice Call', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0F172A),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
              ],
            ),
          ),

          // ── Conversation Log ──
          Expanded(
            child: ticket.messages.isEmpty
                ? Center(
                    child: Text(
                      'No conversation history yet.',
                      style: GoogleFonts.inter(color: AppTheme.textTertiaryColor),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: ticket.messages.length + 1, // +1 for original issue
                    itemBuilder: (context, index) {
                      if (index == 0) {
                        // Original Issue header
                        return _buildOriginalIssue(ticket.messages.first);
                      }
                      return _buildMessageBubble(ticket.messages[index - 1]);
                    },
                  ),
          ),

          // ── Reply Editor ──
          _buildReplyEditor(ticket),

          // ── Response Goal Footer ──
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: const BoxDecoration(
              color: AppTheme.backgroundColor,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'LAST RESPONSE WAS 4 MINUTES AGO',
                  style: GoogleFonts.inter(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textTertiaryColor,
                    letterSpacing: 0.5,
                  ),
                ),
                Text(' • ', style: GoogleFonts.inter(color: AppTheme.textTertiaryColor)),
                Text(
                  'RESPONSE GOAL: UNDER 10 MINUTES',
                  style: GoogleFonts.inter(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.textTertiaryColor,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOriginalIssue(_TicketMessage msg) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'ORIGINAL ISSUE',
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w800,
              color: AppTheme.primaryColor,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '"${msg.content}"',
            style: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: AppTheme.textPrimaryColor,
              height: 1.6,
            ),
          ),
          const Divider(height: 32),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(_TicketMessage msg) {
    final isSystem = msg.role == 'system';
    final isAdmin = msg.role == 'admin';

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Sender Header
          Row(
            children: [
              if (isSystem)
                const Icon(Icons.schedule, size: 14, color: AppTheme.textTertiaryColor)
              else
                CircleAvatar(
                  radius: 14,
                  backgroundColor: isAdmin ? AppTheme.primaryColor : const Color(0xFF94A3B8).withValues(alpha: 0.2),
                  child: Icon(
                    isAdmin ? Icons.shield : Icons.person,
                    size: 14,
                    color: isAdmin ? Colors.white : AppTheme.textSecondaryColor,
                  ),
                ),
              const SizedBox(width: 8),
              Text(
                msg.sender,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isAdmin ? AppTheme.primaryColor : AppTheme.textPrimaryColor,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                msg.timestamp,
                style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textTertiaryColor),
              ),
            ],
          ),
          const SizedBox(height: 6),

          // Message Body
          Container(
            margin: const EdgeInsets.only(left: 36),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: isAdmin
                  ? const Color(0xFF0F172A)
                  : isSystem
                      ? AppTheme.backgroundColor
                      : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              msg.content,
              style: GoogleFonts.inter(
                fontSize: 13,
                color: isAdmin ? Colors.white : AppTheme.textPrimaryColor,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReplyEditor(_SupportTicket ticket) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: AppTheme.borderColor)),
      ),
      child: Column(
        children: [
          // Toolbar
          Row(
            children: [
              _toolbarBtn(Icons.format_bold),
              _toolbarBtn(Icons.format_italic),
              _toolbarBtn(Icons.format_list_bulleted),
              _toolbarBtn(Icons.attach_file),
              _toolbarBtn(Icons.image_outlined),
              const Spacer(),
              Text('INTERNAL NOTE ONLY', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: AppTheme.textTertiaryColor)),
              const SizedBox(width: 6),
              Theme(
                data: Theme.of(context).copyWith(
                  switchTheme: SwitchThemeData(
                    thumbColor: WidgetStateProperty.all(AppTheme.primaryColor),
                    trackColor: WidgetStateProperty.resolveWith((states) {
                      if (states.contains(WidgetState.selected)) {
                        return AppTheme.primaryColor.withValues(alpha: 0.5);
                      }
                      return null;
                    }),
                  ),
                ),
                child: Switch(
                  value: _isInternalNote,
                  onChanged: (v) => setState(() => _isInternalNote = v),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Text Field
          TextField(
            controller: _replyController,
            maxLines: 2,
            style: GoogleFonts.inter(fontSize: 13),
            decoration: InputDecoration(
              hintText: 'Type your reply to ${ticket.userName}...',
              hintStyle: GoogleFonts.inter(fontSize: 13, color: AppTheme.textTertiaryColor),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppTheme.borderColor),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(color: AppTheme.borderColor),
              ),
              contentPadding: const EdgeInsets.all(14),
            ),
          ),
          const SizedBox(height: 12),

          // Action Bar
          Row(
            children: [
              // Smart Template
              TextButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.auto_awesome, size: 16, color: AppTheme.textSecondaryColor),
                label: Text(
                  'Smart Template',
                  style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: AppTheme.textSecondaryColor),
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () {},
                child: Text(
                  'SAVE DRAFT',
                  style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w800, color: AppTheme.textSecondaryColor, letterSpacing: 0.5),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: () {},
                icon: const Text('RESOLVE & SEND', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800)),
                label: const Icon(Icons.send, size: 16),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyInteraction() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.borderColor),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.support_agent_rounded, size: 48, color: AppTheme.textTertiaryColor.withValues(alpha: 0.4)),
            const SizedBox(height: 12),
            Text('Select a ticket', style: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600, color: AppTheme.textSecondaryColor)),
            Text('Choose a support ticket from the queue', style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textTertiaryColor)),
          ],
        ),
      ),
    );
  }

  Widget _toolbarBtn(IconData icon) {
    return InkWell(
      onTap: () {},
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Icon(icon, size: 18, color: AppTheme.textSecondaryColor),
      ),
    );
  }
}
