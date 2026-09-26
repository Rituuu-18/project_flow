import 'dart:math' as math;
import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../core/database/supabase_storage.dart';
import '../features/reviews/domain/entities/design_review.dart';
import '../features/reviews/domain/entities/stage.dart';
import '../features/reviews/domain/entities/sub_step.dart';
import '../features/reviews/domain/entities/stakeholder.dart';
import '../features/reviews/domain/utils/default_stages.dart';
import '../features/reviews/domain/utils/drl_weights.dart';
import '../features/workspace/domain/entities/workspace_data.dart';
import '../core/utils/enums.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:supabase_flutter/supabase_flutter.dart';
import '../features/reviews/domain/repositories/design_review_repository.dart';
import '../features/workspace/domain/repositories/workspace_repository.dart';
import 'project_pdf_data.dart';

class PdfReportService {
  static Future<ProjectPdfData> loadFreshProjectPdfData(
    String projectId,
    DesignReviewRepository reviewRepo,
    WorkspaceRepository workspaceRepo,
  ) async {
    // 1. Fetch fresh review from DB
    final freshReview = await reviewRepo.getReviewById(projectId);
    if (freshReview == null) {
      throw Exception('Review not found.');
    }

    // 2. Load logo
    final ByteData logoData = await rootBundle.load('assets/ed-logo.png');
    final Uint8List logoBytes = logoData.buffer.asUint8List();

    // 3. Load project image
    Uint8List? projectImageBytes;
    if (freshReview.imageUrl != null && freshReview.imageUrl!.isNotEmpty) {
      try {
        final response = await http.get(Uri.parse(freshReview.imageUrl!));
        if (response.statusCode == 200) {
          projectImageBytes = response.bodyBytes;
        }
      } catch (e) {
        debugPrint('Could not load project image: $e');
      }
    }

    // 4 & 5. Fetch all workspaces and their images/URLs sequentially
    final workspaces = <WorkspaceData>[];
    final workspaceImages = <String, Uint8List>{};
    final workspaceAttachmentUrls = <String, String>{};

    for (final stage in freshReview.stages) {
      for (final sub in stage.subSteps) {
        try {
          final ws = await workspaceRepo.getWorkspaceById(sub.workspaceId);
          if (ws == null) continue;
          workspaces.add(ws);

          final allPaths = {...ws.images, ...ws.attachments, ...ws.documents}.toList();
          for (final path in allPaths) {
            String? finalUrl;
            try {
              finalUrl = await SupabaseStorage(Supabase.instance.client)
                  .resolveAttachmentUrl(path, workspaceId: ws.id);
            } catch (e) {
              debugPrint('Could not resolve attachment URL for $path: $e');
            }

            if (finalUrl != null &&
                finalUrl.isNotEmpty &&
                (finalUrl.startsWith('http://') || finalUrl.startsWith('https://'))) {
              workspaceAttachmentUrls[path] = finalUrl;
            }

            if (workspaceImages.containsKey(path)) continue;
            final lower = path.toLowerCase();
            final isLikelyImage = lower.endsWith('.png') ||
                lower.endsWith('.jpg') ||
                lower.endsWith('.jpeg') ||
                lower.endsWith('.webp') ||
                lower.endsWith('.gif') ||
                path.startsWith('storage:attachments:');
            if (!isLikelyImage) continue;

            try {
              if (finalUrl != null && finalUrl.startsWith('http')) {
                final response = await http.get(Uri.parse(finalUrl));
                if (response.statusCode == 200) {
                  final contentType = response.headers['content-type'] ?? '';
                  if (contentType.startsWith('image/') || isLikelyImage) {
                    workspaceImages[path] = response.bodyBytes;
                  }
                }
              }
            } catch (e) {
              debugPrint('Could not load workspace image $path: $e');
            }
          }
        } catch (e) {
          debugPrint('Failed to load workspace for subStep ${sub.name}: $e');
        }
      }
    }

    return ProjectPdfData(
      review: freshReview,
      workspaces: workspaces,
      logoBytes: logoBytes,
      projectImageBytes: projectImageBytes,
      workspaceImages: workspaceImages,
      workspaceAttachmentUrls: workspaceAttachmentUrls,
    );
  }

