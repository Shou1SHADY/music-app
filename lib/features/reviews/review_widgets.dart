import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/constants.dart';
import '../../models/review_model.dart';
import 'review_service.dart';

// --- Review List Widget ---

class ReviewList extends ConsumerWidget {
  final String studioId;

  const ReviewList({super.key, required this.studioId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reviewsAsync = ref.watch(studioReviewsProvider(studioId));

    return reviewsAsync.when(
      data: (reviews) {
        if (reviews.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24.0),
              child: Text(
                'No reviews yet. Be the first to review!',
                style: GoogleFonts.outfit(color: AppColors.textSecondary),
              ),
            ),
          );
        }

        return ListView.builder(
          physics:
              const NeverScrollableScrollPhysics(), // Nested inside other scroll view
          shrinkWrap: true,
          itemCount: reviews.length,
          padding: EdgeInsets.zero,
          itemBuilder: (context, index) {
            final review = reviews[index];
            return classReviewCard(review);
          },
        );
      },
      loading: () => const Center(
          child: Padding(
        padding: EdgeInsets.all(16.0),
        child: CircularProgressIndicator(),
      )),
      error: (e, _) => Text('Error loading reviews: $e',
          style: const TextStyle(color: AppColors.error)),
    );
  }

  Widget classReviewCard(ReviewModel review) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.cardBackground,
                  border: Border.all(color: Colors.white.withOpacity(0.05)),
                ),
                child: ClipOval(
                  child: review.userPhotoUrl != null
                      ? Image.network(
                          review.userPhotoUrl!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              const Icon(Icons.person,
                                  size: 16, color: AppColors.textSecondary),
                        )
                      : const Icon(Icons.person,
                          size: 16, color: AppColors.textSecondary),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.userName,
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      DateFormat.yMMMd().format(review.createdAt),
                      style: GoogleFonts.outfit(
                        color: AppColors.textMuted,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.accent.withOpacity(0.2)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.star_rounded,
                        size: 14, color: AppColors.accent),
                    const SizedBox(width: 4),
                    Text(
                      review.rating.toStringAsFixed(1),
                      style: GoogleFonts.outfit(
                        fontWeight: FontWeight.bold,
                        color: AppColors.textPrimary,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (review.comment.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              review.comment,
              style: GoogleFonts.outfit(
                color: AppColors.textSecondary,
                fontSize: 14,
                height: 1.5,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

final studioReviewsProvider =
    StreamProvider.family<List<ReviewModel>, String>((ref, studioId) {
  return ref.watch(reviewServiceProvider).getStudioReviews(studioId);
});

// --- Write Review Sheet ---

class WriteReviewSheet extends ConsumerStatefulWidget {
  final String studioId;

  const WriteReviewSheet({super.key, required this.studioId});

  @override
  ConsumerState<WriteReviewSheet> createState() => _WriteReviewSheetState();
}

class _WriteReviewSheetState extends ConsumerState<WriteReviewSheet> {
  double _rating = 0;
  final TextEditingController _commentController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _submitReview() async {
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a rating')),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await ref.read(reviewServiceProvider).submitReview(
            studioId: widget.studioId,
            rating: _rating,
            comment: _commentController.text.trim(),
          );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Review submitted successfully!'),
              backgroundColor: AppColors.success),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('Error: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
          24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
      decoration: const BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Write a Review',
            style: GoogleFonts.outfit(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 24),
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(5, (index) {
                return IconButton(
                  onPressed: () => setState(() => _rating = index + 1.0),
                  icon: Icon(
                    index < _rating
                        ? Icons.star_rounded
                        : Icons.star_outline_rounded,
                    color: AppColors.accent,
                    size: 40,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                );
              }),
            ),
          ),
          const SizedBox(height: 24),
          TextField(
            controller: _commentController,
            maxLines: 4,
            style: GoogleFonts.outfit(color: Colors.white),
            decoration: InputDecoration(
              hintText: 'Share your experience with this studio...',
              hintStyle: GoogleFonts.outfit(color: AppColors.textMuted),
              filled: true,
              fillColor: AppColors.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: _isLoading ? null : _submitReview,
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: AppColors.background,
              minimumSize: const Size(double.infinity, 56),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
            ),
            child: _isLoading
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                        color: AppColors.background, strokeWidth: 2))
                : Text('Submit Review',
                    style: GoogleFonts.outfit(
                        fontSize: 16, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
