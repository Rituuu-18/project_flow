import 'package:hive/hive.dart';
import '../../../../core/database/hive_models.dart';
import '../../../../core/database/hive_service.dart';
import '../../domain/entities/design_review.dart';
import '../../domain/repositories/design_review_repository.dart';
import '../../domain/utils/default_stages.dart';
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
    return _loadAndUpgradeReviews();
  }

  @override
  Future<DesignReview?> getReviewById(String id) async {
    final model = _box.values.where((m) => m.uuid == id).firstOrNull;
    if (model == null) return null;
    final review = model.toEntity();
    final upgraded = _upgradeReview(review);
    if (upgraded != review) {
      await _box.put(upgraded.id, upgraded.toHiveModel());
    }
    return upgraded;
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
    yield await _loadAndUpgradeReviews();
    await for (final _ in _box.watch()) {
      yield await _loadAndUpgradeReviews();
    }
  }

  Future<List<DesignReview>> _loadAndUpgradeReviews() async {
    final reviews = _box.values.map((model) => model.toEntity()).toList();
    final upgradedReviews = <DesignReview>[];

    for (final review in reviews) {
      final upgraded = _upgradeReview(review);
      upgradedReviews.add(upgraded);
      if (upgraded != review) {
        await _box.put(upgraded.id, upgraded.toHiveModel());
      }
    }

    return upgradedReviews;
  }

  DesignReview _upgradeReview(DesignReview review) {
    final upgradedStages = upgradeLegacyDefaultStages(review.stages);
    return identical(upgradedStages, review.stages)
        ? review
        : review.copyWith(stages: upgradedStages);
  }
}
