import 'package:equatable/equatable.dart';
import '../../../../core/utils/enums.dart';

class SubStep extends Equatable {
  final String id;
  final String name;
  final StageStatus status;
  final String workspaceId;

  const SubStep({
    required this.id,
    required this.name,
    this.status = StageStatus.notStarted,
    required this.workspaceId,
  });

  @override
  List<Object?> get props => [id, name, status, workspaceId];

  SubStep copyWith({
    String? id,
    String? name,
    StageStatus? status,
    String? workspaceId,
  }) {
    return SubStep(
      id: id ?? this.id,
      name: name ?? this.name,
      status: status ?? this.status,
      workspaceId: workspaceId ?? this.workspaceId,
    );
  }
}
