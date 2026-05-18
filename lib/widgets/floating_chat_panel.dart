import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../core/theme.dart';
import '../core/providers.dart';
import '../core/services/chat_service.dart';
import '../core/models/user_profile.dart';

/// Shows the floating chat panel as an overlay on top of the current screen.
/// Call this from either the patient or pharmacy dashboard.
void showFloatingChatPanel(BuildContext context, {required String userRole}) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.3),
    builder: (context) => FloatingChatPanel(userRole: userRole),
  );
}

class FloatingChatPanel extends ConsumerStatefulWidget {
  final String userRole; // 'patient' or 'pharmacy'

  const FloatingChatPanel({super.key, required this.userRole});

  @override
  ConsumerState<FloatingChatPanel> createState() => _FloatingChatPanelState();
}

class _FloatingChatPanelState extends ConsumerState<FloatingChatPanel> {
  // null = conversations list, non-null = active chat
  String? _activeChatUserId;
  String? _activeChatUserName;
  String? _activeChatUserPhoto;
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  void _openChat(String userId, String userName, String? photo) {
    HapticFeedback.lightImpact();
    setState(() {
      _activeChatUserId = userId;
      _activeChatUserName = userName;
      _activeChatUserPhoto = photo;
    });

    // Mark as read
    final currentUser = ref.read(authProvider);
    if (currentUser != null) {
      final chatService = ref.read(chatServiceProvider);
      final ids = [currentUser.id, userId]..sort();
      final chatId = ids.join('_');
      chatService.markAsRead(chatId, currentUser.id);
    }
  }

