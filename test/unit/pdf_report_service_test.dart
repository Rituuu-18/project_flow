import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:engineering_werk/core/database/supabase_storage.dart';
import 'package:engineering_werk/features/reviews/domain/entities/design_review.dart';
import 'package:engineering_werk/features/reviews/domain/entities/stage.dart';
import 'package:engineering_werk/features/reviews/domain/entities/sub_step.dart';
import 'package:engineering_werk/features/workspace/domain/entities/workspace_data.dart';
import 'package:engineering_werk/features/workspace/domain/entities/comment.dart';
import 'package:engineering_werk/features/workspace/domain/entities/engineering_report.dart';
import 'package:engineering_werk/services/pdf_report_service.dart';
import 'package:engineering_werk/services/project_pdf_data.dart';
import 'package:flutter_test/flutter_test.dart';

import '../fixtures/engineering_report_fixture.dart';

void main() {
  group('PdfReportService formatted analysis', () {
    final report = EngineeringReport.fromResponse(
      jsonEncode(engineeringReportFixture),
    );
    final notes = report.toNotesText();

    for (final field in ['notes', 'engineering comments', 'comment']) {
      test(
        'exports $field as headings and tables, without Markdown syntax',
        () async {
          final data = _paginationData(
            WorkspaceData(
              id: 'ws-long',
              notes: field == 'notes' ? notes : '',
              engineeringComments: field == 'engineering comments' ? notes : '',
              comments: field == 'comment'
                  ? [
                      Comment(
                        id: 'review-comment',
                        author: 'Reviewer',
                        content: notes,
                        createdAt: DateTime(2026, 10, 12),
                      ),
                    ]
                  : [],
            ),
          );
          final bytes = await PdfReportService.generateReport(data);
          final content = _pdfContent(bytes);
          expect(content, contains(report.title));
          for (final section in report.sections) {
            expect(content, contains(section.heading));
            for (final column in section.columns) {
              expect(content, contains(column));
            }
            for (final row in section.rows) {
              expect(content, contains(row.first));
            }
          }
          expect(content, isNot(contains('|')));
          expect(content, isNot(contains('---')));
          expect(content, isNot(contains('##')));

          final output = Platform.environment['PDF_TABLE_PREVIEW_OUTPUT'];
          if (field == 'notes' && output != null) {
            final sample = ProjectPdfData(
              review: data.review.copyWith(name: 'Woodchipper rotor design'),
              workspaces: data.workspaces,
              logoBytes: await File('assets/ed-logo.png').readAsBytes(),
              workspaceImages: data.workspaceImages,
              workspaceAttachmentUrls: data.workspaceAttachmentUrls,
            );
            await File(
              output,
            ).writeAsBytes(await PdfReportService.generateReport(sample));
          }
        },
      );
    }

    test('keeps every row and repeats table headers across pages', () async {
      final rows = List.generate(
        140,
        (i) =>
            '| CHECK${i}END | Verify the assembly and record the governing load case before release. | ACCEPT${i}END |',
      );
      final text =
          '# Load case register\n\n## Design verification\n\n'
          '| Check reference | Required evidence | Acceptance criterion |\n'
          '| --- | --- | --- |\n${rows.join('\n')}';
      final bytes = await PdfReportService.generateReport(
        _paginationData(WorkspaceData(id: 'ws-long', notes: text)),
      );
      final content = _pdfContent(bytes);
      for (var i = 0; i < rows.length; i++) {
        expect(
          content.contains('CHECK${i}END'),
          isTrue,
          reason: 'Missing row $i',
        );
        expect(
          content.contains('ACCEPT${i}END'),
          isTrue,
          reason: 'Missing acceptance $i',
        );
      }
      expect('Check reference'.allMatches(content).length, greaterThan(1));
    });

    test('exports a table spanning more than 20 pages', () async {
      final rows = List.generate(
        600,
        (i) =>
            '| REGISTER${i}END | Verify the governing load case, document the calculation assumptions, and record the supporting test evidence. | ACCEPT${i}END |',
      );
      final text =
          '| Check reference | Required evidence | Acceptance criterion |\n'
          '| --- | --- | --- |\n${rows.join('\n')}';
      final bytes = await PdfReportService.generateReport(
        _paginationData(WorkspaceData(id: 'ws-long', notes: text)),
      );
      final content = _pdfContent(bytes);
      expect(content, contains('REGISTER599END'));
      expect(content, contains('ACCEPT599END'));
      expect('Check reference'.allMatches(content).length, greaterThan(20));
    });

    test('splits a cell taller than a page into continuation rows', () async {
      final detail = List.generate(
        800,
        (i) => 'DETAIL${i}END confirm the load case.',
      ).join(' ');
      final text =
          '| Check | Evidence | Decision |\n| --- | --- | --- |\n'
          '| Tall cell | $detail | FINALDECISION |\n'
          '| NEXTROW | Finish review | DONE |';
      final bytes = await PdfReportService.generateReport(
        _paginationData(WorkspaceData(id: 'ws-long', notes: text)),
      );
      final content = _pdfContent(bytes);
      for (var i = 0; i < 800; i++) {
        expect(
          content.contains('DETAIL${i}END'),
          isTrue,
          reason: 'Missing detail $i',
        );
      }
      expect(content, contains('FINALDECISION'));
      expect(content, contains('NEXTROW'));
    });

    test('preserves malformed tables and escaped pipes', () async {
      const text =
          'Team observation\n\n'
          '| Item | Value |\n| --- | --- |\n| Only one cell |\n\n'
          '| Item | Value |\n| --- | --- |\n'
          r'| Seal | Water \| dust; C:\\drawings\\seal |';
      final bytes = await PdfReportService.generateReport(
        _paginationData(const WorkspaceData(id: 'ws-long', notes: text)),
      );
      final content = _pdfContent(bytes);
      expect(content, contains('Only one cell'));
      expect(content, contains('Water | dust;'));
      expect(content, contains('Team observation'));
    });
  });
  group('PdfReportService pagination', () {
    final longText = List.generate(
      350,
      (i) => 'Engineering requirement $i: verify the assembly under full load.',
    ).join('\n');
    final markedText = 'STARTMARKER\n$longText\nENDMARKER';

    for (final field in [
      'description',
      'notes',
      'engineering comments',
      'action',
      'comment',
    ]) {
      test('paginates a long $field without retrying the same block', () async {
        final workspace = WorkspaceData(
          id: 'ws-long',
          itemDescription: field == 'description' ? markedText : '',
          notes: field == 'notes' ? markedText : '',
          engineeringComments: field == 'engineering comments'
              ? markedText
              : '',
          actionDescription: field == 'action' ? markedText : '',
          comments: field == 'comment'
              ? [
                  Comment(
                    id: 'comment-1',
                    author: 'Reviewer',
                    content: markedText,
                    createdAt: DateTime(2026, 10, 11),
                  ),
                ]
              : [],
        );
        final bytes = await PdfReportService.generateReport(
          _paginationData(workspace),
        );
        final content = _pdfContent(bytes);
        expect(content, contains('STARTMARKER'));
        expect(content, contains('ENDMARKER'));
      });
    }

    test('paginates many evidence images in one substep', () async {
      final refs = List.generate(40, (i) => 'evidence-$i.png');
      final bytes = await PdfReportService.generateReport(
        _paginationData(
          WorkspaceData(id: 'ws-long', images: refs),
          images: {for (final ref in refs) ref: _pixel},
        ),
      );
      final content = _pdfContent(bytes);
      for (final ref in refs) {
        expect(content, contains(ref));
      }
    });

    test('paginates thousands of short lines in one note', () async {
      final notes = List.generate(1500, (_) => 'X').join('\n');
      final bytes = await PdfReportService.generateReport(
        _paginationData(
          WorkspaceData(id: 'ws-long', notes: '$notes\nFINALSHORTLINE'),
        ),
      );
      final content = _pdfContent(bytes);
      expect(RegExp(r'\bX\b').allMatches(content).length, 1500);
      expect(content, contains('FINALSHORTLINE'));
    });

    test('paginates a long paragraph without newline boundaries', () async {
      final notes = List.generate(
        500,
        (i) => 'PARAGRAPH${i}END Verify the assembly under full load.',
      ).join(' ');
      final bytes = await PdfReportService.generateReport(
        _paginationData(WorkspaceData(id: 'ws-long', notes: notes)),
      );
      final content = _pdfContent(bytes);
      for (var i = 0; i < 500; i++) {
        expect(
          content.contains('PARAGRAPH${i}END'),
          isTrue,
          reason: 'Missing paragraph item $i',
        );
      }
    });

    test('exports more than 20 pages without losing the last note', () async {
      final notes = List.generate(
        1600,
        (i) =>
            'ROW${i}END: Verify each component before approving this design.',
      ).join('\n');
      final refs = List.generate(40, (i) => 'evidence-$i.png');
      final data = _paginationData(
        WorkspaceData(
          id: 'ws-long',
          notes: notes,
          images: refs,
          actionDescription: 'Complete the final load test.',
          assignee: 'Lead engineer',
          discipline: 'Mechanical',
        ),
        images: {for (final ref in refs) ref: _pixel},
      );
      final bytes = await PdfReportService.generateReport(data);
      final content = _pdfContent(bytes);
      for (var i = 0; i < 1600; i++) {
        expect(content, contains('ROW${i}END'));
      }
      expect(content, contains('evidence-39.png'));
      expect(content, contains('Complete the final load test.'));
      expect(
        RegExp(r'/Type\s*/Page\b').allMatches(latin1.decode(bytes)).length,
        greaterThan(20),
      );

      final output = Platform.environment['PDF_REGRESSION_OUTPUT'];
      if (output != null) await File(output).writeAsBytes(bytes);
    });
  });
  group('SupabaseStorage path and url resolution', () {
    test('attachmentDisplayName extracts clean filename', () {
      expect(
        SupabaseStorage.attachmentDisplayName(
          'storage:attachments:workspace/ws-1/12345678901234567890123456789012_Checklist.pdf',
        ),
        'Checklist.pdf',
      );
      expect(
        SupabaseStorage.attachmentDisplayName(
          'workspace/ws-1/System_Diagram.png',
        ),
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
      expect(SupabaseStorage.attachmentObjectPath('file.pdf'), 'file.pdf');
    });
  });

  group('PdfReportService evidence section generation', () {
    test('generateReport completes successfully with evidence hyperlinks', () async {
      final transparentPixel = _pixel;

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
      final source = latin1.decode(bytes);
      for (final url in pdfData.workspaceAttachmentUrls.values) {
        expect(source, contains(url));
      }
      expect(_pdfContent(bytes), contains('File unavailable'));
    });
  });
}

final _pixel = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAACklEQVR4nGMAAQAABQABDQottAAAAABJRU5ErkJggg==',
);

