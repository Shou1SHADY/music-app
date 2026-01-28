import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService(FirebaseFirestore.instance);
});

class NotificationService {
  final FirebaseFirestore _firestore;
  final Uuid _uuid = const Uuid();

  NotificationService(this._firestore);

  Future<void> sendBookingConfirmation({
    required String userId,
    required String studioId,
    required String studioName,
    required DateTime startTime,
    required DateTime endTime,
    required double totalPrice,
  }) async {
    final notification = {
      'id': _uuid.v4(),
      'userId': userId,
      'type': 'booking_confirmation',
      'title': 'Booking Confirmed!',
      'body': 'Your booking at $studioName has been confirmed for ${_formatDate(startTime)}.',
      'data': {
        'studioId': studioId,
        'studioName': studioName,
        'startTime': startTime.toIso8601String(),
        'endTime': endTime.toIso8601String(),
        'totalPrice': totalPrice,
      },
      'isRead': false,
      'createdAt': Timestamp.now(),
    };

    await _firestore
        .collection('notifications')
        .doc(notification['id'] as String)
        .set(notification);
  }

  Future<void> sendBookingRequest({
    required String studioOwnerId,
    required String userId,
    required String userName,
    required String studioName,
    required DateTime startTime,
    required DateTime endTime,
  }) async {
    final notification = {
      'id': _uuid.v4(),
      'userId': studioOwnerId,
      'type': 'booking_request',
      'title': 'New Booking Request',
      'body': '$userName wants to book $studioName on ${_formatDate(startTime)}.',
      'data': {
        'requesterUserId': userId,
        'requesterName': userName,
        'studioName': studioName,
        'startTime': startTime.toIso8601String(),
        'endTime': endTime.toIso8601String(),
      },
      'isRead': false,
      'createdAt': Timestamp.now(),
    };

    await _firestore
        .collection('notifications')
        .doc(notification['id'] as String)
        .set(notification);
  }

  Future<void> sendBookingReminder({
    required String userId,
    required String studioName,
    required DateTime startTime,
  }) async {
    final notification = {
      'id': _uuid.v4(),
      'userId': userId,
      'type': 'booking_reminder',
      'title': 'Booking Reminder',
      'body': 'Don\'t forget your booking at $studioName tomorrow at ${_formatTime(startTime)}!',
      'data': {
        'studioName': studioName,
        'startTime': startTime.toIso8601String(),
      },
      'isRead': false,
      'createdAt': Timestamp.now(),
    };

    await _firestore
        .collection('notifications')
        .doc(notification['id'] as String)
        .set(notification);
  }

  Stream<List<Map<String, dynamic>>> getUserNotifications(String userId) {
    return _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.data()).toList());
  }

  Future<void> markNotificationAsRead(String notificationId) async {
    await _firestore
        .collection('notifications')
        .doc(notificationId)
        .update({'isRead': true});
  }

  Future<void> markAllNotificationsAsRead(String userId) async {
    final notifications = await _firestore
        .collection('notifications')
        .where('userId', isEqualTo: userId)
        .where('isRead', isEqualTo: false)
        .get();

    for (final doc in notifications.docs) {
      await doc.reference.update({'isRead': true});
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} at ${_formatTime(date)}';
  }

  String _formatTime(DateTime date) {
    final hour = date.hour.toString().padLeft(2, '0');
    final minute = date.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }
}
