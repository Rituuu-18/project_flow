import 'package:equatable/equatable.dart';
import '../../../../core/utils/enums.dart';
import 'sub_step.dart';

class Stage extends Equatable {
  final String id;
  final String name;
  final StageStatus status;
  final double progress;
  final DateTime lastUpdated;
  final List<SubStep> subSteps;

  const Stage({
    required this.id,
    required this.name,
    this.status = StageStatus.notStarted,
    this.progress = 0.0,
    required this.lastUpdated,
    this.subSteps = const [],
  });

  @override
  List<Object?> get props => [id, name, status, progress, lastUpdated, subSteps];

  Stage copyWith({
    String? id,
    String? name,
    StageStatus? status,
    double? progress,
    DateTime? lastUpdated,
    List<SubStep>? subSteps,
  }) {
    return Stage(
      id: id ?? this.id,
      name: name ?? this.name,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      subSteps: subSteps ?? this.subSteps,
    );
  }
}
