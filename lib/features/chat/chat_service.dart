import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/message_model.dart';
import '../../models/user_model.dart';
import '../../services/firestore_service.dart';
// import '../../services/push_notification_service.dart';
import 'package:uuid/uuid.dart';

final chatServiceProvider = Provider<ChatService>((ref) {
  return ChatService(FirebaseFirestore.instance, ref);
});

class ChatService {
  final FirebaseFirestore _firestore;
  final Ref _ref;
  final Uuid _uuid = const Uuid();

  // Mock storage for sessions without database
  static final Map<String, Map<String, dynamic>> _mockChats = {};
  static final Map<String, List<MessageModel>> _mockMessages = {};

  ChatService(this._firestore, this._ref);

  // Get list of users the current user has chatted with
  // Note: Optimally, we'd have a 'conversations' collection.
  // For simplicity MVP, we'll query unique sender/receiver IDs from messages.
  // Actually, let's create a 'conversations' sub-structure for scalability.

  /*
    Firestore Structure:
    chats/{chatId}
      - participants: [uid1, uid2]
      - lastMessage: "..."
      - timestamp: ...
      - messages/{messageId} (subcollection)
  */

  Stream<List<Map<String, dynamic>>> getUserConversations(
      String currentUserId) {
    return _firestore
        .collection('chats')
        .where('participants', arrayContains: currentUserId)
        .snapshots()
        .handleError((e) {
      print("Firestore error in getUserConversations: $e");
      return Stream.value([]);
    }).asyncMap((snapshot) async {
      final conversations = <Map<String, dynamic>>[];

      try {
        for (var doc in snapshot.docs) {
          try {
            final data = doc.data();
            
            // Validate required fields
            if (!data.containsKey('participants') || data['participants'] == null) {
              print("Skipping chat ${doc.id} - missing participants");
              continue;
            }
            
            final participants = List<String>.from(data['participants']);
            
            // Remove duplicates and filter out current user
            final uniqueParticipants = participants.toSet().toList();
            final otherParticipants = uniqueParticipants.where((id) => id != currentUserId).toList();
            
            if (otherParticipants.isEmpty) {
              print("Skipping chat ${doc.id} - no other participants found (self-chat or invalid)");
              continue;
            }
            
            final otherUserId = otherParticipants.first;

            final otherUserDoc =
                await _firestore.collection('users').doc(otherUserId).get();
            
            if (!otherUserDoc.exists) {
              print("Skipping chat ${doc.id} - other user not found: $otherUserId");
              continue;
            }
            
            final otherUserData = otherUserDoc.data();
            if (otherUserData == null) {
              print("Skipping chat ${doc.id} - other user data is null");
              continue;
            }
            
            final otherUser = UserModel.fromJson(otherUserData);

            conversations.add({
              'chatId': doc.id,
              'otherUser': otherUser,
              'lastMessage': data['lastMessage'] ?? '',
              'timestamp':
                  (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
            });
          } catch (e) {
            print("Error processing chat ${doc.id}: $e");
            continue;
          }
        }
      } catch (e) {
        print("Error in getUserConversations asyncMap: $e");
      }

      // Sort client-side by timestamp descending
      conversations.sort((a, b) =>
          (b['timestamp'] as DateTime).compareTo(a['timestamp'] as DateTime));

      print("Found ${conversations.length} conversations for user $currentUserId");
      return conversations;
    });
  }

  Stream<List<MessageModel>> getMessages(String chatId) {
    return _firestore
        .collection('chats')
        .doc(chatId)
        .collection('messages')
        .snapshots()
        .map((snapshot) {
      final messages = snapshot.docs
          .map((doc) => MessageModel.fromJson(doc.data()))
          .toList();
      // Sort client-side descending
      messages.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return messages;
    }).handleError((e) {
      print("Firestore error in getMessages: $e. Using mock memory.");
      return Stream.value(_mockMessages[chatId] ?? []);
    });
  }

  Future<void> sendMessage(String chatId, String senderId, String text, {String? imageUrl}) async {
    final message = MessageModel(
      id: _uuid.v4(),
      senderId: senderId,
      receiverId: '', // This will be handled by the chat document structure
      content: text,
      timestamp: DateTime.now(),
      isRead: false,
      imageUrl: imageUrl,
    );

    try {
      final batch = _firestore.batch();

      final chatRef = _firestore.collection('chats').doc(chatId);
      final messageRef = chatRef.collection('messages').doc(message.id);

      // Create a display text for the last message
      String displayText = text;
      if (imageUrl != null) {
        // For images, show a more user-friendly message
        if (text.startsWith('[Image:') || text.startsWith('[Photo:')) {
          displayText = '📷 Image';
        }
      }

      batch.set(messageRef, message.toJson());
      batch.update(chatRef, {
        'lastMessage': displayText,
        'timestamp': FieldValue.serverTimestamp(),
      });

      await batch.commit();
    } catch (e) {
      print("Firestore error in sendMessage: $e. Saving to mock memory.");
      _mockMessages[chatId] = [message, ...(_mockMessages[chatId] ?? [])];
      if (_mockChats.containsKey(chatId)) {
        String displayText = text;
        if (imageUrl != null && (text.startsWith('[Image:') || text.startsWith('[Photo:'))) {
          displayText = '📷 Image';
        }
        _mockChats[chatId]!['lastMessage'] = displayText;
        _mockChats[chatId]!['timestamp'] = DateTime.now();
      }
    }
  }

  Future<String> createOrGetChat(
      String currentUserId, String otherUserId) async {
    // Prevent creating self-chats
    if (currentUserId == otherUserId) {
      throw ArgumentError("Cannot create chat with yourself");
    }

    // Check if chat exists
    // This is a bit complex in Firestore (querying arrays).
    // We'll do a simple check: participants contains currentUserId AND participants contains otherUserId
    // Firestore limitations make this tricky with single query.
    // Hack for MVP: ID = sort(uid1, uid2).join('_')

    final ids = [currentUserId, otherUserId]..sort();
    final chatId = ids.join('_');

    try {
      final chatDoc = await _firestore.collection('chats').doc(chatId).get();

      if (!chatDoc.exists) {
        await _firestore.collection('chats').doc(chatId).set({
          'participants': ids,
          'lastMessage': '',
          'timestamp': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      print("Firestore error in createOrGetChat: $e. Using mock memory.");
      if (!_mockChats.containsKey(chatId)) {
        _mockChats[chatId] = {
          'participants': ids,
          'lastMessage': '',
          'timestamp': DateTime.now(),
        };
      }
    }

    return chatId;
  }

  Future<void> markMessageAsRead(String chatId, String messageId) async {
    try {
      await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .doc(messageId)
          .update({'isRead': true});
    } catch (e) {
      print("Firestore error in markMessageAsRead: $e");
    }
  }

  Future<void> markAllMessagesAsRead(String chatId, String currentUserId) async {
    try {
      // Simplified approach - get all messages and filter client-side
      final messages = await _firestore
          .collection('chats')
          .doc(chatId)
          .collection('messages')
          .where('isRead', isEqualTo: false)
          .get();

      for (final doc in messages.docs) {
        final messageData = doc.data();
        final senderId = messageData['senderId'] as String?;
        if (senderId != null && senderId != currentUserId) {
          await doc.reference.update({'isRead': true});
        }
      }
    } catch (e) {
      print("Firestore error in markAllMessagesAsRead: $e");
    }
  }

  void listenForNewMessages(String currentUserId) {
    _firestore
        .collection('chats')
        .where('participants', arrayContains: currentUserId)
        .snapshots()
        .listen((snapshot) {
      for (final chatDoc in snapshot.docs) {
        _firestore
            .collection('chats')
            .doc(chatDoc.id)
            .collection('messages')
            .where('senderId', isNotEqualTo: currentUserId)
            .where('isRead', isEqualTo: false)
            .orderBy('timestamp', descending: true)
            .limit(1)
            .snapshots()
            .listen((messageSnapshot) {
          for (final messageDoc in messageSnapshot.docs) {
            final message = MessageModel.fromJson(messageDoc.data());
            _showNewMessageNotification(message, chatDoc.id);
          }
        });
      }
    });
  }

  void _showNewMessageNotification(MessageModel message, String chatId) {
    // Get sender details
    _firestore.collection('users').doc(message.senderId).get().then((userDoc) {
      if (userDoc.exists) {
        final user = UserModel.fromJson(userDoc.data()!);
        // TODO: Re-enable when push notifications are fixed
        // _ref.read(pushNotificationServiceProvider).showChatNotification(
        //   title: 'New message from ${user.displayName}',
        //   body: message.content,
        //   chatId: chatId,
        //   payload: 'chat_$chatId',
        // );
      }
    });
  }
}