  static Future<Uint8List> generateReport(ProjectPdfData pdfData) async {
    final review = pdfData.review;
    final workspaces = pdfData.workspaces;
    final logoBytes = pdfData.logoBytes;
    final workspaceImages = pdfData.workspaceImages;

    final pdf = pw.Document(
      title: 'Design Review Project Report - ${review.name}',
      author: 'EvalioDesign',
    );

    final drl = calculateDrl(review.stages);

    // ==========================================
    // PAGE 1: Project Overview + Stakeholders
    // ==========================================
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 40, vertical: 34),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _buildHeader(logoBytes),
              pw.SizedBox(height: 18),
              if (pdfData.projectImageBytes != null) ...[
                pw.Center(
                  child: pw.Container(
                    height: 180,
                    width: double.infinity,
                    decoration: pw.BoxDecoration(
                      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                      border: pw.Border.all(color: PdfColor.fromHex('#E2E8F0'), width: 1),
                    ),
                    child: pw.ClipRRect(
                      horizontalRadius: 8,
                      verticalRadius: 8,
                      child: pw.Image(
                        pw.MemoryImage(pdfData.projectImageBytes!),
                        fit: pw.BoxFit.cover,
                      ),
                    ),
                  ),
                ),
                pw.SizedBox(height: 18),
              ],
              _buildProjectOverview(review, drl),
              pw.SizedBox(height: 20),
              _buildStakeholders(review),
              pw.Spacer(),
              _buildFooter(1, context.pagesCount),
            ],
          );
        },
      ),
    );

    // ==========================================
    // PAGE 2: Design Readiness Gauge + Main Steps
    // ==========================================
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 40, vertical: 34),
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              _buildHeader(logoBytes),
              pw.SizedBox(height: 14),
              _buildDesignReadinessLevel(drl),
              pw.SizedBox(height: 16),
              _buildAllMainSteps(review),
              pw.Spacer(),
              _buildFooter(2, context.pagesCount),
            ],
          );
        },
      ),
    );

    // ==========================================
    // PAGE 3+: Design Review Step 1 — Requirements
    // ==========================================
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 40, vertical: 34),
        header: (context) => _buildHeader(logoBytes),
        footer: (context) => _buildFooter(context.pageNumber, context.pagesCount),
        build: (context) {
          return [
            _buildSectionHeader('Design Review Step 1 - Requirements'),
            pw.SizedBox(height: 10),
            ..._buildRequirementsSubSteps(
              review: review,
              workspaces: workspaces,
              workspaceImages: workspaceImages,
              workspaceAttachmentUrls: pdfData.workspaceAttachmentUrls,
            ),
          ];
        },
      ),
    );

    // ==========================================
    // PAGE X+: Design Review Step 2 - Concept
    // ==========================================
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 40, vertical: 34),
        header: (context) => _buildHeader(logoBytes),
        footer: (context) => _buildFooter(context.pageNumber, context.pagesCount),
        build: (context) {
          return [
            _buildSectionHeader('Design Review Step 2 - Concept'),
            pw.SizedBox(height: 10),
            ..._buildConceptSubSteps(
              review: review,
              workspaces: workspaces,
              workspaceImages: workspaceImages,
              workspaceAttachmentUrls: pdfData.workspaceAttachmentUrls,
            ),
          ];
        },
      ),
    );

    // ==========================================
    // PAGE X+: Design Review Step 3 - Preliminary Design
    // ==========================================
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 40, vertical: 34),
        header: (context) => _buildHeader(logoBytes),
        footer: (context) => _buildFooter(context.pageNumber, context.pagesCount),
        build: (context) {
          return [
            _buildSectionHeader('Design Review Step 3 - Preliminary Design'),
            pw.SizedBox(height: 10),
            ..._buildPreliminaryDesignSubSteps(
              review: review,
              workspaces: workspaces,
              workspaceImages: workspaceImages,
              workspaceAttachmentUrls: pdfData.workspaceAttachmentUrls,
            ),
          ];
        },
      ),
    );

    // ==========================================
    // PAGE X+: Design Review Step 4 - Detailed Design
    // ==========================================
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 40, vertical: 34),
        header: (context) => _buildHeader(logoBytes),
        footer: (context) => _buildFooter(context.pageNumber, context.pagesCount),
        build: (context) {
          return [
            _buildSectionHeader('Design Review Step 4 - Detailed Design'),
            pw.SizedBox(height: 10),
            ..._buildDetailedDesignSubSteps(
              review: review,
              workspaces: workspaces,
              workspaceImages: workspaceImages,
              workspaceAttachmentUrls: pdfData.workspaceAttachmentUrls,
            ),
          ];
        },
      ),
    );

    // ==========================================
    // PAGE X+: Design Review Step 5 - Simulation (FEA, CFD...)
    // ==========================================
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 40, vertical: 34),
        header: (context) => _buildHeader(logoBytes),
        footer: (context) => _buildFooter(context.pageNumber, context.pagesCount),
        build: (context) {
          return [
            _buildSectionHeader('Design Review Step 5 - Simulation (FEA, CFD...)'),
            pw.SizedBox(height: 10),
            ..._buildSimulationSubSteps(
              review: review,
              workspaces: workspaces,
              workspaceImages: workspaceImages,
              workspaceAttachmentUrls: pdfData.workspaceAttachmentUrls,
            ),
          ];
        },
      ),
    );

    // ==========================================
    // PAGE X+: Design Review Step 6 - Prototype
    // ==========================================
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 40, vertical: 34),
        header: (context) => _buildHeader(logoBytes),
        footer: (context) => _buildFooter(context.pageNumber, context.pagesCount),
        build: (context) {
          return [
            _buildSectionHeader('Design Review Step 6 - Prototype'),
            pw.SizedBox(height: 10),
            ..._buildPrototypeSubSteps(
              review: review,
              workspaces: workspaces,
              workspaceImages: workspaceImages,
              workspaceAttachmentUrls: pdfData.workspaceAttachmentUrls,
            ),
          ];
        },
      ),
    );

    // ==========================================
    // PAGE X+: Design Review Step 7 - Testing Validation
    // ==========================================
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 40, vertical: 34),
        header: (context) => _buildHeader(logoBytes),
        footer: (context) => _buildFooter(context.pageNumber, context.pagesCount),
        build: (context) {
          return [
            _buildSectionHeader('Design Review Step 7 - Testing Validation'),
            pw.SizedBox(height: 10),
            ..._buildTestingValidationSubSteps(
              review: review,
              workspaces: workspaces,
              workspaceImages: workspaceImages,
              workspaceAttachmentUrls: pdfData.workspaceAttachmentUrls,
            ),
          ];
        },
      ),
    );

    // ==========================================
    // PAGE X+: Design Review Step 8 - Manufacturing Readiness
    // ==========================================
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 40, vertical: 34),
        header: (context) => _buildHeader(logoBytes),
        footer: (context) => _buildFooter(context.pageNumber, context.pagesCount),
        build: (context) {
          return [
            _buildSectionHeader('Design Review Step 8 - Manufacturing Readiness'),
            pw.SizedBox(height: 10),
            ..._buildManufacturingReadinessSubSteps(
              review: review,
              workspaces: workspaces,
              workspaceImages: workspaceImages,
              workspaceAttachmentUrls: pdfData.workspaceAttachmentUrls,
            ),
          ];
        },
      ),
    );

    // ==========================================
    // PAGE X+: Design Review Step 9 - Final Release
    // ==========================================
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 40, vertical: 34),
        header: (context) => _buildHeader(logoBytes),
        footer: (context) => _buildFooter(context.pageNumber, context.pagesCount),
        build: (context) {
          return [
            _buildSectionHeader('Design Review Step 9 - Final Release'),
            pw.SizedBox(height: 10),
            ..._buildFinalReleaseSubSteps(
              review: review,
              workspaces: workspaces,
              workspaceImages: workspaceImages,
              workspaceAttachmentUrls: pdfData.workspaceAttachmentUrls,
            ),
          ];
        },
      ),
    );

    // ==========================================
    // PAGE X+: Design Review Step 10 - Continuous Improvement
    // ==========================================
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 40, vertical: 34),
        header: (context) => _buildHeader(logoBytes),
        footer: (context) => _buildFooter(context.pageNumber, context.pagesCount),
        build: (context) {
          return [
            _buildSectionHeader('Design Review Step 10 - Continuous Improvement'),
            pw.SizedBox(height: 10),
            ..._buildContinuousImprovementSubSteps(
              review: review,
              workspaces: workspaces,
              workspaceImages: workspaceImages,
              workspaceAttachmentUrls: pdfData.workspaceAttachmentUrls,
            ),
          ];
        },
      ),
    );

    return pdf.save();
  }

  // ── Header on Every Page ──────────────────────────────────────────────────
  static pw.Widget _buildHeader(Uint8List logoBytes) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 12),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: PdfColor.fromInt(0xFFE2E8F0), width: 1.2),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.center,
            children: [
              pw.Image(pw.MemoryImage(logoBytes), width: 28, height: 28),
              pw.SizedBox(width: 10),
              pw.Text(
                'EvalioDesign',
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 17,
                  color: PdfColor.fromHex('#0F172A'),
                ),
              ),
            ],
          ),
          pw.Text(
            'Design Review Project Report',
            style: pw.TextStyle(
              color: PdfColor.fromHex('#64748B'),
              fontSize: 12,
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // ── PAGE 1: Section 1 (Project Overview) ──────────────────────────────────
  static pw.Widget _buildProjectOverview(DesignReview review, double drl) {
    final ownerText = review.owner.trim().isEmpty ? '-' : review.owner.trim();
    final disciplineText =
        review.discipline.trim().isEmpty ? '-' : review.discipline.trim();
    final readinessText = '${drl.toStringAsFixed(2)}%';

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          '1. Project Overview',
          style: pw.TextStyle(
            fontSize: 14,
            fontWeight: pw.FontWeight.bold,
            color: PdfColor.fromHex('#0F172A'),
          ),
        ),
        pw.SizedBox(height: 8),
        pw.Container(
          decoration: pw.BoxDecoration(
            color: PdfColor.fromHex('#F8FAFC'),
            border: pw.Border.all(
              color: PdfColor.fromHex('#E2E8F0'),
              width: 1,
            ),
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
          ),
          child: pw.Column(
            children: [
              _buildOverviewRow('Project Name', review.name, isFirst: true),
              _buildDivider(),
              _buildOverviewRow('Owner', ownerText),
              _buildDivider(),
              _buildOverviewRow('Discipline', disciplineText),
              _buildDivider(),
              _buildOverviewRow('Design Readiness', readinessText, isLast: true, isHighlight: true),
            ],
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildOverviewRow(
    String label,
    String value, {
    bool isFirst = false,
    bool isLast = false,
    bool isHighlight = false,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: pw.Row(
        children: [
          pw.SizedBox(
            width: 140,
            child: pw.Text(
              label,
              style: pw.TextStyle(
                fontSize: 10.5,
                fontWeight: pw.FontWeight.bold,
                color: PdfColor.fromHex('#475569'),
              ),
            ),
          ),
          pw.Expanded(
            child: pw.Text(
              value,
              style: pw.TextStyle(
                fontSize: 10.5,
                fontWeight: isHighlight ? pw.FontWeight.bold : pw.FontWeight.normal,
                color: isHighlight
                    ? PdfColor.fromHex('#005CFF')
                    : PdfColor.fromHex('#0F172A'),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildDivider() {
    return pw.Container(
      height: 1,
      color: PdfColor.fromHex('#E2E8F0'),
    );
  }

  // ── PAGE 1: Section 2 (Stakeholders Information) ──────────────────────────
  static pw.Widget _buildStakeholders(DesignReview review) {
    final stakeholders = review.stakeholders;

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          '2. Stakeholders Information',
          style: pw.TextStyle(
            fontSize: 14,
            fontWeight: pw.FontWeight.bold,
            color: PdfColor.fromHex('#0F172A'),
          ),
        ),
        pw.SizedBox(height: 8),
        if (stakeholders.isEmpty)
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            decoration: pw.BoxDecoration(
              color: PdfColor.fromHex('#F8FAFC'),
              border: pw.Border.all(
                color: PdfColor.fromHex('#E2E8F0'),
                width: 1,
              ),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
            ),
            child: pw.Text(
              'No stakeholders assigned to this project.',
              style: pw.TextStyle(
                fontSize: 10.5,
                color: PdfColor.fromHex('#64748B'),
                fontStyle: pw.FontStyle.italic,
              ),
            ),
          )
        else
          pw.Container(
            decoration: pw.BoxDecoration(
              color: PdfColor.fromHex('#FFFFFF'),
              border: pw.Border.all(
                color: PdfColor.fromHex('#E2E8F0'),
                width: 1,
              ),
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
            ),
            child: pw.ClipRRect(
              horizontalRadius: 8,
              verticalRadius: 8,
              child: pw.Table(
                columnWidths: {
                  0: const pw.FlexColumnWidth(3),
                  1: const pw.FlexColumnWidth(2),
                },
                children: [
                  // Table Header
                  pw.TableRow(
                    decoration: pw.BoxDecoration(
                      color: PdfColor.fromHex('#F1F5F9'),
                    ),
                    children: [
                      _buildTableHeaderCell('Stakeholder Name'),
                      _buildTableHeaderCell('Discipline'),
                    ],
                  ),
                  // Table Rows
                  for (int i = 0; i < stakeholders.length; i++)
                    pw.TableRow(
                      decoration: pw.BoxDecoration(
                        color: i % 2 == 0
                            ? PdfColor.fromHex('#FFFFFF')
                            : PdfColor.fromHex('#F8FAFC'),
                      ),
                      children: [
                        _buildTableCell(stakeholders[i].name.trim().isEmpty ? '-' : stakeholders[i].name.trim()),
                        _buildTableCell(stakeholders[i].role.trim().isEmpty ? '-' : stakeholders[i].role.trim()),
                      ],
                    ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  // ── PAGE 2: Section 1 (Design Readiness Level Gauge) ──────────────────────
  static pw.Widget _buildDesignReadinessLevel(double drl) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          '1. Design Readiness Level',
          style: pw.TextStyle(
            fontSize: 14,
            fontWeight: pw.FontWeight.bold,
            color: PdfColor.fromHex('#0F172A'),
          ),
        ),
        pw.SizedBox(height: 8),
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.symmetric(vertical: 14, horizontal: 16),
          decoration: pw.BoxDecoration(
            color: PdfColor.fromHex('#F8FAFC'),
            border: pw.Border.all(
              color: PdfColor.fromHex('#E2E8F0'),
              width: 1,
            ),
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
          ),
          child: pw.Center(
            child: _buildSemicircularGauge(drl / 100.0),
          ),
        ),
      ],
    );
  }

  static pw.Widget _buildSemicircularGauge(double progress) {
    final clamped = progress.clamp(0.0, 1.0);
    final progressPercent = (clamped * 100).toStringAsFixed(2);

    const double width = 300;
    const double height = 155;
    const double cx = width / 2; // 150
    const double cy = 34; // Center Y in PDF bottom-up coordinate space
    const double radius = 90;
    const double strokeWidth = 16;

    final primaryColor = PdfColor.fromHex('#005CFF');
    final bgArcColor = PdfColor.fromHex('#E2E8F0');
    final needleColor = PdfColor.fromHex('#334155');
    final mutedColor = PdfColor.fromHex('#64748B');

    return pw.Container(
      width: width,
      height: height,
      child: pw.Stack(
        alignment: pw.Alignment.center,
        children: [
          pw.CustomPaint(
            size: const PdfPoint(width, height),
            painter: (PdfGraphics canvas, PdfPoint size) {
              // 1. Draw full background arc (0% to 100%, from PI to 0)
              canvas.saveContext();
              canvas.setStrokeColor(bgArcColor);
              canvas.setLineWidth(strokeWidth);
              canvas.setLineCap(PdfLineCap.butt);
              const int totalSteps = 80;
              for (int i = 0; i <= totalSteps; i++) {
                final double angle = math.pi - (math.pi * (i / totalSteps));
                final double x = cx + radius * math.cos(angle);
                final double y = cy + radius * math.sin(angle);
                if (i == 0) {
                  canvas.moveTo(x, y);
                } else {
                  canvas.lineTo(x, y);
                }
              }
              canvas.strokePath();
              canvas.restoreContext();

              // 2. Draw progress arc (0% to progress, starting at PI)
              if (clamped > 0.0001) {
                canvas.saveContext();
                canvas.setStrokeColor(primaryColor);
                canvas.setLineWidth(strokeWidth);
                canvas.setLineCap(PdfLineCap.butt);
                final int progSteps =
                    (totalSteps * clamped).ceil().clamp(2, totalSteps);
                for (int i = 0; i <= progSteps; i++) {
                  final double angle =
                      math.pi - (math.pi * clamped * (i / progSteps));
                  final double x = cx + radius * math.cos(angle);
                  final double y = cy + radius * math.sin(angle);
                  if (i == 0) {
                    canvas.moveTo(x, y);
                  } else {
                    canvas.lineTo(x, y);
                  }
                }
                canvas.strokePath();
                canvas.restoreContext();
              }

              // 3. Draw Needle pointing to current percentage
              final double needleAngle = math.pi - (math.pi * clamped);
              final double needleLength = radius - strokeWidth / 2 - 4;
              final double needleTipX = cx + needleLength * math.cos(needleAngle);
              final double needleTipY = cy + needleLength * math.sin(needleAngle);

              canvas.saveContext();
              canvas.setStrokeColor(needleColor);
              canvas.setLineWidth(2.5);
              canvas.setLineCap(PdfLineCap.round);
              canvas.moveTo(cx, cy);
              canvas.lineTo(needleTipX, needleTipY);
              canvas.strokePath();
              canvas.restoreContext();

              // 4. Draw Pivot Circle
              canvas.saveContext();
              canvas.setFillColor(needleColor);
              canvas.drawEllipse(cx, cy, 5.5, 5.5);
              canvas.fillPath();
              canvas.restoreContext();

              // 5. Draw Pivot Inner Dot
              canvas.saveContext();
              canvas.setFillColor(PdfColors.white);
              canvas.drawEllipse(cx, cy, 2.2, 2.2);
              canvas.fillPath();
              canvas.restoreContext();
            },
          ),
          // 0% label (left endpoint)
          pw.Positioned(
            left: cx - radius - strokeWidth / 2 - 2,
            bottom: 8,
            child: pw.Text(
              '0%',
              style: pw.TextStyle(
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
                color: mutedColor,
              ),
            ),
          ),
          // 100% label (right endpoint)
          pw.Positioned(
            right: cx - radius - strokeWidth / 2 - 12,
            bottom: 8,
            child: pw.Text(
              '100%',
              style: pw.TextStyle(
                fontSize: 10,
                fontWeight: pw.FontWeight.bold,
                color: mutedColor,
              ),
            ),
          ),
          // Center text display (Readiness percentage & label)
          pw.Positioned(
            bottom: 40,
            child: pw.Column(
              mainAxisSize: pw.MainAxisSize.min,
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Text(
                  '$progressPercent%',
                  style: pw.TextStyle(
                    fontSize: 22,
                    fontWeight: pw.FontWeight.bold,
                    color: primaryColor,
                  ),
                ),
                pw.SizedBox(height: 2),
                pw.Text(
                  'Actual Readiness',
                  style: pw.TextStyle(
                    fontSize: 9.5,
                    fontWeight: pw.FontWeight.bold,
                    color: mutedColor,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── PAGE 2: Section 2 (All Main Design Review Steps Percentage) ───────────
  static pw.Widget _buildAllMainSteps(DesignReview review) {
    final stages = review.stages;

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          '2. All Main Design Review Steps Percentage',
          style: pw.TextStyle(
            fontSize: 14,
            fontWeight: pw.FontWeight.bold,
            color: PdfColor.fromHex('#0F172A'),
          ),
        ),
        pw.SizedBox(height: 8),
        pw.Container(
          decoration: pw.BoxDecoration(
            color: PdfColor.fromHex('#FFFFFF'),
            border: pw.Border.all(
              color: PdfColor.fromHex('#E2E8F0'),
              width: 1,
            ),
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
          ),
          child: pw.ClipRRect(
            horizontalRadius: 8,
            verticalRadius: 8,
            child: pw.Table(
              columnWidths: {
                0: const pw.FlexColumnWidth(3),
                1: const pw.FlexColumnWidth(1.2),
              },
              children: [
                // Table Header
                pw.TableRow(
                  decoration: pw.BoxDecoration(
                    color: PdfColor.fromHex('#F1F5F9'),
                  ),
                  children: [
                    _buildTableHeaderCell('Design Review Step'),
                    _buildTableHeaderCell('Percentage', isRightAligned: true),
                  ],
                ),
                // Table Rows
                for (int i = 0; i < stages.length; i++)
                  pw.TableRow(
                    decoration: pw.BoxDecoration(
                      color: i % 2 == 0
                          ? PdfColor.fromHex('#FFFFFF')
                          : PdfColor.fromHex('#F8FAFC'),
                    ),
                    children: [
                      _buildTableCell(stages[i].name),
                      _buildTableCell(
                        '${(stages[i].progress * 100).toStringAsFixed(2)}%',
                        isRightAligned: true,
                        isBold: true,
                        textColor: stages[i].progress > 0
                            ? PdfColor.fromHex('#005CFF')
                            : PdfColor.fromHex('#64748B'),
                      ),
                    ],
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ── Helper Table Cells ────────────────────────────────────────────────────
  static pw.Widget _buildTableHeaderCell(String text, {bool isRightAligned = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 7),
      child: pw.Align(
        alignment: isRightAligned ? pw.Alignment.centerRight : pw.Alignment.centerLeft,
        child: pw.Text(
          text,
          style: pw.TextStyle(
            fontSize: 10,
            fontWeight: pw.FontWeight.bold,
            color: PdfColor.fromHex('#334155'),
          ),
        ),
      ),
    );
  }

  static pw.Widget _buildTableCell(
    String text, {
    bool isRightAligned = false,
    bool isBold = false,
    PdfColor? textColor,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      child: pw.Align(
        alignment: isRightAligned ? pw.Alignment.centerRight : pw.Alignment.centerLeft,
        child: pw.Text(
          text,
          style: pw.TextStyle(
            fontSize: 9.5,
            fontWeight: isBold ? pw.FontWeight.bold : pw.FontWeight.normal,
            color: textColor ?? PdfColor.fromHex('#0F172A'),
          ),
        ),
      ),
    );
  }

  // ── Footer with dynamic page numbering ────────────────────────────────────
  static pw.Widget _buildFooter(int pageNumber, int totalPages) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(top: 10),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          top: pw.BorderSide(color: PdfColor.fromInt(0xFFE2E8F0), width: 1.2),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            DateFormat('dd MMM yyyy').format(DateTime.now()),
            style: pw.TextStyle(
              fontSize: 9,
              color: PdfColor.fromHex('#94A3B8'),
            ),
          ),
          pw.Text(
            'Page $pageNumber of $totalPages',
            style: pw.TextStyle(
              fontSize: 9,
              color: PdfColor.fromHex('#94A3B8'),
            ),
          ),
        ],
      ),
    );
  }

  // ── Generic Section Header ──────────────────────────────────────────────────
  static pw.Widget _buildSectionHeader(String title) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromHex('#0F172A'),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
      ),
      child: pw.Text(
        title,
        style: pw.TextStyle(
          fontSize: 15,
          fontWeight: pw.FontWeight.bold,
          color: PdfColors.white,
        ),
      ),
    );
  }

  static const List<String> _requirementsSubStepNames = [
    'Define the problem and scope',
    'Identify stakeholders and interfaces',
    'Capture user and business needs',
    'Derive functional requirements',
    'Define performance and quality targets',
    'Establish constraints and boundaries',
    'Non-functional requirements',
    'Validation and testability definition',
    'Requirements document and structure',
    'Review, negotiate, and freeze baseline',
  ];

  static List<pw.Widget> _buildRequirementsSubSteps({
    required DesignReview review,
    required List<WorkspaceData> workspaces,
    required Map<String, Uint8List> workspaceImages,
    required Map<String, String> workspaceAttachmentUrls,
  }) {
    final reqStage = review.stages.firstWhere(
      (s) => s.name.trim().toLowerCase() == 'requirements',
      orElse: () => review.stages.isNotEmpty
          ? review.stages.first
          : Stage(id: '', name: 'Requirements', lastUpdated: DateTime.now()),
    );

    final widgets = <pw.Widget>[];

    for (int i = 0; i < _requirementsSubStepNames.length; i++) {
      final name = _requirementsSubStepNames[i];
      final subStepEntity = reqStage.subSteps.firstWhere(
        (s) => s.name.trim().toLowerCase() == name.trim().toLowerCase(),
        orElse: () => (i < reqStage.subSteps.length
            ? reqStage.subSteps[i]
            : SubStep(id: '', name: name, workspaceId: '')),
      );

      final wsData = workspaces.firstWhere(
        (w) => w.id == subStepEntity.workspaceId && subStepEntity.workspaceId.isNotEmpty,
        orElse: () => WorkspaceData(id: subStepEntity.workspaceId, checklistItem: name),
      );

      widgets.add(
        _buildSubStepCard(
          subStepNumber: i + 1,
          subStepName: name,
          wsData: wsData,
          workspaceImages: workspaceImages,
          workspaceAttachmentUrls: workspaceAttachmentUrls,
          projectStakeholders: review.stakeholders,
        ),
      );

      if (i < _requirementsSubStepNames.length - 1) {
        widgets.add(pw.SizedBox(height: 10));
      }
    }

    return widgets;
  }

  static List<pw.Widget> _buildConceptSubSteps({
    required DesignReview review,
    required List<WorkspaceData> workspaces,
    required Map<String, Uint8List> workspaceImages,
    required Map<String, String> workspaceAttachmentUrls,
  }) {
    final conceptStage = review.stages.firstWhere(
      (s) => s.name.trim().toLowerCase() == 'concept',
      orElse: () => review.stages.firstWhere(
        (s) => s.name.trim().toLowerCase() == 'concept design',
        orElse: () => Stage(id: '', name: 'Concept', lastUpdated: DateTime.now()),
      ),
    );

    final widgets = <pw.Widget>[];
    final subSteps = conceptStage.subSteps;

    if (subSteps.isEmpty) {
      widgets.add(
        pw.Text(
          'No Concept substeps found for this project.',
          style: pw.TextStyle(
            fontSize: 11.5,
            color: PdfColor.fromHex('#64748B'),
            fontStyle: pw.FontStyle.italic,
          ),
        ),
      );
      return widgets;
    }

    for (int i = 0; i < subSteps.length; i++) {
      final subStepEntity = subSteps[i];
      final name = subStepEntity.name;

      final wsData = workspaces.firstWhere(
        (w) => w.id == subStepEntity.workspaceId && subStepEntity.workspaceId.isNotEmpty,
        orElse: () => WorkspaceData(id: subStepEntity.workspaceId, checklistItem: name),
      );

      widgets.add(
        _buildSubStepCard(
          subStepNumber: i + 1,
          subStepName: name,
          wsData: wsData,
          workspaceImages: workspaceImages,
          workspaceAttachmentUrls: workspaceAttachmentUrls,
          projectStakeholders: review.stakeholders,
        ),
      );

      if (i < subSteps.length - 1) {
        widgets.add(pw.SizedBox(height: 10));
      }
    }

    return widgets;
  }

  static List<pw.Widget> _buildPreliminaryDesignSubSteps({
    required DesignReview review,
    required List<WorkspaceData> workspaces,
    required Map<String, Uint8List> workspaceImages,
    required Map<String, String> workspaceAttachmentUrls,
  }) {
    final prelimStage = review.stages.firstWhere(
      (s) => s.name.trim().toLowerCase() == 'preliminary design',
      orElse: () => review.stages.firstWhere(
        (s) => s.name.trim().toLowerCase() == 'preliminary',
        orElse: () => Stage(id: '', name: 'Preliminary Design', lastUpdated: DateTime.now()),
      ),
    );

    final widgets = <pw.Widget>[];
    final subSteps = prelimStage.subSteps;

    if (subSteps.isEmpty) {
      widgets.add(
        pw.Text(
          'No Preliminary Design substeps found for this project.',
          style: pw.TextStyle(
            fontSize: 11.5,
            color: PdfColor.fromHex('#64748B'),
            fontStyle: pw.FontStyle.italic,
          ),
        ),
      );
      return widgets;
    }

    for (int i = 0; i < subSteps.length; i++) {
      final subStepEntity = subSteps[i];
      final name = subStepEntity.name;

      final wsData = workspaces.firstWhere(
        (w) => w.id == subStepEntity.workspaceId && subStepEntity.workspaceId.isNotEmpty,
        orElse: () => WorkspaceData(id: subStepEntity.workspaceId, checklistItem: name),
      );

      widgets.add(
        _buildSubStepCard(
          subStepNumber: i + 1,
          subStepName: name,
          wsData: wsData,
          workspaceImages: workspaceImages,
          workspaceAttachmentUrls: workspaceAttachmentUrls,
          projectStakeholders: review.stakeholders,
        ),
      );

      if (i < subSteps.length - 1) {
        widgets.add(pw.SizedBox(height: 10));
      }
    }

    return widgets;
  }

  static List<pw.Widget> _buildDetailedDesignSubSteps({
    required DesignReview review,
    required List<WorkspaceData> workspaces,
    required Map<String, Uint8List> workspaceImages,
    required Map<String, String> workspaceAttachmentUrls,
  }) {
    final detailedStage = review.stages.firstWhere(
      (s) => s.name.trim().toLowerCase() == 'detailed design',
      orElse: () => review.stages.firstWhere(
        (s) => s.name.trim().toLowerCase() == 'detailed',
        orElse: () => Stage(id: '', name: 'Detailed Design', lastUpdated: DateTime.now()),
      ),
    );

    final widgets = <pw.Widget>[];
    final subSteps = detailedStage.subSteps;

    if (subSteps.isEmpty) {
      widgets.add(
        pw.Text(
          'No Detailed Design substeps found for this project.',
          style: pw.TextStyle(
            fontSize: 11.5,
            color: PdfColor.fromHex('#64748B'),
            fontStyle: pw.FontStyle.italic,
          ),
        ),
      );
      return widgets;
    }

    for (int i = 0; i < subSteps.length; i++) {
      final subStepEntity = subSteps[i];
      final name = subStepEntity.name;

      final wsData = workspaces.firstWhere(
        (w) => w.id == subStepEntity.workspaceId && subStepEntity.workspaceId.isNotEmpty,
        orElse: () => WorkspaceData(id: subStepEntity.workspaceId, checklistItem: name),
      );

      widgets.add(
        _buildSubStepCard(
          subStepNumber: i + 1,
          subStepName: name,
          wsData: wsData,
          workspaceImages: workspaceImages,
          workspaceAttachmentUrls: workspaceAttachmentUrls,
          projectStakeholders: review.stakeholders,
        ),
      );

      if (i < subSteps.length - 1) {
        widgets.add(pw.SizedBox(height: 10));
      }
    }

    return widgets;
  }

  static List<pw.Widget> _buildSimulationSubSteps({
    required DesignReview review,
    required List<WorkspaceData> workspaces,
    required Map<String, Uint8List> workspaceImages,
    required Map<String, String> workspaceAttachmentUrls,
  }) {
    final simulationStage = review.stages.firstWhere(
      (s) => s.name.trim().toLowerCase() == 'simulation (fea,cfd...)',
      orElse: () => review.stages.firstWhere(
        (s) => s.name.trim().toLowerCase().startsWith('simulation'),
        orElse: () => Stage(id: '', name: 'Simulation (FEA,CFD...)', lastUpdated: DateTime.now()),
      ),
    );

    final widgets = <pw.Widget>[];
    final subSteps = simulationStage.subSteps;

    if (subSteps.isEmpty) {
      widgets.add(
        pw.Text(
          'No Simulation substeps found for this project.',
          style: pw.TextStyle(
            fontSize: 11.5,
            color: PdfColor.fromHex('#64748B'),
            fontStyle: pw.FontStyle.italic,
          ),
        ),
      );
      return widgets;
    }

    for (int i = 0; i < subSteps.length; i++) {
      final subStepEntity = subSteps[i];
      final name = subStepEntity.name;

      final wsData = workspaces.firstWhere(
        (w) => w.id == subStepEntity.workspaceId && subStepEntity.workspaceId.isNotEmpty,
        orElse: () => WorkspaceData(id: subStepEntity.workspaceId, checklistItem: name),
      );

      widgets.add(
        _buildSubStepCard(
          subStepNumber: i + 1,
          subStepName: name,
          wsData: wsData,
          workspaceImages: workspaceImages,
          workspaceAttachmentUrls: workspaceAttachmentUrls,
          projectStakeholders: review.stakeholders,
        ),
      );

      if (i < subSteps.length - 1) {
        widgets.add(pw.SizedBox(height: 10));
      }
    }

    return widgets;
  }

  static List<pw.Widget> _buildPrototypeSubSteps({
    required DesignReview review,
    required List<WorkspaceData> workspaces,
    required Map<String, Uint8List> workspaceImages,
    required Map<String, String> workspaceAttachmentUrls,
  }) {
    final prototypeStage = review.stages.firstWhere(
      (s) => s.name.trim().toLowerCase() == 'prototype',
      orElse: () => Stage(id: '', name: 'Prototype', lastUpdated: DateTime.now()),
    );

    final widgets = <pw.Widget>[];
    final subSteps = prototypeStage.subSteps;

    if (subSteps.isEmpty) {
      widgets.add(
        pw.Text(
          'No Prototype substeps found for this project.',
          style: pw.TextStyle(
            fontSize: 11.5,
            color: PdfColor.fromHex('#64748B'),
            fontStyle: pw.FontStyle.italic,
          ),
        ),
      );
      return widgets;
    }

    for (int i = 0; i < subSteps.length; i++) {
      final subStepEntity = subSteps[i];
      final name = subStepEntity.name;

      final wsData = workspaces.firstWhere(
        (w) => w.id == subStepEntity.workspaceId && subStepEntity.workspaceId.isNotEmpty,
        orElse: () => WorkspaceData(id: subStepEntity.workspaceId, checklistItem: name),
      );

      widgets.add(
        _buildSubStepCard(
          subStepNumber: i + 1,
          subStepName: name,
          wsData: wsData,
          workspaceImages: workspaceImages,
          workspaceAttachmentUrls: workspaceAttachmentUrls,
          projectStakeholders: review.stakeholders,
        ),
      );

      if (i < subSteps.length - 1) {
        widgets.add(pw.SizedBox(height: 10));
      }
    }

    return widgets;
  }

  static List<pw.Widget> _buildTestingValidationSubSteps({
    required DesignReview review,
    required List<WorkspaceData> workspaces,
    required Map<String, Uint8List> workspaceImages,
    required Map<String, String> workspaceAttachmentUrls,
  }) {
    final testingValidationStage = review.stages.firstWhere(
      (s) => s.name.trim().toLowerCase() == 'testing validation',
      orElse: () => review.stages.firstWhere(
        (s) => s.name.trim().toLowerCase().startsWith('testing'),
        orElse: () => Stage(id: '', name: 'Testing Validation', lastUpdated: DateTime.now()),
      ),
    );

    final widgets = <pw.Widget>[];
    final subSteps = testingValidationStage.subSteps;

    if (subSteps.isEmpty) {
      widgets.add(
        pw.Text(
          'No Testing Validation substeps found for this project.',
          style: pw.TextStyle(
            fontSize: 11.5,
            color: PdfColor.fromHex('#64748B'),
            fontStyle: pw.FontStyle.italic,
          ),
        ),
      );
      return widgets;
    }

    for (int i = 0; i < subSteps.length; i++) {
      final subStepEntity = subSteps[i];
      final name = subStepEntity.name;

      final wsData = workspaces.firstWhere(
        (w) => w.id == subStepEntity.workspaceId && subStepEntity.workspaceId.isNotEmpty,
        orElse: () => WorkspaceData(id: subStepEntity.workspaceId, checklistItem: name),
      );

      widgets.add(
        _buildSubStepCard(
          subStepNumber: i + 1,
          subStepName: name,
          wsData: wsData,
          workspaceImages: workspaceImages,
          workspaceAttachmentUrls: workspaceAttachmentUrls,
          projectStakeholders: review.stakeholders,
        ),
      );

      if (i < subSteps.length - 1) {
        widgets.add(pw.SizedBox(height: 10));
      }
    }

    return widgets;
  }

  static List<pw.Widget> _buildManufacturingReadinessSubSteps({
    required DesignReview review,
    required List<WorkspaceData> workspaces,
    required Map<String, Uint8List> workspaceImages,
    required Map<String, String> workspaceAttachmentUrls,
  }) {
    final mfgReadinessStage = review.stages.firstWhere(
      (s) => s.name.trim().toLowerCase() == 'manufacturing readiness',
      orElse: () => Stage(id: '', name: 'Manufacturing Readiness', lastUpdated: DateTime.now()),
    );

    final widgets = <pw.Widget>[];
    final subSteps = mfgReadinessStage.subSteps;

    if (subSteps.isEmpty) {
      widgets.add(
        pw.Text(
          'No Manufacturing Readiness substeps found for this project.',
          style: pw.TextStyle(
            fontSize: 11.5,
            color: PdfColor.fromHex('#64748B'),
            fontStyle: pw.FontStyle.italic,
          ),
        ),
      );
      return widgets;
    }

    for (int i = 0; i < subSteps.length; i++) {
      final subStepEntity = subSteps[i];
      final name = subStepEntity.name;

      final wsData = workspaces.firstWhere(
        (w) => w.id == subStepEntity.workspaceId && subStepEntity.workspaceId.isNotEmpty,
        orElse: () => WorkspaceData(id: subStepEntity.workspaceId, checklistItem: name),
      );

      widgets.add(
        _buildSubStepCard(
          subStepNumber: i + 1,
          subStepName: name,
          wsData: wsData,
          workspaceImages: workspaceImages,
          workspaceAttachmentUrls: workspaceAttachmentUrls,
          projectStakeholders: review.stakeholders,
        ),
      );

      if (i < subSteps.length - 1) {
        widgets.add(pw.SizedBox(height: 10));
      }
    }

    return widgets;
  }

  static List<pw.Widget> _buildFinalReleaseSubSteps({
    required DesignReview review,
    required List<WorkspaceData> workspaces,
    required Map<String, Uint8List> workspaceImages,
    required Map<String, String> workspaceAttachmentUrls,
  }) {
    final finalReleaseStage = review.stages.firstWhere(
      (s) => s.name.trim().toLowerCase() == 'final release',
      orElse: () => Stage(id: '', name: 'Final Release', lastUpdated: DateTime.now()),
    );

    final widgets = <pw.Widget>[];
    final subSteps = finalReleaseStage.subSteps;

    if (subSteps.isEmpty) {
      widgets.add(
        pw.Text(
          'No Final Release substeps found for this project.',
          style: pw.TextStyle(
            fontSize: 11.5,
            color: PdfColor.fromHex('#64748B'),
            fontStyle: pw.FontStyle.italic,
          ),
        ),
      );
      return widgets;
    }

    for (int i = 0; i < subSteps.length; i++) {
      final subStepEntity = subSteps[i];
      final name = subStepEntity.name;

      final wsData = workspaces.firstWhere(
        (w) => w.id == subStepEntity.workspaceId && subStepEntity.workspaceId.isNotEmpty,
        orElse: () => WorkspaceData(id: subStepEntity.workspaceId, checklistItem: name),
      );

      widgets.add(
        _buildSubStepCard(
          subStepNumber: i + 1,
          subStepName: name,
          wsData: wsData,
          workspaceImages: workspaceImages,
          workspaceAttachmentUrls: workspaceAttachmentUrls,
          projectStakeholders: review.stakeholders,
        ),
      );

      if (i < subSteps.length - 1) {
        widgets.add(pw.SizedBox(height: 10));
      }
    }

    return widgets;
  }

  static List<pw.Widget> _buildContinuousImprovementSubSteps({
    required DesignReview review,
    required List<WorkspaceData> workspaces,
    required Map<String, Uint8List> workspaceImages,
    required Map<String, String> workspaceAttachmentUrls,
  }) {
    final continuousImprovementStage = review.stages.firstWhere(
      (s) => s.name.trim().toLowerCase() == 'continuous improvement',
      orElse: () => Stage(id: '', name: 'Continuous Improvement', lastUpdated: DateTime.now()),
    );

    final widgets = <pw.Widget>[];
    final subSteps = continuousImprovementStage.subSteps;

    if (subSteps.isEmpty) {
      widgets.add(
        pw.Text(
          'No Continuous Improvement substeps found for this project.',
          style: pw.TextStyle(
            fontSize: 11.5,
            color: PdfColor.fromHex('#64748B'),
            fontStyle: pw.FontStyle.italic,
          ),
        ),
      );
      return widgets;
    }

    for (int i = 0; i < subSteps.length; i++) {
      final subStepEntity = subSteps[i];
      final name = subStepEntity.name;

      final wsData = workspaces.firstWhere(
        (w) => w.id == subStepEntity.workspaceId && subStepEntity.workspaceId.isNotEmpty,
        orElse: () => WorkspaceData(id: subStepEntity.workspaceId, checklistItem: name),
      );

      widgets.add(
        _buildSubStepCard(
          subStepNumber: i + 1,
          subStepName: name,
          wsData: wsData,
          workspaceImages: workspaceImages,
          workspaceAttachmentUrls: workspaceAttachmentUrls,
          projectStakeholders: review.stakeholders,
        ),
      );

      if (i < subSteps.length - 1) {
        widgets.add(pw.SizedBox(height: 10));
      }
    }

    return widgets;
  }

  static pw.Widget _buildSubStepCard({
    required int subStepNumber,
    required String subStepName,
    required WorkspaceData wsData,
    required Map<String, Uint8List> workspaceImages,
    required Map<String, String> workspaceAttachmentUrls,
    required List<Stakeholder> projectStakeholders,
  }) {
    return pw.Container(
      decoration: pw.BoxDecoration(
        color: PdfColor.fromHex('#FFFFFF'),
        border: pw.Border.all(
          color: PdfColor.fromHex('#E2E8F0'),
          width: 1,
        ),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // Substep Header Bar
          pw.Container(
            width: double.infinity,
            padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: pw.BoxDecoration(
              color: PdfColor.fromHex('#F1F5F9'),
              borderRadius: const pw.BorderRadius.only(
                topLeft: pw.Radius.circular(7),
                topRight: pw.Radius.circular(7),
              ),
            ),
            child: pw.Text(
              '$subStepNumber. $subStepName',
              style: pw.TextStyle(
                fontSize: 11,
                fontWeight: pw.FontWeight.bold,
                color: PdfColor.fromHex('#0F172A'),
              ),
            ),
          ),
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                _buildFieldDescription(subStepName, wsData),
                pw.SizedBox(height: 7),
                _buildFieldNotes(wsData),
                pw.SizedBox(height: 7),
                _buildFieldEvidence(wsData, workspaceImages, workspaceAttachmentUrls),
                pw.SizedBox(height: 7),
                _buildFieldActionDescription(wsData),
                pw.SizedBox(height: 7),
                _buildFieldResponsiblePerson(subStepName, wsData, projectStakeholders),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildFieldHeader(String title) {
    return pw.Text(
      title,
      style: pw.TextStyle(
        fontSize: 10,
        fontWeight: pw.FontWeight.bold,
        color: PdfColor.fromHex('#005CFF'),
      ),
    );
  }

  // a. Description
  static pw.Widget _buildFieldDescription(String subStepName, WorkspaceData wsData) {
    String desc = wsData.itemDescription.trim();
    if (desc.isEmpty) {
      for (final stageContent in defaultStageContent.values) {
        final defaultInfo = stageContent.subSteps[subStepName];
        if (defaultInfo != null) {
          desc = defaultInfo.description.trim();
          break;
        }
      }
    }
    final isNone = desc.isEmpty;
    final textContent = isNone ? 'No description provided.' : desc;

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildFieldHeader('a. Description'),
        pw.SizedBox(height: 4),
        pw.Text(
          textContent,
          style: pw.TextStyle(
            fontSize: 9.5,
            color: isNone ? PdfColor.fromHex('#64748B') : PdfColor.fromHex('#334155'),
            fontStyle: isNone ? pw.FontStyle.italic : pw.FontStyle.normal,
            height: 1.3,
          ),
        ),
      ],
    );
  }

  // b. Notes
  static pw.Widget _buildFieldNotes(WorkspaceData wsData) {
    final noteItems = <pw.Widget>[];

    if (wsData.notes.trim().isNotEmpty) {
      noteItems.add(
        pw.Text(
          wsData.notes.trim(),
          style: pw.TextStyle(
            fontSize: 9.5,
            color: PdfColor.fromHex('#334155'),
            height: 1.3,
          ),
        ),
      );
    }

    if (wsData.engineeringComments.trim().isNotEmpty) {
      if (noteItems.isNotEmpty) noteItems.add(pw.SizedBox(height: 4));
      noteItems.add(
        pw.Text(
          'Engineering Comments: ${wsData.engineeringComments.trim()}',
          style: pw.TextStyle(
            fontSize: 9.5,
            color: PdfColor.fromHex('#334155'),
            height: 1.3,
          ),
        ),
      );
    }

    for (final comment in wsData.comments) {
      if (noteItems.isNotEmpty) noteItems.add(pw.SizedBox(height: 4));
      final authorStr = comment.author.trim().isEmpty ? 'Author' : comment.author.trim();
      final dateStr = DateFormat('dd MMM yyyy HH:mm').format(comment.createdAt);
      noteItems.add(
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: [
            pw.Text(
              comment.content.trim(),
              style: pw.TextStyle(
                fontSize: 9.5,
                color: PdfColor.fromHex('#334155'),
                height: 1.3,
              ),
            ),
            pw.SizedBox(height: 2),
            pw.Text(
              '- $authorStr on $dateStr',
              style: pw.TextStyle(
                fontSize: 8.5,
                color: PdfColor.fromHex('#64748B'),
                fontStyle: pw.FontStyle.italic,
              ),
            ),
          ],
        ),
      );
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildFieldHeader('b. Notes'),
        pw.SizedBox(height: 4),
        if (noteItems.isEmpty)
          pw.Text(
            'No notes available.',
            style: pw.TextStyle(
              fontSize: 9.5,
              color: PdfColor.fromHex('#64748B'),
              fontStyle: pw.FontStyle.italic,
            ),
          )
        else
          pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: noteItems,
          ),
      ],
    );
  }

  // c. Evidence
  static pw.Widget _buildFieldEvidence(
    WorkspaceData wsData,
    Map<String, Uint8List> workspaceImages,
    Map<String, String> workspaceAttachmentUrls,
  ) {
    final allEvidenceRefs = {
      ...wsData.attachments,
      ...wsData.images,
      ...wsData.documents,
    }.toList();

    if (allEvidenceRefs.isEmpty) {
      return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _buildFieldHeader('c. Evidence'),
          pw.SizedBox(height: 4),
          pw.Text(
            'No evidence uploaded.',
            style: pw.TextStyle(
              fontSize: 9.5,
              color: PdfColor.fromHex('#64748B'),
              fontStyle: pw.FontStyle.italic,
            ),
          ),
        ],
      );
    }

    final items = <pw.Widget>[];

    for (final ref in allEvidenceRefs) {
      final fileName = SupabaseStorage.attachmentDisplayName(ref);
      final bytes = workspaceImages[ref];
      final lower = ref.toLowerCase();
      final isImageFile = lower.endsWith('.png') ||
          lower.endsWith('.jpg') ||
          lower.endsWith('.jpeg') ||
          lower.endsWith('.webp') ||
          lower.endsWith('.gif');
      final rawUrl = workspaceAttachmentUrls[ref];
      final url = (rawUrl != null &&
              (rawUrl.startsWith('http://') || rawUrl.startsWith('https://')))
          ? rawUrl
          : null;

      if (bytes != null && bytes.isNotEmpty && isImageFile) {
        final widget = pw.Container(
          margin: const pw.EdgeInsets.symmetric(vertical: 4),
          padding: const pw.EdgeInsets.all(6),
          decoration: pw.BoxDecoration(
            color: PdfColor.fromHex('#F8FAFC'),
            border: pw.Border.all(color: PdfColor.fromHex('#E2E8F0')),
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Center(
                child: pw.Image(
                  pw.MemoryImage(bytes),
                  height: 95,
                  fit: pw.BoxFit.contain,
                ),
              ),
              pw.SizedBox(height: 4),
              pw.Text(
                'Image: $fileName',
                style: pw.TextStyle(
                  fontSize: 8.5,
                  color: url != null
                      ? PdfColor.fromHex('#2563EB')
                      : PdfColor.fromHex('#475569'),
                  decoration: url != null
                      ? pw.TextDecoration.underline
                      : pw.TextDecoration.none,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ],
          ),
        );

        items.add(
          url != null ? pw.UrlLink(destination: url, child: widget) : widget,
        );
      } else {
        final typeLabel = _getFileTypeLabel(fileName);

        final widget = pw.Container(
          margin: const pw.EdgeInsets.only(top: 3, bottom: 3),
          padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: pw.BoxDecoration(
            color: PdfColor.fromHex('#F8FAFC'),
            border: pw.Border.all(color: PdfColor.fromHex('#E2E8F0')),
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
          ),
          child: pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Expanded(
                child: pw.Text(
                  fileName,
                  style: pw.TextStyle(
                    fontSize: 9,
                    fontWeight: pw.FontWeight.bold,
                    color: url != null
                        ? PdfColor.fromHex('#2563EB')
                        : PdfColor.fromHex('#0F172A'),
                    decoration: url != null
                        ? pw.TextDecoration.underline
                        : pw.TextDecoration.none,
                  ),
                ),
              ),
              pw.SizedBox(width: 8),
              pw.Text(
                url != null ? typeLabel : 'File unavailable',
                style: pw.TextStyle(
                  fontSize: 8.5,
                  color: url != null
                      ? PdfColor.fromHex('#005CFF')
                      : PdfColor.fromHex('#EF4444'),
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
            ],
          ),
        );

        items.add(
          url != null ? pw.UrlLink(destination: url, child: widget) : widget,
        );
      }
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildFieldHeader('c. Evidence'),
        pw.SizedBox(height: 4),
        pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.start,
          children: items,
        ),
      ],
    );
  }

  static String _getFileTypeLabel(String filename) {
    final ext = filename.split('.').last.toLowerCase();
    return switch (ext) {
      'pdf' => 'PDF Document',
      'dwg' || 'dxf' || 'step' || 'stp' || 'iges' || 'igs' || 'sldprt' => 'CAD File (.${ext.toUpperCase()})',
      'doc' || 'docx' => 'Word Document',
      'xls' || 'xlsx' || 'csv' => 'Excel Spreadsheet',
      'ppt' || 'pptx' => 'Presentation',
      'png' || 'jpg' || 'jpeg' || 'webp' || 'gif' => 'Image (${ext.toUpperCase()})',
      _ => 'Document (.$ext)',
    };
  }

  // d. Action Description
  static pw.Widget _buildFieldActionDescription(WorkspaceData wsData) {
    final actionText = wsData.actionDescription.trim();
    if (actionText.isEmpty) {
      return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _buildFieldHeader('d. Action Description'),
          pw.SizedBox(height: 4),
          pw.Text(
            'No actions recorded.',
            style: pw.TextStyle(
              fontSize: 9.5,
              color: PdfColor.fromHex('#64748B'),
              fontStyle: pw.FontStyle.italic,
            ),
          ),
        ],
      );
    }

    final metaDetails = <String>[];
    if (wsData.priority.trim().isNotEmpty) {
      metaDetails.add('Priority: ${wsData.priority.trim()}');
    }
    if (wsData.assignee.trim().isNotEmpty) {
      metaDetails.add('Assigned: ${wsData.assignee.trim()}');
    }
    if (wsData.dueDate != null) {
      metaDetails.add('Due: ${DateFormat('dd MMM yyyy').format(wsData.dueDate!)}');
    }
    if (wsData.approvalStatus != ApprovalStatus.pending) {
      metaDetails.add('Status: ${wsData.approvalStatus.name}');
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildFieldHeader('d. Action Description'),
        pw.SizedBox(height: 4),
        pw.Text(
          actionText,
          style: pw.TextStyle(
            fontSize: 9.5,
            color: PdfColor.fromHex('#334155'),
            height: 1.3,
          ),
        ),
        if (metaDetails.isNotEmpty) ...[
          pw.SizedBox(height: 3),
          pw.Text(
            metaDetails.join(' | '),
            style: pw.TextStyle(
              fontSize: 8.5,
              color: PdfColor.fromHex('#64748B'),
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ],
      ],
    );
  }

  // e. Responsible Person & Discipline
  static pw.Widget _buildFieldResponsiblePerson(
    String subStepName,
    WorkspaceData wsData,
    List<Stakeholder> projectStakeholders,
  ) {
    String person = wsData.assignee.trim();
    String discipline = wsData.discipline.trim();

    if (person.isEmpty) {
      final defaultInfo = defaultStageContent['Requirements']?.subSteps[subStepName];
      final targetDiscipline = discipline.isNotEmpty
          ? discipline
          : (defaultInfo?.discipline ?? '');

      final matched = projectStakeholders.firstWhere(
        (s) => s.role.trim().toLowerCase() == targetDiscipline.toLowerCase() && s.name.trim().isNotEmpty,
        orElse: () => const Stakeholder(id: '', name: '', role: ''),
      );

      if (matched.name.trim().isNotEmpty) {
        person = matched.name.trim();
        discipline = matched.role.trim();
      }
    }

    if (person.isEmpty) {
      return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          _buildFieldHeader('e. Responsible Person'),
          pw.SizedBox(height: 4),
          pw.Text(
            'No responsible person assigned.',
            style: pw.TextStyle(
              fontSize: 9.5,
              color: PdfColor.fromHex('#64748B'),
              fontStyle: pw.FontStyle.italic,
            ),
          ),
        ],
      );
    }

    final finalDiscipline = discipline.isEmpty ? 'General Engineering' : discipline;

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _buildFieldHeader('e. Responsible Person'),
        pw.SizedBox(height: 4),
        pw.Text(
          'Responsible Person: $person',
          style: pw.TextStyle(
            fontSize: 9.5,
            fontWeight: pw.FontWeight.bold,
            color: PdfColor.fromHex('#0F172A'),
          ),
        ),
        pw.SizedBox(height: 1),
        pw.Text(
          'Discipline: $finalDiscipline',
          style: pw.TextStyle(
            fontSize: 9.5,
            color: PdfColor.fromHex('#475569'),
          ),
        ),
      ],
    );
  }
}
