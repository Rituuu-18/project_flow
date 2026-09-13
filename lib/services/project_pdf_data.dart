import 'dart:typed_data';

import '../features/reviews/domain/entities/design_review.dart';
import '../features/workspace/domain/entities/workspace_data.dart';

class ProjectPdfData {
  final DesignReview review;
  final List<WorkspaceData> workspaces;
  final Uint8List logoBytes;
  final Uint8List? projectImageBytes;
  final Map<String, Uint8List> workspaceImages;
  final Map<String, String> workspaceAttachmentUrls;

  ProjectPdfData({
    required this.review,
    required this.workspaces,
    required this.logoBytes,
    this.projectImageBytes,
    required this.workspaceImages,
    required this.workspaceAttachmentUrls,
  });
}
