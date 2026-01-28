import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final presenceServiceProvider = Provider<PresenceService>((ref) {
  return PresenceService(FirebaseFirestore.instance);
});

class PresenceService {
  final FirebaseFirestore _firestore;

  PresenceService(this._firestore);

  Future<void> updateUserPresence(String userId, {bool isOnline = true}) async {
    await _firestore.collection('users').doc(userId).update({
      'lastSeen': Timestamp.now(),
      'isOnline': isOnline,
    });
  }

  Future<void> setUserOffline(String userId) async {
    await _firestore.collection('users').doc(userId).update({
      'lastSeen': Timestamp.now(),
      'isOnline': false,
    });
  }

  Stream<DocumentSnapshot> getUserPresenceStream(String userId) {
    return _firestore.collection('users').doc(userId).snapshots();
  }

  Future<bool> isUserOnline(String userId) async {
    final doc = await _firestore.collection('users').doc(userId).get();
    if (!doc.exists) return false;
    
    final data = doc.data() as Map<String, dynamic>?;
    if (data == null) return false;
    
    // Check if user is marked as online
    if (data['isOnline'] == true) {
      // Also check if lastSeen is recent (within 5 minutes)
      final lastSeen = (data['lastSeen'] as Timestamp?)?.toDate();
      if (lastSeen != null) {
        final now = DateTime.now();
        final difference = now.difference(lastSeen);
        return difference.inMinutes < 5;
      }
    }
    
    return false;
  }

  String formatLastSeen(DateTime? lastSeen) {
    if (lastSeen == null) return 'Unknown';
    
    final now = DateTime.now();
    final difference = now.difference(lastSeen);
    
    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${lastSeen.day}/${lastSeen.month}/${lastSeen.year}';
    }
  }
}
