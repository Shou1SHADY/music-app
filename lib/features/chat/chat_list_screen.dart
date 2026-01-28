import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'chat_service.dart';
import '../auth/auth_service.dart';
import '../../core/constants.dart';
import '../../models/user_model.dart';

class ChatListScreen extends ConsumerWidget {
  const ChatListScreen({super.key});

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

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(authServiceProvider).currentUser;

    if (currentUser == null) {
      return Scaffold(
        backgroundColor: const Color(0xFF0F0F1E),
        body: const Center(
          child: Text(
            'Please login to view chats',
            style: TextStyle(color: Colors.white),
          ),
        ),
      );
    }

    final conversationsStream =
        ref.watch(chatServiceProvider).getUserConversations(currentUser.uid);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Messages',
            style: GoogleFonts.outfit(fontWeight: FontWeight.bold)),
        backgroundColor: AppColors.background,
        elevation: 0,
      ),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: conversationsStream,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
                child: Text('Error loading messages',
                    style: GoogleFonts.outfit(color: AppColors.error)));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final conversations = snapshot.data!;

          if (conversations.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                        color: AppColors.surface, shape: BoxShape.circle),
                    child: const Icon(Icons.chat_bubble_outline_rounded,
                        size: 48, color: AppColors.textMuted),
                  ),
                  const SizedBox(height: 24),
                  Text('No conversations yet',
                      style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary)),
                  const SizedBox(height: 8),
                  Text('Connect with musicians to start jamming!',
                      style:
                          GoogleFonts.outfit(color: AppColors.textSecondary)),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: conversations.length,
            separatorBuilder: (context, index) =>
                Divider(color: Colors.white.withOpacity(0.05)),
            itemBuilder: (context, index) {
              final chat = conversations[index];
              final otherUser = chat['otherUser'];
              if (otherUser is! UserModel) {
                return const SizedBox.shrink();
              }

              final user = otherUser;
              final lastMessage = (chat['lastMessage'] as String?) ?? '';
              final timestamp = chat['timestamp'] as DateTime?;

              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.cardBackground,
                      AppColors.cardBackground.withOpacity(0.8),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColors.primary.withOpacity(0.1),
                    width: 1,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ListTile(
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  leading: Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primary.withOpacity(0.8),
                          AppColors.primary,
                        ],
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
                      child: user.photoUrl != null
                          ? Image.network(
                              user.photoUrl!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) =>
                                  Center(
                                child: Text(
                                  user.displayName.isNotEmpty
                                      ? user.displayName[0].toUpperCase()
                                      : '?',
                                  style: GoogleFonts.outfit(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    fontSize: 18,
                                  ),
                                ),
                              ),
                            )
                          : Center(
                              child: Text(
                                user.displayName.isNotEmpty
                                    ? user.displayName[0].toUpperCase()
                                    : '?',
                                style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  fontSize: 18,
                                ),
                              ),
                            ),
                  ),
                  ),
                  title: Text(
                    user.displayName,
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                      fontSize: 16,
                    ),
                  ),
                  subtitle: Text(
                    lastMessage,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.outfit(
                      color: Colors.white.withOpacity(0.7),
                      fontSize: 14,
                    ),
                  ),
                  trailing: Text(
                    _formatMessageTime(timestamp ?? DateTime.now()),
                    style: GoogleFonts.outfit(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 12,
                    ),
                  ),
                  onTap: () {
                    context.push('/chat-detail/${chat['chatId']}', extra: user);
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}
