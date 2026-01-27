import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'chat_service.dart';
import '../auth/auth_service.dart';
import '../../core/constants.dart';
import '../../models/user_model.dart';

class ChatListScreen extends ConsumerWidget {
  const ChatListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentUser = ref.watch(authServiceProvider).currentUser;

    if (currentUser == null) {
      return Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
            title: Text('Messages',
                style: GoogleFonts.outfit(fontWeight: FontWeight.bold))),
        body: Center(
            child: Text('Please log in to see messages',
                style: GoogleFonts.outfit(color: AppColors.textSecondary))),
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

              return ListTile(
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                leading: Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.surface,
                    border: Border.all(color: Colors.white.withOpacity(0.05)),
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
                                  color: AppColors.primary,
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
                                color: AppColors.primary,
                                fontSize: 18,
                              ),
                            ),
                          ),
                  ),
                ),
                title: Text(user.displayName,
                    style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                        fontSize: 16)),
                subtitle: Text(
                  lastMessage,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.outfit(
                      color: AppColors.textSecondary, fontSize: 14),
                ),
                trailing: Text(
                  timeago.format(timestamp ?? DateTime.now(), locale: 'en_short'),
                  style: GoogleFonts.outfit(
                      color: AppColors.textMuted, fontSize: 12),
                ),
                onTap: () {
                  context.push('/chat-detail/${chat['chatId']}', extra: user);
                },
              );
            },
          );
        },
      ),
    );
  }
}
