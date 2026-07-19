import '../entities/design_review.dart';
import '../entities/stakeholder.dart';

/// Abstract repository for Design Review CRUD operations.
abstract class DesignReviewRepository {
  /// Returns all design reviews once.
  Future<List<DesignReview>> getAllReviews();

  /// Returns a single review by [id], or null if not found.
  Future<DesignReview?> getReviewById(String id);

  /// Persists [review] (insert or update by id).
  Future<void> saveReview(DesignReview review);

  /// Inserts one stakeholder for [reviewId] without rewriting the whole review.
  Future<void> addStakeholder(String reviewId, Stakeholder stakeholder);

  /// Updates only the preview image URL for [reviewId].
  Future<void> updateImageUrl(String reviewId, String? imageUrl);

  /// Removes the review with the given [id].
  Future<void> deleteReview(String id);

  /// Streams the updated list every time the underlying store changes.
  Stream<List<DesignReview>> watchReviews();
}
