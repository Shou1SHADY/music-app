import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../models/booking_model.dart';
import '../../models/studio_model.dart';
import '../../models/user_model.dart';
import '../../services/firestore_service.dart';
import '../auth/auth_service.dart';

final bookingServiceProvider = Provider<BookingService>((ref) {
  return BookingService(FirebaseFirestore.instance, ref);
});

class BookingService {
  final FirebaseFirestore _firestore;
  final Ref _ref;
  final Uuid _uuid = const Uuid();

  BookingService(this._firestore, this._ref);

  Future<void> createBooking(String studioId, String studioName,
      DateTime startTime, DateTime endTime, double pricePerHour) async {
    final user = _ref.read(authServiceProvider).currentUser;
    if (user == null) throw Exception('User must be logged in to book');

    // Get user details for name
    final userProfile =
        await _ref.read(firestoreServiceProvider).getUserProfile(user.uid);
    if (userProfile == null) throw Exception('User profile not found');

    final durationHours = endTime.difference(startTime).inMinutes / 60.0;
    final totalPrice = durationHours * pricePerHour;

    final booking = BookingModel(
      id: _uuid.v4(),
      studioId: studioId,
      userId: user.uid,
      studioName: studioName,
      userName: userProfile.displayName,
      startTime: startTime,
      endTime: endTime,
      totalPrice: totalPrice,
      status: BookingStatus.pending,
      createdAt: DateTime.now(),
    );

    await _firestore
        .collection('bookings')
        .doc(booking.id)
        .set(booking.toJson());
  }

  Stream<List<BookingModel>> getUserBookings(String userId) {
    return _firestore
        .collection('bookings')
        .where('userId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      final bookings = snapshot.docs
          .map((doc) => BookingModel.fromJson(doc.data()))
          .toList();
      // Sort client-side to avoid needing a composite index
      bookings.sort((a, b) => a.startTime.compareTo(b.startTime));
      return bookings;
    });
  }
}
