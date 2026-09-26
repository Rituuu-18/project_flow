enum ProjectStatus { active, reviewPending, completed }

enum StageStatus { notStarted, inProgress, completed, notRequired }

extension StageStatusExtension on StageStatus {
  String get jsonValue {
    switch (this) {
      case StageStatus.notStarted: return 'Open';
      case StageStatus.inProgress: return 'In Progress';
      case StageStatus.completed: return 'Completed';
      case StageStatus.notRequired: return 'Not Required';
    }
  }

  static StageStatus fromJson(String value) {
    switch (value) {
      case 'Open': return StageStatus.notStarted;
      case 'In Progress': return StageStatus.inProgress;
      case 'Completed': return StageStatus.completed;
      case 'Not Required': return StageStatus.notRequired;
      default: return StageStatus.notStarted;
    }
  }
}

enum ApprovalStatus { pending, approved, rejected }
