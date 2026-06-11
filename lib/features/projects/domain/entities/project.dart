import 'package:equatable/equatable.dart';
import '../../../../core/utils/enums.dart';
import '../../../reviews/domain/entities/stage.dart';

class Project extends Equatable {
  final String id;
  final String name;
  final String description;
  final String owner;
  final String discipline;
  final String? imageUrl;
  final double progress;
  final ProjectStatus status;
  final DateTime lastUpdated;
  final List<Stage> stages;

  const Project({
    required this.id,
    required this.name,
    this.description = '',
    this.owner = '',
    this.discipline = '',
    this.imageUrl,
    this.progress = 0.0,
    this.status = ProjectStatus.active,
    required this.lastUpdated,
    this.stages = const [],
  });

  @override
  List<Object?> get props => [id, name, description, owner, discipline, imageUrl, progress, status, lastUpdated, stages];

  Project copyWith({
    String? id,
    String? name,
    String? description,
    String? owner,
    String? discipline,
    String? imageUrl,
    double? progress,
    ProjectStatus? status,
    DateTime? lastUpdated,
    List<Stage>? stages,
  }) {
    return Project(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      owner: owner ?? this.owner,
      discipline: discipline ?? this.discipline,
      imageUrl: imageUrl ?? this.imageUrl,
      progress: progress ?? this.progress,
      status: status ?? this.status,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      stages: stages ?? this.stages,
    );
  }
}
