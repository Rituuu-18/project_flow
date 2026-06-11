import 'package:hive_flutter/hive_flutter.dart';
import 'hive_models.dart';

class HiveService {
  static const String projectsBoxName   = 'projects';
  static const String workspaceBoxName  = 'workspaces';
  static const String reviewsBoxName    = 'design_reviews';

  static Future<void> init() async {
    await Hive.initFlutter();

    // Register adapters
    Hive.registerAdapter(DesignReviewHiveModelAdapter());
    Hive.registerAdapter(StakeholderHiveModelAdapter());
    Hive.registerAdapter(ProjectHiveModelAdapter());
    Hive.registerAdapter(StageHiveModelAdapter());
    Hive.registerAdapter(SubStepHiveModelAdapter());
    Hive.registerAdapter(WorkspaceDataHiveModelAdapter());
    Hive.registerAdapter(CommentHiveModelAdapter());

    // Open boxes
    await Hive.openBox<DesignReviewHiveModel>(reviewsBoxName);
    await Hive.openBox<ProjectHiveModel>(projectsBoxName);
    await Hive.openBox<WorkspaceDataHiveModel>(workspaceBoxName);
  }

  static Box<ProjectHiveModel>      get projectsBox => Hive.box<ProjectHiveModel>(projectsBoxName);
  static Box<WorkspaceDataHiveModel> get workspaceBox => Hive.box<WorkspaceDataHiveModel>(workspaceBoxName);
  static Box<DesignReviewHiveModel>  get reviewsBox  => Hive.box<DesignReviewHiveModel>(reviewsBoxName);
}