  void _goBackToList() {
    HapticFeedback.lightImpact();
    setState(() {
      _activeChatUserId = null;
      _activeChatUserName = null;
      _activeChatUserPhoto = null;
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Container(
      height: screenHeight * 0.75,
      decoration: BoxDecoration(
        color: AppTheme.backgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 30,
            offset: const Offset(0, -10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        child: Column(
          children: [
            // Drag handle
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 4),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            // Content: either conversations list or active chat
            Expanded(
              child: _activeChatUserId != null
                  ? _ActiveChatView(
                      receiverId: _activeChatUserId!,
                      receiverName: _activeChatUserName!,
                      receiverPhoto: _activeChatUserPhoto,
                      onBack: _goBackToList,
                    )
                  : _buildConversationsList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConversationsList() {
    final user = ref.watch(authProvider);
    if (user == null) {
      return const Center(child: Text('Please log in to chat.'));
    }

    return Column(
      children: [
        // Header
        _buildHeader(),
        // Search bar
        _buildSearchBar(),
        const SizedBox(height: 8),
        // Conversations
        Expanded(
          child: StreamBuilder<List<ChatConversation>>(
            stream: ref.watch(chatServiceProvider).getConversations(user.id),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: AppTheme.primaryColor),
                );
              }

              final conversations = snapshot.data ?? [];
              final filtered = _searchQuery.isEmpty
                  ? conversations
                  : conversations
                      .where((c) => c.otherUserName
                          .toLowerCase()
                          .contains(_searchQuery.toLowerCase()))
                      .toList();

              if (filtered.isEmpty && conversations.isEmpty) {
                return _buildEmptyState();
              }

              if (filtered.isEmpty) {
                return Center(
                  child: Text(
                    'No conversations matching "$_searchQuery"',
                    style: GoogleFonts.inter(color: AppTheme.textTertiaryColor),
                  ),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                itemCount: filtered.length,
                separatorBuilder: (_, __) => Divider(
                  color: AppTheme.borderColor.withValues(alpha: 0.5),
                  height: 1,
                  indent: 68,
                ),
                itemBuilder: (context, index) {
                  final convo = filtered[index];
                  return _buildConversationTile(convo);
                },
              );
            },
          ),
        ),
        // New Chat Button
        if (widget.userRole == 'patient') _buildNewChatButton(),
      ],
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppTheme.primaryColor, Color(0xFFF97316)],
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.chat_bubble_rounded, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Messages',
                  style: GoogleFonts.inter(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
                Text(
                  widget.userRole == 'patient'
                      ? 'Chat with verified pharmacies'
                      : 'Patient conversations',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: AppTheme.textTertiaryColor,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close_rounded, color: AppTheme.textSecondaryColor),
            onPressed: () => Navigator.pop(context),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.borderColor),
        ),
        child: TextField(
          controller: _searchController,
          onChanged: (val) => setState(() => _searchQuery = val),
          style: GoogleFonts.inter(fontSize: 14),
          decoration: InputDecoration(
            hintText: 'Search conversations...',
            hintStyle: GoogleFonts.inter(color: AppTheme.textTertiaryColor, fontSize: 14),
            prefixIcon: const Icon(Icons.search, color: AppTheme.textTertiaryColor, size: 20),
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 12),
          ),
        ),
      ),
    );
  }

  Widget _buildConversationTile(ChatConversation convo) {
    final timeAgo = _formatTimeAgo(convo.lastTimestamp);
    final hasUnread = convo.unreadCount > 0;

    return InkWell(
      onTap: () => _openChat(convo.otherUserId, convo.otherUserName, convo.otherUserPhoto),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        child: Row(
          children: [
            // Avatar with online indicator
            Stack(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                  backgroundImage: convo.otherUserPhoto != null
                      ? NetworkImage(convo.otherUserPhoto!)
                      : null,
                  child: convo.otherUserPhoto == null
                      ? Text(
                          convo.otherUserName.isNotEmpty
                              ? convo.otherUserName[0].toUpperCase()
                              : '?',
                          style: GoogleFonts.inter(
                            color: AppTheme.primaryColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        )
                      : null,
                ),
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: convo.isOtherUserOnline
                          ? const Color(0xFF22C55E)
                          : Colors.grey,
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 2),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(width: 14),
            // Name, last message
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          convo.otherUserName,
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            fontWeight: hasUnread ? FontWeight.bold : FontWeight.w600,
                            color: AppTheme.textPrimaryColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Text(
                        timeAgo,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          color: hasUnread
                              ? AppTheme.primaryColor
                              : AppTheme.textTertiaryColor,
                          fontWeight: hasUnread ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          convo.lastMessage,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            color: hasUnread
                                ? AppTheme.textPrimaryColor
                                : AppTheme.textTertiaryColor,
                            fontWeight: hasUnread ? FontWeight.w500 : FontWeight.normal,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (hasUnread)
                        Container(
                          margin: const EdgeInsets.only(left: 8),
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${convo.unreadCount}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.chat_bubble_outline_rounded,
              size: 48,
              color: AppTheme.primaryColor.withValues(alpha: 0.4),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'No conversations yet',
            style: GoogleFonts.inter(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            widget.userRole == 'patient'
                ? 'Tap below to start chatting\nwith a verified pharmacy'
                : 'Patient messages will\nappear here',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: AppTheme.textTertiaryColor,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNewChatButton() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      child: SizedBox(
        width: double.infinity,
        height: 52,
        child: ElevatedButton.icon(
          onPressed: () => _showPharmacyPicker(),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.primaryColor,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            elevation: 0,
          ),
          icon: const Icon(Icons.add_comment_rounded, size: 20),
          label: Text(
            'Chat with a Pharmacy',
            style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 15),
          ),
        ),
      ),
    );
  }

  void _showPharmacyPicker() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) => _PharmacyPickerSheet(
        onSelect: (pharmacy) {
          Navigator.pop(ctx); // Close picker
          _openChat(
            pharmacy.uid,
            pharmacy.displayName ?? pharmacy.name,
            pharmacy.photoUrl,
          );
        },
      ),
    );
  }

  String _formatTimeAgo(DateTime dateTime) {
    final diff = DateTime.now().difference(dateTime);
    if (diff.inMinutes < 1) return 'Now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m';
    if (diff.inHours < 24) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return '${dateTime.day}/${dateTime.month}';
  }
}

// ─────────────────────────────────────────────────────────────────────
// Active Chat View (inline within the panel)
// ─────────────────────────────────────────────────────────────────────

class _ActiveChatView extends ConsumerStatefulWidget {
  final String receiverId;
  final String receiverName;
  final String? receiverPhoto;
  final VoidCallback onBack;

