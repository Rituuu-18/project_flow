import 'package:engineering_werk/features/workspace/domain/entities/workspace_data.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('copyWith clearDueDate nulls dueDate', () {
    final data = WorkspaceData(
      id: 'ws-1',
      dueDate: DateTime(2026, 7, 20),
    );
    final cleared = data.copyWith(clearDueDate: true);
    expect(cleared.dueDate, isNull);
    expect(data.copyWith(dueDate: DateTime(2026, 8, 1)).dueDate,
        DateTime(2026, 8, 1));
  });
}
