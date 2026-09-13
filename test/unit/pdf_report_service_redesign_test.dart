import 'dart:typed_data';

import 'package:engineering_werk/core/utils/enums.dart';
import 'package:engineering_werk/features/workspace/domain/entities/comment.dart';
import 'package:engineering_werk/features/reviews/domain/entities/design_review.dart';
import 'package:engineering_werk/features/reviews/domain/entities/stage.dart';
import 'package:engineering_werk/features/reviews/domain/entities/stakeholder.dart';
import 'package:engineering_werk/features/reviews/domain/entities/sub_step.dart';
import 'package:engineering_werk/features/workspace/domain/entities/workspace_data.dart';
import 'package:engineering_werk/services/pdf_report_service.dart';
import 'package:engineering_werk/services/project_pdf_data.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PdfReportService Redesign Tests', () {
    final transparentPixel = Uint8List.fromList([
      0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D,
      0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
      0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00,
      0x0A, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
      0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49,
      0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
    ]);

    test('generateReport renders full 10-stage review with rich AI notes, evidence, and actions', () async {
      final now = DateTime.now();

      final stageNames = [
        'Requirements',
        'Concept',
        'Preliminary Design',
        'Detailed Design',
        'Simulation (FEA, CFD...)',
        'Prototype',
        'Testing Validation',
        'Manufacturing Readiness',
        'Final Release',
        'Continuous Improvement',
      ];

      final stages = <Stage>[];
      final workspaces = <WorkspaceData>[];
      final workspaceImages = <String, Uint8List>{};
      final workspaceAttachmentUrls = <String, String>{};

      for (int s = 0; s < stageNames.length; s++) {
        final stageName = stageNames[s];
        final subSteps = <SubStep>[
          SubStep(
            id: 'sub-$s-1',
            name: 'Define the problem and scope',
            status: StageStatus.completed,
            workspaceId: 'ws-$s-1',
          ),
          SubStep(
            id: 'sub-$s-2',
            name: 'Identify stakeholders and interfaces',
            status: StageStatus.inProgress,
            workspaceId: 'ws-$s-2',
          ),
          SubStep(
            id: 'sub-$s-3',
            name: 'Empty and Unworked SubStep',
            status: StageStatus.notStarted,
            workspaceId: 'ws-$s-3',
          ),
        ];

        stages.add(
          Stage(
            id: 'stage-$s',
            name: stageName,
            lastUpdated: now,
            subSteps: subSteps,
          ),
        );

        // ws-1 has rich AI notes, engineering comments, and discussions
        workspaces.add(
          WorkspaceData(
            id: 'ws-$s-1',
            checklistItem: 'Define the problem and scope',
            notes: '''### Executive AI Summary
* Operational constraints verified against standard EN 9100.
* Peak thermal load calculated at 85 deg C with margin of 15%.
* Safety factor = 2.45 based on structural simulations.

### Next Action Directives
1. Submit signoff request to Systems Engineering lead.
2. Archive simulation mesh files in repository.''',
            engineeringComments: 'Validated by senior technical review committee.',
            comments: [
              Comment(
                id: 'c-1',
                author: 'Sarah Chen',
                content: 'All baseline parameters matched spec sheet rev 3.',
                createdAt: now,
              ),
            ],
            attachments: [
              'storage:attachments:workspace/ws-1/FEA_Stress_Analysis.pdf',
              'storage:attachments:workspace/ws-1/Gearbox_Housing.step',
              'storage:attachments:workspace/ws-1/Load_Schedule.xlsx',
            ],
            images: [
              'storage:attachments:workspace/ws-1/Von_Mises_Stress.png',
            ],
            actionDescription: 'Conduct cross-disciplinary verification meeting before freeze.',
            priority: 'High',
            assignee: 'Sarah Chen',
            discipline: 'Systems Engineering',
            dueDate: now.add(const Duration(days: 7)),
            approvalStatus: ApprovalStatus.approved,
          ),
        );

        // ws-2 has in-progress action item and single attachment
        workspaces.add(
          WorkspaceData(
            id: 'ws-$s-2',
            checklistItem: 'Identify stakeholders and interfaces',
            notes: 'Interface control document updated for electrical subsystems.',
            actionDescription: 'Route ICD to Electrical Team for connector approval.',
            priority: 'Medium',
            assignee: 'Marcus Vance',
            discipline: 'Electrical',
            dueDate: now.add(const Duration(days: 14)),
          ),
        );

        // ws-3 is completely empty
        workspaces.add(
          WorkspaceData(
            id: 'ws-$s-3',
            checklistItem: 'Empty and Unworked SubStep',
          ),
        );

        // Register evidence
        workspaceImages['storage:attachments:workspace/ws-1/Von_Mises_Stress.png'] = transparentPixel;
        workspaceAttachmentUrls['storage:attachments:workspace/ws-1/FEA_Stress_Analysis.pdf'] =
            'https://example.supabase.co/storage/FEA_Stress_Analysis.pdf';
        workspaceAttachmentUrls['storage:attachments:workspace/ws-1/Gearbox_Housing.step'] =
            'https://example.supabase.co/storage/Gearbox_Housing.step';
        workspaceAttachmentUrls['storage:attachments:workspace/ws-1/Load_Schedule.xlsx'] =
            'https://example.supabase.co/storage/Load_Schedule.xlsx';
        workspaceAttachmentUrls['storage:attachments:workspace/ws-1/Von_Mises_Stress.png'] =
            'https://example.supabase.co/storage/Von_Mises_Stress.png';
      }

      final review = DesignReview(
        id: 'proj-full',
        name: 'Aerospace Propulsion Test Bed',
        owner: 'Dr. Elena Rostova',
        discipline: 'Mechanical & Propulsion',
        createdAt: now,
        lastUpdated: now,
        stakeholders: const [
          Stakeholder(id: 'st-1', name: 'Dr. Elena Rostova', role: 'Mechanical & Propulsion'),
          Stakeholder(id: 'st-2', name: 'Sarah Chen', role: 'Systems Engineering'),
          Stakeholder(id: 'st-3', name: 'Marcus Vance', role: 'Electrical'),
        ],
        stages: stages,
      );

      final pdfData = ProjectPdfData(
        review: review,
        workspaces: workspaces,
        logoBytes: transparentPixel,
        projectImageBytes: transparentPixel,
        workspaceImages: workspaceImages,
        workspaceAttachmentUrls: workspaceAttachmentUrls,
      );

      final pdfBytes = await PdfReportService.generateReport(pdfData);
      expect(pdfBytes, isNotNull);
      expect(pdfBytes.length, greaterThan(1000));
    });

    test('generateReport handles completely empty project without crashing', () async {
      final now = DateTime.now();
      final review = DesignReview(
        id: 'proj-empty',
        name: 'Empty Minimal Project',
        owner: 'Solo Engineer',
        discipline: 'Software',
        createdAt: now,
        lastUpdated: now,
        stakeholders: const [],
        stages: const [],
      );

      final pdfData = ProjectPdfData(
        review: review,
        workspaces: const [],
        logoBytes: transparentPixel,
        workspaceImages: const {},
        workspaceAttachmentUrls: const {},
      );

      final pdfBytes = await PdfReportService.generateReport(pdfData);
      expect(pdfBytes, isNotNull);
      expect(pdfBytes.length, greaterThan(100));
    });
  });
}
