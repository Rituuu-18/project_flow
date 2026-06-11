import 'package:hive/hive.dart';
import '../../../../core/database/hive_models.dart';
import '../../../../core/database/hive_service.dart';
import '../../domain/entities/design_review.dart';
import '../../domain/repositories/design_review_repository.dart';
import '../models/design_review_mapper.dart';

/// Hive-backed implementation of [DesignReviewRepository].
///
/// All reviews are stored in the 'design_reviews' Hive box, keyed by
/// [DesignReview.id]. The [watchReviews] stream re-emits whenever
/// the box changes, so any UI listening to the stream is always up to date.
class HiveDesignReviewRepository implements DesignReviewRepository {
  Box<DesignReviewHiveModel> get _box => HiveService.reviewsBox;

  // ── Read ────────────────────────────────────────────────────────────────

  @override
  Future<List<DesignReview>> getAllReviews() async {
    return _box.values.map((m) => m.toEntity()).toList();
  }

  @override
  Future<DesignReview?> getReviewById(String id) async {
    final model = _box.values.where((m) => m.uuid == id).firstOrNull;
    return model?.toEntity();
  }

  // ── Write ───────────────────────────────────────────────────────────────

  @override
  Future<void> saveReview(DesignReview review) async {
    final model = review.toHiveModel();
    await _box.put(review.id, model);
  }

  // ── Delete ──────────────────────────────────────────────────────────────

  @override
  Future<void> deleteReview(String id) async {
    await _box.delete(id);
  }

  // ── Stream ──────────────────────────────────────────────────────────────

  @override
  Stream<List<DesignReview>> watchReviews() async* {
    // Emit the initial list immediately…
    yield _box.values.map((m) => m.toEntity()).toList();
    // …then re-emit on every box change.
    await for (final _ in _box.watch()) {
      yield _box.values.map((m) => m.toEntity()).toList();
    }
  }
}
