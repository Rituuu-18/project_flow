import 'package:flutter_test/flutter_test.dart';
import 'package:engineering_werk/features/projects/domain/entities/project.dart';
import 'package:engineering_werk/core/utils/enums.dart';

void main() {
  group('Project Entity', () {
    test('should create a Project with default values', () {
      final now = DateTime.now();
      final project = Project(
        id: '1',
        name: 'Test Project',
        lastUpdated: now,
      );

      expect(project.id, '1');
      expect(project.name, 'Test Project');
      expect(project.progress, 0.0);
      expect(project.status, ProjectStatus.active);
      expect(project.lastUpdated, now);
      expect(project.stages, isEmpty);
    });

    test('copyWith should update specified fields', () {
      final now = DateTime.now();
      final project = Project(
        id: '1',
        name: 'Test Project',
        lastUpdated: now,
      );

      final updated = project.copyWith(name: 'Updated Name', progress: 0.5);

      expect(updated.name, 'Updated Name');
      expect(updated.progress, 0.5);
      expect(updated.id, '1'); // Unchanged
    });
  });
}
