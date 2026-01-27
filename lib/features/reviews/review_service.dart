import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../models/review_model.dart';
import '../../models/user_model.dart';
import '../../services/firestore_service.dart';
import '../auth/auth_service.dart';

final reviewServiceProvider = Provider<ReviewService>((ref) {
  return ReviewService(FirebaseFirestore.instance, ref);
});

class ReviewService {
  final FirebaseFirestore _firestore;
  final Ref _ref;
  final Uuid _uuid = const Uuid();

  ReviewService(this._firestore, this._ref);

  // Get reviews for a studio
  Stream<List<ReviewModel>> getStudioReviews(String studioId) {
    return _firestore
        .collection('reviews')
        .where('studioId', isEqualTo: studioId)
        .snapshots()
        .map((snapshot) {
      final reviews =
          snapshot.docs.map((doc) => ReviewModel.fromJson(doc.data())).toList();
      // Sort client-side descending by creation date
      reviews.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return reviews;
    });
  }

  // Get average rating for a studio
  Future<Map<String, dynamic>> getStudioRatingStats(String studioId) async {
    final reviews = await _firestore
        .collection('reviews')
        .where('studioId', isEqualTo: studioId)
        .get();

    if (reviews.docs.isEmpty) {
      return {'average': 0.0, 'count': 0};
    }

    double total = 0;
    for (var doc in reviews.docs) {
      total += (doc.data()['rating'] as num).toDouble();
    }

    return {
      'average': total / reviews.docs.length,
      'count': reviews.docs.length,
    };
  }

  // Check if user has already reviewed this studio
  Future<bool> hasUserReviewed(String studioId, String userId) async {
    final review = await _firestore
        .collection('reviews')
        .where('studioId', isEqualTo: studioId)
        .where('userId', isEqualTo: userId)
        .limit(1)
        .get();

    return review.docs.isNotEmpty;
  }

  // Submit a review
  Future<void> submitReview({
    required String studioId,
    required double rating,
    required String comment,
  }) async {
    final user = _ref.read(authServiceProvider).currentUser;
    if (user == null) throw Exception('User must be logged in to review');

    // Get user profile for name and photo
    final userProfile =
        await _ref.read(firestoreServiceProvider).getUserProfile(user.uid);
    if (userProfile == null) throw Exception('User profile not found');

    // Check if user already reviewed
    final hasReviewed = await hasUserReviewed(studioId, user.uid);
    if (hasReviewed) throw Exception('You have already reviewed this studio');

    final review = ReviewModel(
      id: _uuid.v4(),
      studioId: studioId,
      userId: user.uid,
      userName: userProfile.displayName,
      userPhotoUrl: userProfile.photoUrl,
      rating: rating,
      comment: comment,
      createdAt: DateTime.now(),
    );

    // Save review
    await _firestore.collection('reviews').doc(review.id).set(review.toJson());

    // Update studio rating
    await _updateStudioRating(studioId);
  }

  // Update studio's average rating
  Future<void> _updateStudioRating(String studioId) async {
    final stats = await getStudioRatingStats(studioId);

    await _firestore.collection('studios').doc(studioId).update({
      'rating': stats['average'],
      'reviewCount': stats['count'],
    });
  }

  // Delete a review (only by the author)
  Future<void> deleteReview(String reviewId, String studioId) async {
    final user = _ref.read(authServiceProvider).currentUser;
    if (user == null) throw Exception('User must be logged in');

    final reviewDoc =
        await _firestore.collection('reviews').doc(reviewId).get();
    if (!reviewDoc.exists) throw Exception('Review not found');

    if (reviewDoc.data()?['userId'] != user.uid) {
      throw Exception('You can only delete your own reviews');
    }

    await _firestore.collection('reviews').doc(reviewId).delete();
    await _updateStudioRating(studioId);
  }
}
