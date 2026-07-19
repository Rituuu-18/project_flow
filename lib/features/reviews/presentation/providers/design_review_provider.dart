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

/// Provides the concrete [DesignReviewRepository] backed by Supabase.
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

  void _refreshLists() {
    ref.invalidateSelf();
    ref.invalidate(designReviewsStreamProvider);
  }

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
    _refreshLists();
  }

  /// Updates an existing review (e.g. changing status) and refreshes state.
  Future<void> updateReview(DesignReview review) async {
    await _repo.saveReview(review);
    _refreshLists();
  }

  /// Adds a stakeholder to a review (targeted insert — does not rewrite stages).
  Future<void> addStakeholder(String reviewId, Stakeholder stakeholder) async {
    final name = stakeholder.name.trim();
    if (name.isEmpty) {
      throw Exception('Stakeholder name is required.');
    }
    final reviews = await _repo.getAllReviews();
    final review = reviews.where((r) => r.id == reviewId).firstOrNull;
    if (review != null) {
      final duplicate = review.stakeholders.any(
        (s) => s.name.trim().toLowerCase() == name.toLowerCase(),
      );
      if (duplicate) {
        throw Exception(
          'A stakeholder named "$name" already exists on this review.',
        );
      }
    }
    final normalized = stakeholder.copyWith(
      name: name,
      role: stakeholder.role.trim(),
    );
    await _repo.addStakeholder(reviewId, normalized);
    _refreshLists();
  }

  /// Updates only the card preview image.
  Future<void> updateImageUrl(String reviewId, String? imageUrl) async {
    await _repo.updateImageUrl(reviewId, imageUrl);
    _refreshLists();
  }

  /// Removes a review by [id] and refreshes state.
  Future<void> deleteReview(String id) async {
    await _repo.deleteReview(id);
    _refreshLists();
  }
}

final designReviewNotifierProvider =
    AsyncNotifierProvider<DesignReviewNotifier, List<DesignReview>>(
  DesignReviewNotifier.new,
);
