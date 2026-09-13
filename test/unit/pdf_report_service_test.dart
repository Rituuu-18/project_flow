import 'dart:typed_data';

import 'package:engineering_werk/core/database/supabase_storage.dart';
import 'package:engineering_werk/features/reviews/domain/entities/design_review.dart';
import 'package:engineering_werk/features/reviews/domain/entities/stage.dart';
import 'package:engineering_werk/features/reviews/domain/entities/sub_step.dart';
import 'package:engineering_werk/features/workspace/domain/entities/workspace_data.dart';
import 'package:engineering_werk/services/pdf_report_service.dart';
import 'package:engineering_werk/services/project_pdf_data.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SupabaseStorage path and url resolution', () {
    test('attachmentDisplayName extracts clean filename', () {
      expect(
        SupabaseStorage.attachmentDisplayName(
          'storage:attachments:workspace/ws-1/12345678901234567890123456789012_Checklist.pdf',
        ),
        'Checklist.pdf',
      );
      expect(
        SupabaseStorage.attachmentDisplayName('workspace/ws-1/System_Diagram.png'),
        'System_Diagram.png',
      );
      expect(
        SupabaseStorage.attachmentDisplayName('Design_Drawing.dwg'),
        'Design_Drawing.dwg',
      );
    });

    test('attachmentObjectPath parses ref prefixes correctly', () {
      expect(
        SupabaseStorage.attachmentObjectPath(
          'storage:attachments:workspace/ws-1/file.pdf',
        ),
        'workspace/ws-1/file.pdf',
      );
      expect(
        SupabaseStorage.attachmentObjectPath('workspace/ws-1/file.pdf'),
        'workspace/ws-1/file.pdf',
      );
      expect(
        SupabaseStorage.attachmentObjectPath('file.pdf'),
        'file.pdf',
      );
    });
  });

  group('PdfReportService evidence section generation', () {
    test('generateReport completes successfully with evidence hyperlinks', () async {
      final transparentPixel = Uint8List.fromList([
        0x89, 0x50, 0x4E, 0x47, 0x0D, 0x0A, 0x1A, 0x0A, 0x00, 0x00, 0x00, 0x0D,
        0x49, 0x48, 0x44, 0x52, 0x00, 0x00, 0x00, 0x01, 0x00, 0x00, 0x00, 0x01,
        0x08, 0x06, 0x00, 0x00, 0x00, 0x1F, 0x15, 0xC4, 0x89, 0x00, 0x00, 0x00,
        0x0A, 0x49, 0x44, 0x41, 0x54, 0x78, 0x9C, 0x63, 0x00, 0x01, 0x00, 0x00,
        0x05, 0x00, 0x01, 0x0D, 0x0A, 0x2D, 0xB4, 0x00, 0x00, 0x00, 0x00, 0x49,
        0x45, 0x4E, 0x44, 0xAE, 0x42, 0x60, 0x82,
      ]);

      final now = DateTime.now();

      final review = DesignReview(
        id: 'proj-1',
        name: 'Test Project',
        owner: 'Lead Engineer',
        discipline: 'Mechanical',
        createdAt: now,
        lastUpdated: now,
        stages: [
          Stage(
            id: 'stage-1',
            name: 'Requirements',
            lastUpdated: now,
            subSteps: [
              const SubStep(
                id: 'sub-1',
                name: 'System Requirements',
                workspaceId: 'ws-1',
              ),
            ],
          ),
        ],
      );

      final workspace = WorkspaceData(
        id: 'ws-1',
        notes: 'Substep details',
        attachments: [
          'storage:attachments:workspace/ws-1/12345678901234567890123456789012_Checklist.pdf',
          'storage:attachments:workspace/ws-1/12345678901234567890123456789012_Design_Drawing.dwg',
          'missing_file.pdf',
        ],
        images: [
          'storage:attachments:workspace/ws-1/12345678901234567890123456789012_Diagram.png',
        ],
      );

      final pdfData = ProjectPdfData(
        review: review,
        workspaces: [workspace],
        logoBytes: transparentPixel,
        workspaceImages: {
          'storage:attachments:workspace/ws-1/12345678901234567890123456789012_Diagram.png':
              transparentPixel,
        },
        workspaceAttachmentUrls: {
          'storage:attachments:workspace/ws-1/12345678901234567890123456789012_Checklist.pdf':
              'https://example.supabase.co/storage/v1/object/sign/attachments/Checklist.pdf?token=123',
          'storage:attachments:workspace/ws-1/12345678901234567890123456789012_Design_Drawing.dwg':
              'https://example.supabase.co/storage/v1/object/sign/attachments/Design_Drawing.dwg?token=123',
          'storage:attachments:workspace/ws-1/12345678901234567890123456789012_Diagram.png':
              'https://example.supabase.co/storage/v1/object/sign/attachments/Diagram.png?token=123',
        },
      );

      final bytes = await PdfReportService.generateReport(pdfData);
      expect(bytes, isNotNull);
      expect(bytes.length, greaterThan(0));
    });
  });
}
