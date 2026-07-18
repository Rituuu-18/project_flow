import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/repositories/supabase_design_review_repository.dart';
import '../../domain/entities/design_review.dart';
import '../../domain/entities/stakeholder.dart';
import '../../domain/repositories/design_review_repository.dart';
import '../../domain/utils/default_stages.dart';

// ──────────────────────────────────────────────────────────────────────────
// Repository provider
// ──────────────────────────────────────────────────────────────────────────

/// Provides the concrete [DesignReviewRepository] backed by Hive.
final designReviewRepositoryProvider = Provider<DesignReviewRepository>((ref) {
  return SupabaseDesignReviewRepository(Supabase.instance.client);
});

// ──────────────────────────────────────────────────────────────────────────
// Stream provider  (dashboard list)
// ──────────────────────────────────────────────────────────────────────────

/// Streams the full list of [DesignReview]s.
final designReviewsStreamProvider = StreamProvider<List<DesignReview>>((ref) {
  final repository = ref.watch(designReviewRepositoryProvider);
  return repository.watchReviews();
});

// ──────────────────────────────────────────────────────────────────────────
// Notifier – create / update / delete helpers
// ──────────────────────────────────────────────────────────────────────────

class DesignReviewNotifier extends AsyncNotifier<List<DesignReview>> {
  DesignReviewRepository get _repo => ref.read(designReviewRepositoryProvider);

  @override
  Future<List<DesignReview>> build() {
    return _repo.getAllReviews();
  }

  /// Persists a new [review] and refreshes the state.
  /// Automatically adds default stages if the list is empty.
  Future<void> createReview(DesignReview review) async {
    DesignReview finalReview = review;
    if (review.stages.isEmpty) {
      finalReview = review.copyWith(stages: getDefaultStages());
    }
    await _repo.saveReview(finalReview);
    ref.invalidateSelf();
  }

  /// Updates an existing review (e.g. changing status) and refreshes state.
  Future<void> updateReview(DesignReview review) async {
    await _repo.saveReview(review);
    ref.invalidateSelf();
  }

  /// Adds a stakeholder to a review
  Future<void> addStakeholder(String reviewId, Stakeholder stakeholder) async {
    final reviews = await _repo.getAllReviews();
    final review = reviews.where((r) => r.id == reviewId).firstOrNull;
    if (review != null) {
      final updated = review.copyWith(
        stakeholders: [...review.stakeholders, stakeholder],
      );
      await updateReview(updated);
    }
  }

  /// Removes a review by [id] and refreshes state.
  Future<void> deleteReview(String id) async {
    await _repo.deleteReview(id);
    ref.invalidateSelf();
  }
}

final designReviewNotifierProvider =
    AsyncNotifierProvider<DesignReviewNotifier, List<DesignReview>>(
  DesignReviewNotifier.new,
);
