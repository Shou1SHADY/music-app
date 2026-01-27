import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/message_model.dart';
import '../../models/user_model.dart';
import '../../services/firestore_service.dart'; // Reuse for getting user details
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

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final participants = List<String>.from(data['participants']);
        final otherUserId =
            participants.firstWhere((id) => id != currentUserId);

        final otherUserDoc =
            await _firestore.collection('users').doc(otherUserId).get();
        final otherUser = otherUserDoc.exists
            ? UserModel.fromJson(otherUserDoc.data()!)
            : null;

        if (otherUser != null) {
          conversations.add({
            'chatId': doc.id,
            'otherUser': otherUser,
            'lastMessage': data['lastMessage'] ?? '',
            'timestamp':
                (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
          });
        }
      }

      // Sort client-side by timestamp descending
      conversations.sort((a, b) =>
          (b['timestamp'] as DateTime).compareTo(a['timestamp'] as DateTime));

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

  Future<void> sendMessage(String chatId, String senderId, String text) async {
    final message = MessageModel(
      id: _uuid.v4(),
      senderId: senderId,
      receiverId:
          '', // Ideally we need this if we don't have chatId, but with chatId it's implied
      content: text,
      timestamp: DateTime.now(),
      isRead: false,
    );

    // Ensure chatId exists or create it?
    // For MVP, we assume we find/create chat before sending.

    try {
      final batch = _firestore.batch();

      final chatRef = _firestore.collection('chats').doc(chatId);
      final messageRef = chatRef.collection('messages').doc(message.id);

      batch.set(messageRef, message.toJson());
      batch.update(chatRef, {
        'lastMessage': text,
        'timestamp': FieldValue.serverTimestamp(),
      });

      await batch.commit();
    } catch (e) {
      print("Firestore error in sendMessage: $e. Saving to mock memory.");
      _mockMessages[chatId] = [message, ...(_mockMessages[chatId] ?? [])];
      if (_mockChats.containsKey(chatId)) {
        _mockChats[chatId]!['lastMessage'] = text;
        _mockChats[chatId]!['timestamp'] = DateTime.now();
      }
    }
  }

  Future<String> createOrGetChat(
      String currentUserId, String otherUserId) async {
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
}