ProjectPdfData _paginationData(
  WorkspaceData workspace, {
  Map<String, Uint8List> images = const {},
}) {
  final date = DateTime(2026, 10, 11);
  return ProjectPdfData(
    review: DesignReview(
      id: 'project-long',
      name: 'Pagination regression',
      owner: 'Engineer',
      discipline: 'Mechanical',
      createdAt: date,
      lastUpdated: date,
      stages: [
        Stage(id: 'requirements', name: 'Requirements', lastUpdated: date),
        Stage(
          id: 'concept',
          name: 'Concept',
          lastUpdated: date,
          subSteps: [
            SubStep(
              id: 'sub-long',
              name: 'Assembly concept',
              workspaceId: workspace.id,
            ),
          ],
        ),
      ],
    ),
    workspaces: [workspace],
    logoBytes: _pixel,
    workspaceImages: images,
    workspaceAttachmentUrls: const {},
  );
}

// Inspect decompressed page streams; generation alone can pass with clipped or
// missing content. The fixture uses standard Helvetica and ASCII markers.
String _pdfContent(Uint8List bytes) {
  final source = latin1.decode(bytes);
  final streams = RegExp(r'stream\r?\n(.*?)\r?\nendstream', dotAll: true);
  final decoded = streams
      .allMatches(source)
      .map((match) {
        try {
          return latin1.decode(ZLibDecoder().convert(latin1.encode(match[1]!)));
        } on FormatException {
          return match[1]!;
        }
      })
      .join('\n');
  return RegExp(
    r'\(([^()]*)\)',
  ).allMatches(decoded).map((match) => match[1]!).join(' ');
}
