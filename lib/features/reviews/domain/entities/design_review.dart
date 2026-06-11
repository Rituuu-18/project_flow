import 'package:equatable/equatable.dart';
import '../../../../core/utils/enums.dart';
import 'stage.dart';
import 'stakeholder.dart';

/// Core domain entity for a Design Review.
class DesignReview extends Equatable {
  final String id;
  final String name;
  final String owner;
  final String discipline;
  final ProjectStatus status;
  final DateTime createdAt;
  final DateTime lastUpdated;
  final String? imageUrl;
  final List<Stage> stages;
  final List<Stakeholder> stakeholders;
  final double progress;

  const DesignReview({
    required this.id,
    required this.name,
    required this.owner,
    required this.discipline,
    this.status = ProjectStatus.active,
    required this.createdAt,
    required this.lastUpdated,
    this.imageUrl,
    this.stages = const [],
    this.stakeholders = const [],
    this.progress = 0.0,
  });

  @override
  List<Object?> get props => [
        id,
        name,
        owner,
        discipline,
        status,
        createdAt,
        lastUpdated,
        imageUrl,
        stages,
        stakeholders,
        progress,
      ];

  DesignReview copyWith({
    String? id,
    String? name,
    String? owner,
    String? discipline,
    ProjectStatus? status,
    DateTime? createdAt,
    DateTime? lastUpdated,
    String? imageUrl,
    List<Stage>? stages,
    List<Stakeholder>? stakeholders,
    double? progress,
  }) {
    return DesignReview(
      id: id ?? this.id,
      name: name ?? this.name,
      owner: owner ?? this.owner,
      discipline: discipline ?? this.discipline,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      imageUrl: imageUrl ?? this.imageUrl,
      stages: stages ?? this.stages,
      stakeholders: stakeholders ?? this.stakeholders,
      progress: progress ?? this.progress,
    );
  }
}
