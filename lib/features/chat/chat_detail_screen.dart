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

  @override
  void dispose() {
    _messageController.dispose();
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
        appBar: AppBar(title: Text('Chat with ${widget.otherUser.displayName}')),
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
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isMe ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment:
              isMe ? CrossAxisAlignment.end : CrossAxisAlignment.start,
          children: [
            Text(
              message.content,
              style: GoogleFonts.outfit(
                color: Colors.white,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              timeago.format(message.timestamp, locale: 'en_short'),
              style: GoogleFonts.outfit(
                color: Colors.white70,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: Colors.white.withOpacity(0.1))),
      ),
      child: SafeArea(
        child: Row(
          children: [
            Expanded(
              child: TextField(
                controller: _messageController,
                style: GoogleFonts.outfit(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Type a message...',
                  hintStyle: GoogleFonts.outfit(color: AppColors.textMuted),
                  filled: true,
                  fillColor: AppColors.background,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              icon: const Icon(Icons.send_rounded, color: AppColors.primary),
              onPressed: _sendMessage,
            ),
          ],
        ),
      ),
    );
  }
}
