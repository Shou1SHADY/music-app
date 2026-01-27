import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'chat_service.dart';
import '../auth/auth_service.dart';
import '../../core/constants.dart';
import '../../models/message_model.dart';
import '../../models/user_model.dart';

class ChatDetailScreen extends ConsumerStatefulWidget {
  final String chatId;
  final UserModel otherUser;

  const ChatDetailScreen({
    super.key,
    required this.chatId,
    required this.otherUser,
  });

  @override
  ConsumerState<ChatDetailScreen> createState() => _ChatDetailScreenState();
}

class _ChatDetailScreenState extends ConsumerState<ChatDetailScreen> {
  final _messageController = TextEditingController();
  final List<MessageModel> _optimisticMessages = [];
  Timer? _timeagoTimer;

  @override
  void initState() {
    super.initState();
    // Refresh timeago every minute
    _timeagoTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _timeagoTimer?.cancel();
    super.dispose();
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final currentUser = ref.read(authServiceProvider).currentUser;
    if (currentUser == null) return;

    // Optimistic insertion
    final optimistic = MessageModel(
      id: 'optimistic_${DateTime.now().millisecondsSinceEpoch}',
      senderId: currentUser.uid,
      receiverId: widget.otherUser.id,
      content: text,
      timestamp: DateTime.now(),
      isRead: false,
    );
    setState(() {
      _optimisticMessages.insert(0, optimistic);
    });

    ref
        .read(chatServiceProvider)
        .sendMessage(widget.chatId, currentUser.uid, text);
    _messageController.clear();
  }

  @override
  Widget build(BuildContext context) {
    try {
      final messagesStream =
          ref.watch(chatServiceProvider).getMessages(widget.chatId);
      final currentUser = ref.watch(authServiceProvider).currentUser;

      if (currentUser == null) {
        return const Scaffold(
          body: Center(child: Text("Authentication required.")),
        );
      }

      return Scaffold(
        backgroundColor: const Color(0xFF0F0F1E),
        appBar: AppBar(
          elevation: 0,
          backgroundColor: const Color(0xFF0F0F1E),
          title: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [AppColors.primary.withOpacity(0.8), AppColors.primary],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: ClipOval(
                  child: widget.otherUser.photoUrl != null &&
                          widget.otherUser.photoUrl!.isNotEmpty
                      ? Image.network(
                          widget.otherUser.photoUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => Center(
                            child: Text(
                              widget.otherUser.displayName.isNotEmpty
                                  ? widget.otherUser.displayName[0]
                                      .toUpperCase()
                                  : '?',
                              style: GoogleFonts.outfit(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return const Center(
                              child: SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                ),
                              ),
                            );
                          },
                        )
                      : Center(
                          child: Text(
                            widget.otherUser.displayName.isNotEmpty
                                ? widget.otherUser.displayName[0].toUpperCase()
                                : '?',
                            style: GoogleFonts.outfit(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.otherUser.displayName,
                      style: GoogleFonts.outfit(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'Active now',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        color: Colors.greenAccent,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.more_vert, color: Colors.white),
              onPressed: () {},
            ),
          ],
        ),
        body: Column(
          children: [
            Expanded(
              child: StreamBuilder<List<MessageModel>>(
                stream: messagesStream,
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Text(
                          'Error loading: ${snapshot.error}',
                          textAlign: TextAlign.center,
                        ),
                      ),
                    );
                  }

                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  final messages = snapshot.data ?? [];
                  // Remove optimistic messages that have been confirmed by the stream
                  final confirmedOptimisticIds = <String>{};
                  for (final msg in messages) {
                    for (final opt in _optimisticMessages) {
                      if (msg.content == opt.content &&
                          (msg.timestamp.difference(opt.timestamp).inSeconds < 5)) {
                        confirmedOptimisticIds.add(opt.id);
                        break;
                      }
                    }
                  }
                  _optimisticMessages.removeWhere((id) => confirmedOptimisticIds.contains(id.id));

                  // Merge optimistic messages with stream messages, dedupe by id
                  final merged = <MessageModel>[
                    ..._optimisticMessages,
                    ...messages,
                  ];
                  // Sort by timestamp descending
                  merged.sort((a, b) => b.timestamp.compareTo(a.timestamp));

                  if (merged.isEmpty) {
                    return const Center(
                      child: Text('No messages yet. Say hi!'),
                    );
                  }

                  return ListView.builder(
                    reverse: true,
                    padding: const EdgeInsets.all(16),
                    itemCount: merged.length,
                    itemBuilder: (context, index) {
                      final msg = merged[index];
                      final isMe = msg.senderId == currentUser.uid;
                      return _buildMessageBubble(msg, isMe);
                    },
                  );
                },
              ),
            ),
            _buildMessageInput(),
          ],
        ),
      );
    } catch (e) {
      debugPrint("CRITICAL ERROR building ChatDetailScreen: $e");
      return Scaffold(
        appBar: AppBar(title: const Text("Chat Error")),
        body: Center(
          child: Text("Something went wrong opening the chat: $e"),
        ),
      );
    }
  }

  Widget _buildMessageBubble(MessageModel message, bool isMe) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Align(
        alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.75,
          ),
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          decoration: BoxDecoration(
            gradient: isMe
                ? LinearGradient(
                    colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : LinearGradient(
                    colors: [const Color(0xFF2A2A3E), const Color(0xFF1F1F2E)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
            borderRadius: BorderRadius.only(
              topLeft: const Radius.circular(20),
              topRight: const Radius.circular(20),
              bottomLeft: Radius.circular(isMe ? 20 : 6),
              bottomRight: Radius.circular(isMe ? 6 : 20),
            ),
            boxShadow: [
              BoxShadow(
                color: (isMe ? AppColors.primary : const Color(0xFF2A2A3E)).withOpacity(0.3),
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
                message.content,
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                timeago.format(message.timestamp, locale: 'en_short'),
                style: GoogleFonts.outfit(
                  color: Colors.white.withOpacity(0.6),
                  fontSize: 11,
                  fontWeight: FontWeight.w400,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F0F1E),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFF2A2A3E),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                    color: AppColors.primary.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: TextField(
                  controller: _messageController,
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Type a message...',
                    hintStyle: GoogleFonts.outfit(
                      color: Colors.white.withOpacity(0.4),
                      fontSize: 15,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    prefixIcon: IconButton(
                      icon: Icon(
                        Icons.add_circle_outline,
                        color: Colors.white.withOpacity(0.6),
                        size: 24,
                      ),
                      onPressed: () {},
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: IconButton(
                icon: const Icon(
                  Icons.send_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                onPressed: _sendMessage,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
