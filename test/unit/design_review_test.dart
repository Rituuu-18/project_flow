import 'package:flutter_test/flutter_test.dart';
import 'package:engineering_werk/features/reviews/domain/entities/design_review.dart';
import 'package:engineering_werk/features/reviews/data/models/design_review_mapper.dart';
import 'package:engineering_werk/core/utils/enums.dart';

void main() {
  group('DesignReview Entity', () {
    final now = DateTime.now();
    final review = DesignReview(
      id: '1',
      name: 'Test Review',
      owner: 'John Doe',
      discipline: 'Mechanical',
      createdAt: now,
      lastUpdated: now,
    );

    test('should create DesignReview with correct values', () {
      expect(review.id, '1');
      expect(review.name, 'Test Review');
      expect(review.owner, 'John Doe');
      expect(review.discipline, 'Mechanical');
      expect(review.status, ProjectStatus.active);
      expect(review.createdAt, now);
      expect(review.lastUpdated, now);
    });

    test('copyWith should return a new instance with updated values', () {
      final updated = review.copyWith(name: 'Updated Name', status: ProjectStatus.completed);
      expect(updated.name, 'Updated Name');
      expect(updated.status, ProjectStatus.completed);
      expect(updated.id, '1'); // remains unchanged
    });

    test('Equality works correctly', () {
      final review2 = DesignReview(
        id: '1',
        name: 'Test Review',
        owner: 'John Doe',
        discipline: 'Mechanical',
        createdAt: now,
        lastUpdated: now,
      );
      expect(review, equals(review2));
    });
  });

  group('DesignReview Mapper', () {
    test('toHiveModel and toEntity should be consistent', () {
      final now = DateTime.now();
      final review = DesignReview(
        id: 'uuid-123',
        name: 'Pump Rev A',
        owner: 'Sunil',
        discipline: 'Hydraulics',
        status: ProjectStatus.reviewPending,
        createdAt: now,
        lastUpdated: now,
      );

      final hiveModel = review.toHiveModel();
      expect(hiveModel.uuid, 'uuid-123');
      expect(hiveModel.name, 'Pump Rev A');
      expect(hiveModel.statusIndex, ProjectStatus.reviewPending.index);

      final backToEntity = hiveModel.toEntity();
      expect(backToEntity, equals(review));
    });
  });
}
