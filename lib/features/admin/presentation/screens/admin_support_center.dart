import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme.dart';
import '../../../../core/providers/admin_providers.dart';
import '../../../../core/providers.dart';
import '../../../../core/models/support_ticket.dart';

// ─────────────────────────────────────────────────────────────────────
// ADMIN SUPPORT CENTER — Dual-pane ticket management hub
// ─────────────────────────────────────────────────────────────────────

class AdminSupportCenter extends ConsumerStatefulWidget {
  const AdminSupportCenter({super.key});

  @override
  ConsumerState<AdminSupportCenter> createState() => _AdminSupportCenterState();
}

class _AdminSupportCenterState extends ConsumerState<AdminSupportCenter> {
  String? _selectedTicketId;
  String _activeFilter = 'all'; // 'all', 'patient', 'pharmacy'
  bool _isInternalNote = false;
  final _replyController = TextEditingController();

  @override
  void dispose() {
    _replyController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ticketsAsync = ref.watch(supportTicketsProvider(_activeFilter));
    final urgentList = ref.watch(adminUrgentInventoryProvider).value ?? [];

    return ticketsAsync.when(
      data: (tickets) {
        // Find the selected ticket object
        final selected = _selectedTicketId != null 
            ? tickets.firstWhere((t) => t.id == _selectedTicketId, orElse: () => tickets.first)
            : (tickets.isNotEmpty ? tickets.first : null);

        // Update selected ID if it was null
        if (_selectedTicketId == null && selected != null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) setState(() => _selectedTicketId = selected.id);
          });
        }

        return Padding(
          padding: const EdgeInsets.all(28),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Left: Support Queue (flex 4) ──
              Expanded(
                flex: 4,
                child: _buildSupportQueue(tickets, selected?.id, urgentList),
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
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error loading tickets: $e')),
    );
  }

  // ── Support Queue (Left Pane) ──────────────────────────────────
  Widget _buildSupportQueue(List<SupportTicket> tickets, String? selectedId, List<dynamic> urgentList) {
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

          // Scrollable Queue
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: tickets.length,
              itemBuilder: (context, index) => _buildTicketCard(tickets[index], selectedId),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTicketCard(SupportTicket ticket, String? selectedId) {
    final isSelected = ticket.id == selectedId;
    final isUrgent = ticket.priority == TicketPriority.urgent;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        onTap: () => setState(() => _selectedTicketId = ticket.id),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primaryColor.withValues(alpha: 0.05) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? AppTheme.primaryColor.withValues(alpha: 0.3) : Colors.transparent,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Category + Time
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    ticket.category.toUpperCase(),
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: isUrgent ? const Color(0xFFEF4444) : AppTheme.primaryColor,
                      letterSpacing: 0.5,
                    ),
                  ),
                  Text(
                    _formatDateTime(ticket.updatedAt),
                    style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textTertiaryColor),
                  ),
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
                    '#${ticket.id.substring(0, 6).toUpperCase()}',
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
  Widget _buildActiveInteraction(SupportTicket ticket) {
    final messagesAsync = ref.watch(supportMessagesProvider(ticket.id));

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
                          if (ticket.userType != 'SYSTEM')
                            const Icon(Icons.verified, color: Color(0xFF3B82F6), size: 16),
                        ],
                      ),
                      Text(
                        '${ticket.userType} ID: #${ticket.userId.substring(0, 8)} • Priority: ${ticket.priority.name.toUpperCase()}',
                        style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondaryColor),
                      ),
                    ],
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.folder_shared_outlined, size: 16),
                  label: Text('Details', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600)),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppTheme.borderColor),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.done_all, size: 16),
                  label: Text('Close Ticket', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700)),
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
            child: messagesAsync.when(
              data: (messages) {
                if (messages.isEmpty) {
                  return Center(child: Text('No conversation history yet.', style: GoogleFonts.inter(color: AppTheme.textTertiaryColor)));
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(20),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final msg = messages[index];
                    if (index == 0 && msg.role == UserRole.system) {
                       return _buildOriginalIssue(msg);
                    }
                    return _buildMessageBubble(msg);
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e')),
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
                  'REAL-TIME FIREBASE CONNECTION ACTIVE',
                  style: GoogleFonts.inter(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF22C55E),
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

  Widget _buildOriginalIssue(TicketMessage msg) {
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

  Widget _buildMessageBubble(TicketMessage msg) {
    final isSystem = msg.role == UserRole.system;
    final isAdmin = msg.role == UserRole.admin;

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
                msg.senderName,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: isAdmin ? AppTheme.primaryColor : AppTheme.textPrimaryColor,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                _formatDateTime(msg.timestamp),
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

  Widget _buildReplyEditor(SupportTicket ticket) {
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
                onPressed: () => _handleSendReply(ticket),
                child: Text(
                  'SAVE DRAFT',
                  style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w800, color: AppTheme.textSecondaryColor, letterSpacing: 0.5),
                ),
              ),
              const SizedBox(width: 8),
              ElevatedButton.icon(
                onPressed: () => _handleSendReply(ticket),
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

  Future<void> _handleSendReply(SupportTicket ticket) async {
    final content = _replyController.text.trim();
    if (content.isEmpty) return;

    try {
      final userProfile = ref.read(userProfileProvider).value;
      await ref.read(supportServiceProvider).sendReply(
        ticketId: ticket.id,
        senderName: userProfile?.displayName ?? 'Admin',
        senderId: userProfile?.uid ?? 'system-admin',
        content: content,
        isInternal: _isInternalNote,
      );
      _replyController.clear();
      if (mounted) setState(() => _isInternalNote = false);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error sending reply: $e')),
        );
      }
    }
  }

  String _formatDateTime(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  Widget _filterChip(String label, String value) {
    final isSelected = _activeFilter == value;
    return InkWell(
      onTap: () => setState(() {
        _activeFilter = value;
        _selectedTicketId = null; // Reset selection on filter change
      }),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? AppTheme.primaryColor : AppTheme.borderColor),
        ),
        child: Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            color: isSelected ? Colors.white : AppTheme.textSecondaryColor,
          ),
        ),
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
