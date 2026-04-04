import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../core/theme.dart';
import '../../../../core/providers/admin_providers.dart';
import '../../../../core/providers.dart';
import '../../../../core/models/support_ticket.dart';

/// ADMIN SUPPORT COMMAND CENTER — High-fidelity interaction hub.
class AdminSupportCenter extends ConsumerStatefulWidget {
  const AdminSupportCenter({super.key});

  @override
  ConsumerState<AdminSupportCenter> createState() => _AdminSupportCenterState();
}

class _AdminSupportCenterState extends ConsumerState<AdminSupportCenter> {
  String? _selectedTicketId;
  String _activeFilter = 'all'; 
  bool _isInternalNote = false;
  final _replyController = TextEditingController();
  Timer? _slaTimer;

  @override
  void initState() {
    super.initState();
    _slaTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _replyController.dispose();
    _slaTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ticketsAsync = ref.watch(supportTicketsProvider(_activeFilter));

    return ticketsAsync.when(
      data: (tickets) {
        final selected = _selectedTicketId != null 
            ? tickets.firstWhere((t) => t.id == _selectedTicketId, orElse: () => tickets.first)
            : (tickets.isNotEmpty ? tickets.first : null);

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
              // ── Left: Management Queue ──
              Expanded(
                flex: 4,
                child: _buildQueuePane(tickets, selected?.id),
              ),
              const SizedBox(width: 24),

              // ── Right: Command Interaction ──
              Expanded(
                flex: 6,
                child: selected != null
                    ? _buildInteractionPane(selected)
                    : _buildEmptyPane(),
              ),
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Telemetry Sync Error: $e')),
    );
  }

  Widget _buildQueuePane(List<SupportTicket> tickets, String? selectedId) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.borderColor),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.03), blurRadius: 20, offset: const Offset(0, 8))
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Support Latency', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.textPrimaryColor)),
                _pulseBadge('${tickets.length} ACTIVE'),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                _filterTab('PATIENTS', 'patient'),
                const SizedBox(width: 8),
                _filterTab('PHARMACIES', 'pharmacy'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: tickets.length,
              itemBuilder: (context, index) => _ticketTile(tickets[index], selectedId),
            ),
          ),
        ],
      ),
    );
  }

  Widget _ticketTile(SupportTicket ticket, String? selectedId) {
    final isSelected = ticket.id == selectedId;
    final isUrgent = ticket.priority == TicketPriority.urgent;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => setState(() => _selectedTicketId = ticket.id),
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isSelected ? AppTheme.primaryColor.withValues(alpha: 0.05) : Colors.transparent,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? AppTheme.primaryColor.withValues(alpha: 0.4) : Colors.transparent,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(ticket.category.toUpperCase(), style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w900, color: isUrgent ? const Color(0xFFEF4444) : AppTheme.primaryColor, letterSpacing: 1.0)),
                  _slaTimerWidget(ticket.updatedAt),
                ],
              ),
              const SizedBox(height: 8),
              Text(ticket.userName, style: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.textPrimaryColor)),
              const SizedBox(height: 4),
              Text(ticket.snippet, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.inter(fontSize: 12, color: AppTheme.textSecondaryColor)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInteractionPane(SupportTicket ticket) {
    final messagesAsync = ref.watch(supportMessagesProvider(ticket.id));

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppTheme.borderColor),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 24, offset: const Offset(0, 10))
        ],
      ),
      child: Column(
        children: [
          // Header
          _paneHeader(ticket),
          
          // Messages
          Expanded(
            child: messagesAsync.when(
              data: (messages) => ListView.builder(
                padding: const EdgeInsets.all(24),
                itemCount: messages.length,
                itemBuilder: (context, index) => _messageBubble(messages[index]),
              ),
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Transmission Break: $e')),
            ),
          ),

          // Editor
          _replyCommand(ticket),
        ],
      ),
    );
  }

  Widget _paneHeader(SupportTicket ticket) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: AppTheme.borderColor))),
      child: Row(
        children: [
          CircleAvatar(radius: 24, backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1), child: const Icon(Icons.person_outline_rounded, color: AppTheme.primaryColor)),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(ticket.userName, style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800, color: AppTheme.textPrimaryColor)),
                Text('TRANSACTION ID: #${ticket.id.substring(0, 8).toUpperCase()} • ${ticket.userType}', style: GoogleFonts.inter(fontSize: 11, color: AppTheme.textTertiaryColor, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          _statusPill(ticket.priority.name.toUpperCase()),
        ],
      ),
    );
  }

  Widget _messageBubble(TicketMessage msg) {
    final isAdmin = msg.role == UserRole.admin;
    final isInternal = msg.isInternal;

    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: isAdmin ? CrossAxisAlignment.end : CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (!isAdmin) Text(msg.senderName, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w800, color: AppTheme.textSecondaryColor)),
              const SizedBox(width: 8),
              Text(_formatTime(msg.timestamp), style: GoogleFonts.inter(fontSize: 10, color: AppTheme.textTertiaryColor)),
              if (isAdmin) const SizedBox(width: 8),
              if (isAdmin) Text('STAFF AUDITOR', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w900, color: AppTheme.primaryColor)),
            ],
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isInternal ? const Color(0xFFFEF3C7) : (isAdmin ? const Color(0xFF0F172A) : AppTheme.backgroundColor),
              borderRadius: BorderRadius.circular(16),
              border: isInternal ? Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.3)) : null,
            ),
            child: Text(
              msg.content,
              style: GoogleFonts.inter(fontSize: 14, color: isAdmin && !isInternal ? Colors.white : AppTheme.textPrimaryColor, height: 1.5),
            ),
          ),
          if (isInternal) Padding(padding: const EdgeInsets.only(top: 4, left: 4), child: Text('INTERNAL COMPLIANCE NOTE', style: GoogleFonts.inter(fontSize: 9, fontWeight: FontWeight.w800, color: const Color(0xFFD97706)))),
        ],
      ),
    );
  }

  Widget _replyCommand(SupportTicket ticket) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(border: Border(top: BorderSide(color: AppTheme.borderColor))),
      child: Column(
        children: [
          Row(
            children: [
              Text('INTERNAL COMPLIANCE ONLY', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w800, color: AppTheme.textTertiaryColor)),
              const SizedBox(width: 8),
              Switch(
                value: _isInternalNote,
                onChanged: (v) => setState(() => _isInternalNote = v),
                activeTrackColor: AppTheme.primaryColor.withValues(alpha: 0.4),
                activeThumbColor: AppTheme.primaryColor,
              ),
              const Spacer(),
              _toolIcon(Icons.attach_file_rounded),
              _toolIcon(Icons.auto_awesome_rounded),
            ],
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _replyController,
            maxLines: 3,
            decoration: InputDecoration(
              hintText: 'Transmit instructions to ${ticket.userName}...',
              filled: true,
              fillColor: AppTheme.backgroundColor.withValues(alpha: 0.5),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.all(20),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              OutlinedButton(
                onPressed: () {},
                style: OutlinedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16)),
                child: Text('RESOLVE CASE', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w800, color: AppTheme.textSecondaryColor)),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: () => _handleSend(ticket),
                icon: const Icon(Icons.send_rounded, size: 18),
                label: Text('SEND TRANSMISSION', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w900)),
                style: ElevatedButton.styleFrom(backgroundColor: _isInternalNote ? const Color(0xFFF59E0B) : AppTheme.primaryColor, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 18), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _slaTimerWidget(DateTime lastUpdate) {
    final diff = DateTime.now().difference(lastUpdate);
    final isCritical = diff.inMinutes >= 10;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: (isCritical ? const Color(0xFFEF4444) : const Color(0xFF22C55E)).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.timer_outlined, size: 10, color: isCritical ? const Color(0xFFEF4444) : const Color(0xFF22C55E)),
          const SizedBox(width: 4),
          Text(
            '${diff.inMinutes}m ago',
            style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w800, color: isCritical ? const Color(0xFFEF4444) : const Color(0xFF22C55E)),
          ),
        ],
      ),
    );
  }

  Widget _pulseBadge(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(color: const Color(0xFF22C55E).withValues(alpha: 0.1), borderRadius: BorderRadius.circular(20)),
      child: Text(text, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w900, color: const Color(0xFF22C55E))),
    );
  }

  Widget _statusPill(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: AppTheme.backgroundColor, borderRadius: BorderRadius.circular(8), border: Border.all(color: AppTheme.borderColor)),
      child: Text(text, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w800, color: AppTheme.textPrimaryColor)),
    );
  }

  Widget _filterTab(String label, String value) {
    final isSelected = _activeFilter == value;
    return InkWell(
      onTap: () => setState(() => _activeFilter = value),
      child: Column(
        children: [
          Text(label, style: GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w800, color: isSelected ? AppTheme.primaryColor : AppTheme.textTertiaryColor)),
          const SizedBox(height: 4),
          if (isSelected) Container(width: 24, height: 2, color: AppTheme.primaryColor),
        ],
      ),
    );
  }

  Widget _toolIcon(IconData icon) {
    return Padding(padding: const EdgeInsets.only(left: 8), child: Icon(icon, size: 18, color: AppTheme.textTertiaryColor));
  }

  String _formatTime(DateTime dt) => '${dt.hour}:${dt.minute.toString().padLeft(2, '0')}';

  Future<void> _handleSend(SupportTicket ticket) async {
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
      setState(() => _isInternalNote = false);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Transmission Error: $e')));
    }
  }

  Widget _buildEmptyPane() {
    return Container(
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), border: Border.all(color: AppTheme.borderColor)),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.support_agent_rounded, size: 48, color: AppTheme.textTertiaryColor.withValues(alpha: 0.3)),
            const SizedBox(height: 16),
            Text('Awaiting Signal', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700, color: AppTheme.textSecondaryColor)),
          ],
        ),
      ),
    );
  }
}