  const _ActiveChatView({
    required this.receiverId,
    required this.receiverName,
    this.receiverPhoto,
    required this.onBack,
  });

  @override
  ConsumerState<_ActiveChatView> createState() => _ActiveChatViewState();
}

class _ActiveChatViewState extends ConsumerState<_ActiveChatView> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final user = ref.read(authProvider);
    if (user == null) return;

    HapticFeedback.lightImpact();

    final userProfile = ref.read(userProfileProvider).value;

    ref.read(chatServiceProvider).sendMessage(
      user.id,
      widget.receiverId,
      text,
      senderName: userProfile?.displayName ?? userProfile?.name,
      senderPhoto: userProfile?.photoUrl,
      receiverName: widget.receiverName,
      receiverPhoto: widget.receiverPhoto,
    );
    _messageController.clear();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider);
    if (user == null) {
      return const Center(child: Text('Please log in'));
    }

    final messagesStream =
        ref.watch(chatServiceProvider).getMessages(user.id, widget.receiverId);

    return Column(
      children: [
        // Chat header
        _buildChatHeader(),
        // Divider
        Container(height: 1, color: AppTheme.borderColor),
        // Messages
        Expanded(
          child: StreamBuilder<List<ChatMessage>>(
            stream: messagesStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(color: AppTheme.primaryColor),
                );
              }

              final messages = snapshot.data ?? [];

              if (messages.isEmpty) {
                return _buildChatEmptyState();
              }

              return ListView.builder(
                controller: _scrollController,
                reverse: true,
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final message = messages[index];
                  final isMe = message.senderId == user.id;
                  return _buildMessageBubble(message, isMe);
                },
              );
            },
          ),
        ),
        // Input
        _buildMessageInput(),
      ],
    );
  }

  Widget _buildChatHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 8),
      color: Colors.white,
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: AppTheme.textPrimaryColor),
            onPressed: widget.onBack,
          ),
          CircleAvatar(
            radius: 18,
            backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
            backgroundImage: widget.receiverPhoto != null
                ? NetworkImage(widget.receiverPhoto!)
                : null,
            child: widget.receiverPhoto == null
                ? Text(
                    widget.receiverName.isNotEmpty
                        ? widget.receiverName[0].toUpperCase()
                        : '?',
                    style: GoogleFonts.inter(
                      color: AppTheme.primaryColor,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.receiverName,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimaryColor,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                // Online status
                StreamBuilder<bool>(
                  stream: ref.watch(chatServiceProvider).getOnlineStatus(widget.receiverId),
                  builder: (context, snap) {
                    final isOnline = snap.data ?? false;
                    return Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: isOnline ? const Color(0xFF22C55E) : Colors.grey,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          isOnline ? 'Online' : 'Offline',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: isOnline ? const Color(0xFF22C55E) : AppTheme.textTertiaryColor,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
          // Verified badge for pharmacies
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.blue.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.verified, color: Colors.blue, size: 18),
          ),
        ],
      ),
    );
  }

  Widget _buildChatEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.primaryColor.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.waving_hand_rounded,
              size: 36,
              color: AppTheme.primaryColor.withValues(alpha: 0.5),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Say hello!',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimaryColor,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Ask about medications, prescriptions\nor product availability',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: AppTheme.textTertiaryColor,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(ChatMessage message, bool isMe) {
    String timeStr = '';
    final dt = message.timestamp;
    final hour = dt.hour % 12 == 0 ? 12 : dt.hour % 12;
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    timeStr = '$hour:${dt.minute.toString().padLeft(2, '0')} $period';

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.7,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isMe ? AppTheme.primaryColor : Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(isMe ? 18 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 18),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              message.text,
              style: GoogleFonts.inter(
                color: isMe ? Colors.white : AppTheme.textPrimaryColor,
                fontSize: 14,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  timeStr,
                  style: GoogleFonts.inter(
                    color: isMe
                        ? Colors.white.withValues(alpha: 0.7)
                        : AppTheme.textTertiaryColor,
                    fontSize: 10,
                  ),
                ),
                if (isMe) ...[
                  const SizedBox(width: 4),
                  Icon(
                    Icons.done_all,
                    size: 14,
                    color: Colors.white.withValues(alpha: 0.7),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: _messageController,
                onSubmitted: (_) => _sendMessage(),
                textInputAction: TextInputAction.send,
                style: GoogleFonts.inter(fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Type a message...',
                  hintStyle: GoogleFonts.inter(
                    color: AppTheme.textTertiaryColor,
                    fontSize: 14,
                  ),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          GestureDetector(
            onTap: _sendMessage,
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.primaryColor, Color(0xFFF97316)],
                ),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────
// Pharmacy Picker Sheet (for patients starting new chats)
// ─────────────────────────────────────────────────────────────────────

class _PharmacyPickerSheet extends ConsumerWidget {
  final Function(UserProfile) onSelect;

  const _PharmacyPickerSheet({required this.onSelect});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pharmacies = ref.watch(verifiedPharmaciesProvider).value ?? [];

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.5,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                const Icon(Icons.local_pharmacy, color: AppTheme.primaryColor, size: 22),
                const SizedBox(width: 10),
                Text(
                  'Select a Pharmacy',
                  style: GoogleFonts.inter(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimaryColor,
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              '${pharmacies.length} verified ${pharmacies.length == 1 ? 'pharmacy' : 'pharmacies'} available',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: AppTheme.textTertiaryColor,
              ),
            ),
          ),
          const SizedBox(height: 8),
          // List
          Flexible(
            child: pharmacies.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(32),
                    child: Text(
                      'No verified pharmacies available at the moment.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(color: AppTheme.textTertiaryColor),
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
                    itemCount: pharmacies.length,
                    itemBuilder: (context, index) {
                      final ph = pharmacies[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Material(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          child: InkWell(
                            onTap: () => onSelect(ph),
                            borderRadius: BorderRadius.circular(14),
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: AppTheme.borderColor),
                              ),
                              child: Row(
                                children: [
                                  Stack(
                                    children: [
                                      CircleAvatar(
                                        radius: 22,
                                        backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.1),
                                        backgroundImage: ph.photoUrl != null
                                            ? NetworkImage(ph.photoUrl!)
                                            : null,
                                        child: ph.photoUrl == null
                                            ? Text(
                                                (ph.displayName ?? ph.name).isNotEmpty 
                                                    ? (ph.displayName ?? ph.name)[0].toUpperCase() 
                                                    : 'P',
                                                style: GoogleFonts.inter(
                                                  color: AppTheme.primaryColor,
                                                  fontWeight: FontWeight.bold,
                                                ),
                                              )
                                            : null,
                                      ),
                                      Positioned(
                                        bottom: 0,
                                        right: 0,
                                        child: Container(
                                          width: 12,
                                          height: 12,
                                          decoration: BoxDecoration(
                                            color: const Color(0xFF22C55E),
                                            shape: BoxShape.circle,
                                            border: Border.all(color: Colors.white, width: 2),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Row(
                                          children: [
                                            Flexible(
                                              child: Text(
                                                ph.displayName ?? ph.name,
                                                style: GoogleFonts.inter(
                                                  fontWeight: FontWeight.w600,
                                                  fontSize: 15,
                                                  color: AppTheme.textPrimaryColor,
                                                ),
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                              ),
                                            ),
                                            const SizedBox(width: 6),
                                            const Icon(Icons.verified, color: Colors.blue, size: 16),
                                          ],
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          'Available • Quick Response',
                                          style: GoogleFonts.inter(
                                            fontSize: 12,
                                            color: const Color(0xFF22C55E),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: AppTheme.primaryColor,
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      'Chat',
                                      style: GoogleFonts.inter(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 13,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
