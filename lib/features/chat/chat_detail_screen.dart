import 'dart:async';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:image_picker/image_picker.dart';
import 'chat_service.dart';
import '../auth/auth_service.dart';
import '../../core/constants.dart';
import '../../models/message_model.dart';
import '../../models/user_model.dart';
import '../../services/presence_service.dart';

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
  final ImagePicker _imagePicker = ImagePicker();
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    // Configure timeago for better local time display
    timeago.setLocaleMessages('en_short', timeago.EnShortMessages());
    // Refresh timeago every minute
    _timeagoTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
    
    // Set user as online when opening chat
    _setUserOnline();
    // Mark all messages as read when opening chat
    _markAllMessagesAsRead();
  }

  void _setUserOnline() async {
    final currentUser = ref.read(authServiceProvider).currentUser;
    if (currentUser != null) {
      await ref.read(presenceServiceProvider).updateUserPresence(currentUser.uid, isOnline: true);
    }
  }

  void _setUserOffline() async {
    if (!mounted) return;
    final currentUser = ref.read(authServiceProvider).currentUser;
    if (currentUser != null) {
      await ref.read(presenceServiceProvider).setUserOffline(currentUser.uid);
    }
  }

  void _markAllMessagesAsRead() async {
    final currentUser = ref.read(authServiceProvider).currentUser;
    if (currentUser != null) {
      await ref.read(chatServiceProvider).markAllMessagesAsRead(widget.chatId, currentUser.uid);
    }
  }

  @override
  void dispose() {
    _messageController.dispose();
    _timeagoTimer?.cancel();
    _setUserOffline();
    super.dispose();
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    final currentUser = ref.read(authServiceProvider).currentUser!;
    final message = MessageModel(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      senderId: currentUser.uid,
      receiverId: widget.otherUser.id,
      content: text,
      timestamp: DateTime.now(),
      isRead: false,
    );

    setState(() {
      _optimisticMessages.insert(0, message);
    });

    ref.read(chatServiceProvider).sendMessage(
          widget.chatId,
          currentUser.uid,
          text,
          imageUrl: null,
        );

    _messageController.clear();
  }

  Future<void> _sendImage() async {
    try {
      final XFile? image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );

      if (image == null) return;

      setState(() => _isUploading = true);

      final currentUser = ref.read(authServiceProvider).currentUser!;

      // For now, we'll send the image as a file path
      // In a real app, you'd upload to Firebase Storage first
      final message = MessageModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        senderId: currentUser.uid,
        receiverId: widget.otherUser.id,
        content: '[Image: ${image.name}]',
        timestamp: DateTime.now(),
        isRead: false,
        imageUrl: image.path, // This would be the Firebase Storage URL
      );

      setState(() {
        _optimisticMessages.insert(0, message);
      });

      // TODO: Upload image to Firebase Storage and get URL
      // For now, we'll just send the message with local path
      await ref.read(chatServiceProvider).sendMessage(
            widget.chatId,
            currentUser.uid,
            '[Image: ${image.name}]',
            imageUrl: image.path,
          );

      if (mounted) {
        setState(() => _isUploading = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send image: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  void _showMediaOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1A2E),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Share Media',
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              leading: Icon(Icons.photo_library, color: AppColors.primary),
              title: Text(
                'Photo from Gallery',
                style: GoogleFonts.outfit(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(context);
                _sendImage();
              },
            ),
            ListTile(
              leading: Icon(Icons.camera_alt, color: AppColors.primary),
              title: Text(
                'Take Photo',
                style: GoogleFonts.outfit(color: Colors.white),
              ),
              onTap: () {
                Navigator.pop(context);
                _takePhoto();
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _takePhoto() async {
    try {
      final XFile? photo = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 80,
      );

      if (photo == null) return;

      setState(() => _isUploading = true);

      final currentUser = ref.read(authServiceProvider).currentUser!;

      final message = MessageModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        senderId: currentUser.uid,
        receiverId: widget.otherUser.id,
        content: '[Photo: ${photo.name}]',
        timestamp: DateTime.now(),
        isRead: false,
        imageUrl: photo.path,
      );

      setState(() {
        _optimisticMessages.insert(0, message);
      });

      await ref.read(chatServiceProvider).sendMessage(
            widget.chatId,
            currentUser.uid,
            '[Photo: ${photo.name}]',
            imageUrl: photo.path,
          );

      if (mounted) {
        setState(() => _isUploading = false);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isUploading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to take photo: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
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
                    StreamBuilder<DocumentSnapshot>(
                      stream: ref.read(presenceServiceProvider).getUserPresenceStream(widget.otherUser.id),
                      builder: (context, snapshot) {
                        if (snapshot.hasData && snapshot.data!.exists) {
                          final data = snapshot.data!.data() as Map<String, dynamic>?;
                          final isOnline = data?['isOnline'] == true;
                          final lastSeen = (data?['lastSeen'] as Timestamp?)?.toDate();
                          
                          return Text(
                            isOnline ? 'Active now' : 'Last seen ${ref.read(presenceServiceProvider).formatLastSeen(lastSeen)}',
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              color: isOnline ? Colors.greenAccent : Colors.white.withOpacity(0.6),
                              fontWeight: FontWeight.w400,
                            ),
                          );
                        }
                        return Text(
                          'Checking status...',
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.6),
                            fontWeight: FontWeight.w400,
                          ),
                        );
                      },
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

  String _formatMessageTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
    // Convert to local time
    final localTime = timestamp.toLocal();
    
    // If less than 1 minute ago
    if (difference.inSeconds < 60) {
      return 'now';
    }
    
    // If less than 1 hour ago
    if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m';
    }
    
    // If less than 24 hours ago
    if (difference.inHours < 24) {
      return '${difference.inHours}h';
    }
    
    // If less than 7 days ago
    if (difference.inDays < 7) {
      return '${difference.inDays}d';
    }
    
    // Otherwise show date
    return '${localTime.day}/${localTime.month}/${localTime.year}';
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
              // Show image if present
              if (message.imageUrl != null) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    File(message.imageUrl!),
                    width: 200,
                    height: 200,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        width: 200,
                        height: 200,
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          Icons.broken_image,
                          color: Colors.white.withOpacity(0.6),
                          size: 40,
                        ),
                      );
                    },
                  ),
                ),
                if (message.content != '[Image: ${message.imageUrl!.split('/').last}]' && 
                    message.content != '[Photo: ${message.imageUrl!.split('/').last}]')
                  const SizedBox(height: 8),
              ],
              // Show text content if it's not just an image placeholder
              if (!message.content.startsWith('[Image:') && 
                  !message.content.startsWith('[Photo:')) ...[
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
              ],
              Row(
                mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
                children: [
                  Text(
                    _formatMessageTime(message.timestamp),
                    style: GoogleFonts.outfit(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 11,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                  if (isMe) ...[
                    SizedBox(width: 4),
                    Icon(
                      message.isRead ? Icons.done_all_rounded : Icons.done_rounded,
                      color: message.isRead ? Colors.blue : Colors.white.withOpacity(0.6),
                      size: 14,
                    ),
                  ],
                ],
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
                    prefixIcon: _isUploading
                        ? Container(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                            ),
                          )
                        : IconButton(
                            icon: Icon(
                              Icons.add_circle_outline,
                              color: Colors.white.withOpacity(0.6),
                              size: 24,
                            ),
                            onPressed: _showMediaOptions,
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
