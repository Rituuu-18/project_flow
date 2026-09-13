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
    // PAGES 3+: Comprehensive Design Review Stages (Steps 1 to 10)
    // Unified MultiPage flow for continuous page numbering and optimal spacing
    // ==========================================
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 40, vertical: 34),
        header: (context) => _buildHeader(logoBytes),
        footer: (context) => _buildFooter(context.pageNumber + 2, context.pagesCount + 2),
        build: (context) {
          final stagesConfig = <({
            String title,
            int stepNum,
            List<pw.Widget> Function() buildSubSteps,
          })>[
            (
              title: 'Design Review Step 1 - Requirements',
              stepNum: 1,
              buildSubSteps: () => _buildRequirementsSubSteps(
                review: review,
                workspaces: workspaces,
                workspaceImages: workspaceImages,
                workspaceAttachmentUrls: pdfData.workspaceAttachmentUrls,
              ),
            ),
            (
              title: 'Design Review Step 2 - Concept',
              stepNum: 2,
              buildSubSteps: () => _buildConceptSubSteps(
                review: review,
                workspaces: workspaces,
                workspaceImages: workspaceImages,
                workspaceAttachmentUrls: pdfData.workspaceAttachmentUrls,
              ),
            ),
            (
              title: 'Design Review Step 3 - Preliminary Design',
              stepNum: 3,
              buildSubSteps: () => _buildPreliminaryDesignSubSteps(
                review: review,
                workspaces: workspaces,
                workspaceImages: workspaceImages,
                workspaceAttachmentUrls: pdfData.workspaceAttachmentUrls,
              ),
            ),
            (
              title: 'Design Review Step 4 - Detailed Design',
              stepNum: 4,
              buildSubSteps: () => _buildDetailedDesignSubSteps(
                review: review,
                workspaces: workspaces,
                workspaceImages: workspaceImages,
                workspaceAttachmentUrls: pdfData.workspaceAttachmentUrls,
              ),
            ),
            (
              title: 'Design Review Step 5 - Simulation (FEA, CFD...)',
              stepNum: 5,
              buildSubSteps: () => _buildSimulationSubSteps(
                review: review,
                workspaces: workspaces,
                workspaceImages: workspaceImages,
                workspaceAttachmentUrls: pdfData.workspaceAttachmentUrls,
              ),
            ),
            (
              title: 'Design Review Step 6 - Prototype',
              stepNum: 6,
              buildSubSteps: () => _buildPrototypeSubSteps(
                review: review,
                workspaces: workspaces,
                workspaceImages: workspaceImages,
                workspaceAttachmentUrls: pdfData.workspaceAttachmentUrls,
              ),
            ),
            (
              title: 'Design Review Step 7 - Testing Validation',
              stepNum: 7,
              buildSubSteps: () => _buildTestingValidationSubSteps(
                review: review,
                workspaces: workspaces,
                workspaceImages: workspaceImages,
                workspaceAttachmentUrls: pdfData.workspaceAttachmentUrls,
              ),
            ),
            (
              title: 'Design Review Step 8 - Manufacturing Readiness',
              stepNum: 8,
              buildSubSteps: () => _buildManufacturingReadinessSubSteps(
                review: review,
                workspaces: workspaces,
                workspaceImages: workspaceImages,
                workspaceAttachmentUrls: pdfData.workspaceAttachmentUrls,
              ),
            ),
            (
              title: 'Design Review Step 9 - Final Release',
              stepNum: 9,
              buildSubSteps: () => _buildFinalReleaseSubSteps(
                review: review,
                workspaces: workspaces,
                workspaceImages: workspaceImages,
                workspaceAttachmentUrls: pdfData.workspaceAttachmentUrls,
              ),
            ),
            (
              title: 'Design Review Step 10 - Continuous Improvement',
              stepNum: 10,
              buildSubSteps: () => _buildContinuousImprovementSubSteps(
                review: review,
                workspaces: workspaces,
                workspaceImages: workspaceImages,
                workspaceAttachmentUrls: pdfData.workspaceAttachmentUrls,
              ),
            ),
          ];

          final allWidgets = <pw.Widget>[];

          for (int i = 0; i < stagesConfig.length; i++) {
            final stageItem = stagesConfig[i];
            final subStepWidgets = stageItem.buildSubSteps();

            // Inter-stage vertical rhythm
            if (i > 0) {
              allWidgets.add(pw.SizedBox(height: 18));
            }

            // Prevent orphan section header: bind header with first substep if available
            if (subStepWidgets.isNotEmpty) {
              allWidgets.add(
                pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader(stageItem.title, stageNumber: stageItem.stepNum),
                    pw.SizedBox(height: 10),
                    subStepWidgets.first,
                  ],
                ),
              );
              for (int j = 1; j < subStepWidgets.length; j++) {
                allWidgets.add(pw.SizedBox(height: 10));
                allWidgets.add(subStepWidgets[j]);
              }
            } else {
              allWidgets.add(_buildSectionHeader(stageItem.title, stageNumber: stageItem.stepNum));
            }
          }

          return allWidgets;
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

  // ── Section Header ──────────────────────────────────────────────────────────
  static pw.Widget _buildSectionHeader(String title, {int? stageNumber}) {
    String stepLabel = stageNumber != null
        ? 'STAGE ${stageNumber.toString().padLeft(2, '0')}'
        : 'STAGE';
    String mainTitle = title;

    if (title.contains('-')) {
      final parts = title.split('-');
      mainTitle = parts.last.trim();
    } else if (title.contains('—')) {
      final parts = title.split('—');
      mainTitle = parts.last.trim();
    }

    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: pw.BoxDecoration(
        color: PdfColor.fromHex('#0F172A'),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
        border: pw.Border.all(color: PdfColor.fromHex('#1E293B'), width: 1),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Row(
            children: [
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: const pw.BoxDecoration(
                  color: PdfColor.fromInt(0xFF2563EB),
                  borderRadius: pw.BorderRadius.all(pw.Radius.circular(4)),
                ),
                child: pw.Text(
                  stepLabel,
                  style: pw.TextStyle(
                    fontSize: 8.5,
                    fontWeight: pw.FontWeight.bold,
                    color: PdfColors.white,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              pw.SizedBox(width: 10),
              pw.Text(
                mainTitle,
                style: pw.TextStyle(
                  fontSize: 12.5,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColors.white,
                ),
              ),
            ],
          ),
          pw.Text(
            'Stage Gate Checklist',
            style: pw.TextStyle(
              fontSize: 8.5,
              color: PdfColor.fromHex('#94A3B8'),
              fontWeight: pw.FontWeight.bold,
            ),
          ),
        ],
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
          status: subStepEntity.status,
        ),
      );
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
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: pw.BoxDecoration(
            color: PdfColor.fromHex('#F8FAFC'),
            border: pw.Border.all(color: PdfColor.fromHex('#E2E8F0'), width: 0.8),
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
          ),
          child: pw.Text(
            'No Concept substeps recorded for this project.',
            style: pw.TextStyle(
              fontSize: 9.5,
              color: PdfColor.fromHex('#64748B'),
              fontStyle: pw.FontStyle.italic,
            ),
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
          status: subStepEntity.status,
        ),
      );
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
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: pw.BoxDecoration(
            color: PdfColor.fromHex('#F8FAFC'),
            border: pw.Border.all(color: PdfColor.fromHex('#E2E8F0'), width: 0.8),
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
          ),
          child: pw.Text(
            'No Preliminary Design substeps recorded for this project.',
            style: pw.TextStyle(
              fontSize: 9.5,
              color: PdfColor.fromHex('#64748B'),
              fontStyle: pw.FontStyle.italic,
            ),
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
          status: subStepEntity.status,
        ),
      );
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
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: pw.BoxDecoration(
            color: PdfColor.fromHex('#F8FAFC'),
            border: pw.Border.all(color: PdfColor.fromHex('#E2E8F0'), width: 0.8),
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
          ),
          child: pw.Text(
            'No Detailed Design substeps recorded for this project.',
            style: pw.TextStyle(
              fontSize: 9.5,
              color: PdfColor.fromHex('#64748B'),
              fontStyle: pw.FontStyle.italic,
            ),
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
          status: subStepEntity.status,
        ),
      );
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
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: pw.BoxDecoration(
            color: PdfColor.fromHex('#F8FAFC'),
            border: pw.Border.all(color: PdfColor.fromHex('#E2E8F0'), width: 0.8),
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
          ),
          child: pw.Text(
            'No Simulation substeps recorded for this project.',
            style: pw.TextStyle(
              fontSize: 9.5,
              color: PdfColor.fromHex('#64748B'),
              fontStyle: pw.FontStyle.italic,
            ),
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
          status: subStepEntity.status,
        ),
      );
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
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: pw.BoxDecoration(
            color: PdfColor.fromHex('#F8FAFC'),
            border: pw.Border.all(color: PdfColor.fromHex('#E2E8F0'), width: 0.8),
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
          ),
          child: pw.Text(
            'No Prototype substeps recorded for this project.',
            style: pw.TextStyle(
              fontSize: 9.5,
              color: PdfColor.fromHex('#64748B'),
              fontStyle: pw.FontStyle.italic,
            ),
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
          status: subStepEntity.status,
        ),
      );
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
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: pw.BoxDecoration(
            color: PdfColor.fromHex('#F8FAFC'),
            border: pw.Border.all(color: PdfColor.fromHex('#E2E8F0'), width: 0.8),
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
          ),
          child: pw.Text(
            'No Testing Validation substeps recorded for this project.',
            style: pw.TextStyle(
              fontSize: 9.5,
              color: PdfColor.fromHex('#64748B'),
              fontStyle: pw.FontStyle.italic,
            ),
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
          status: subStepEntity.status,
        ),
      );
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
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: pw.BoxDecoration(
            color: PdfColor.fromHex('#F8FAFC'),
            border: pw.Border.all(color: PdfColor.fromHex('#E2E8F0'), width: 0.8),
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
          ),
          child: pw.Text(
            'No Manufacturing Readiness substeps recorded for this project.',
            style: pw.TextStyle(
              fontSize: 9.5,
              color: PdfColor.fromHex('#64748B'),
              fontStyle: pw.FontStyle.italic,
            ),
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
          status: subStepEntity.status,
        ),
      );
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
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: pw.BoxDecoration(
            color: PdfColor.fromHex('#F8FAFC'),
            border: pw.Border.all(color: PdfColor.fromHex('#E2E8F0'), width: 0.8),
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
          ),
          child: pw.Text(
            'No Final Release substeps recorded for this project.',
            style: pw.TextStyle(
              fontSize: 9.5,
              color: PdfColor.fromHex('#64748B'),
              fontStyle: pw.FontStyle.italic,
            ),
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
          status: subStepEntity.status,
        ),
      );
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
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: pw.BoxDecoration(
            color: PdfColor.fromHex('#F8FAFC'),
            border: pw.Border.all(color: PdfColor.fromHex('#E2E8F0'), width: 0.8),
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
          ),
          child: pw.Text(
            'No Continuous Improvement substeps recorded for this project.',
            style: pw.TextStyle(
              fontSize: 9.5,
              color: PdfColor.fromHex('#64748B'),
              fontStyle: pw.FontStyle.italic,
            ),
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
          status: subStepEntity.status,
        ),
      );
    }

    return widgets;
  }

  // ── Executive Sub-Step Card ─────────────────────────────────────────────────
  static pw.Widget _buildSubStepCard({
    required int subStepNumber,
    required String subStepName,
    required WorkspaceData wsData,
    required Map<String, Uint8List> workspaceImages,
    required Map<String, String> workspaceAttachmentUrls,
    required List<Stakeholder> projectStakeholders,
    StageStatus status = StageStatus.notStarted,
  }) {
    // 1. Resolve Lead and Discipline
    String person = wsData.assignee.trim();
    String discipline = wsData.discipline.trim();

    for (final stageContent in defaultStageContent.values) {
      final defaultInfo = stageContent.subSteps[subStepName];
      if (defaultInfo != null) {
        if (discipline.isEmpty && defaultInfo.discipline.trim().isNotEmpty) {
          discipline = defaultInfo.discipline.trim();
        }
        break;
      }
    }

    if (person.isEmpty && discipline.isNotEmpty) {
      final matched = projectStakeholders.firstWhere(
        (s) =>
            s.role.trim().toLowerCase() == discipline.toLowerCase() &&
            s.name.trim().isNotEmpty,
        orElse: () => const Stakeholder(id: '', name: '', role: ''),
      );
      if (matched.name.trim().isNotEmpty) {
        person = matched.name.trim();
      }
    }

    final isCompleted = status == StageStatus.completed ||
        wsData.approvalStatus == ApprovalStatus.approved;

    final (statusBg, statusFg, statusBorder, statusText) = switch (status) {
      StageStatus.completed => (
        PdfColor.fromHex('#ECFDF5'),
        PdfColor.fromHex('#047857'),
        PdfColor.fromHex('#A7F3D0'),
        'COMPLETED',
      ),
      StageStatus.inProgress => (
        PdfColor.fromHex('#EFF6FF'),
        PdfColor.fromHex('#1D4ED8'),
        PdfColor.fromHex('#BFDBFE'),
        'IN PROGRESS',
      ),
      StageStatus.notRequired => (
        PdfColor.fromHex('#F1F5F9'),
        PdfColor.fromHex('#64748B'),
        PdfColor.fromHex('#CBD5E1'),
        'NOT REQUIRED',
      ),
      StageStatus.notStarted => (
        PdfColor.fromHex('#F8FAFC'),
        PdfColor.fromHex('#64748B'),
        PdfColor.fromHex('#E2E8F0'),
        'OPEN',
      ),
    };

    // Sub-widgets
    final notesWidget = _buildFieldNotes(wsData);
    final evidenceWidget = _buildFieldEvidence(
      wsData,
      workspaceImages,
      workspaceAttachmentUrls,
    );
    final actionWidget = _buildFieldActionDescription(wsData);

    return pw.Container(
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        border: pw.Border.all(
          color: isCompleted
              ? PdfColor.fromHex('#CBD5E1')
              : PdfColor.fromHex('#E2E8F0'),
          width: 0.9,
        ),
        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          // ── Header Bar ──────────────────────────────
          pw.Container(
            padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: const pw.BoxDecoration(
              color: PdfColor.fromInt(0xFFF8FAFC),
              border: pw.Border(
                bottom: pw.BorderSide(color: PdfColor.fromInt(0xFFE2E8F0), width: 0.8),
              ),
            ),
            child: pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Row(
                  children: [
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                      decoration: pw.BoxDecoration(
                        color: isCompleted
                            ? PdfColor.fromHex('#059669')
                            : PdfColor.fromHex('#0F172A'),
                        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(3)),
                      ),
                      child: pw.Text(
                        subStepNumber.toString().padLeft(2, '0'),
                        style: pw.TextStyle(
                          fontSize: 8,
                          fontWeight: pw.FontWeight.bold,
                          color: PdfColors.white,
                        ),
                      ),
                    ),
                    pw.SizedBox(width: 8),
                    pw.Text(
                      subStepName,
                      style: pw.TextStyle(
                        fontSize: 9.5,
                        fontWeight: pw.FontWeight.bold,
                        color: PdfColor.fromHex('#0F172A'),
                      ),
                    ),
                  ],
                ),
                pw.Row(
                  children: [
                    if (discipline.isNotEmpty) ...[
                      pw.Container(
                        padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                        decoration: pw.BoxDecoration(
                          color: PdfColor.fromHex('#F1F5F9'),
                          border: pw.Border.all(color: PdfColor.fromHex('#E2E8F0'), width: 0.7),
                          borderRadius: const pw.BorderRadius.all(pw.Radius.circular(3)),
                        ),
                        child: pw.Text(
                          discipline,
                          style: pw.TextStyle(
                            fontSize: 7,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColor.fromHex('#475569'),
                          ),
                        ),
                      ),
                      pw.SizedBox(width: 5),
                    ],
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: pw.BoxDecoration(
                        color: statusBg,
                        border: pw.Border.all(color: statusBorder, width: 0.7),
                        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(3)),
                      ),
                      child: pw.Text(
                        statusText,
                        style: pw.TextStyle(
                          fontSize: 7,
                          fontWeight: pw.FontWeight.bold,
                          color: statusFg,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── Lead meta bar (if lead is known) ────────
          if (person.isNotEmpty)
            pw.Container(
              padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 3),
              color: PdfColor.fromHex('#FAFAFA'),
              child: pw.Row(
                children: [
                  pw.Text(
                    'Lead: ',
                    style: pw.TextStyle(
                      fontSize: 7.5,
                      color: PdfColor.fromHex('#64748B'),
                    ),
                  ),
                  pw.Text(
                    person,
                    style: pw.TextStyle(
                      fontSize: 7.5,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColor.fromHex('#334155'),
                    ),
                  ),
                ],
              ),
            ),

          // ── Card Body ────────────────────────────────
          pw.Padding(
            padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Description (Scope & Objectives)
                _buildFieldDescription(subStepName, wsData),

                // Formatted Notes (if non-empty)
                if (notesWidget != null) ...[
                  pw.SizedBox(height: 7),
                  notesWidget,
                ],

                // Evidence (if non-empty)
                if (evidenceWidget != null) ...[
                  pw.SizedBox(height: 7),
                  evidenceWidget,
                ],

                // Action Item (if non-empty)
                if (actionWidget != null) ...[
                  pw.SizedBox(height: 7),
                  actionWidget,
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Scope & Objective Callout ───────────────────────────────────────────────
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

    final displayText = desc.isNotEmpty
        ? desc
        : 'Objective and scope validation item as specified in engineering design baseline.';

    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: const pw.BoxDecoration(
        color: PdfColor.fromInt(0xFFF8FAFC),
        border: pw.Border(
          left: pw.BorderSide(color: PdfColor.fromInt(0xFF2563EB), width: 2.2),
          top: pw.BorderSide(color: PdfColor.fromInt(0xFFE2E8F0), width: 0.7),
          right: pw.BorderSide(color: PdfColor.fromInt(0xFFE2E8F0), width: 0.7),
          bottom: pw.BorderSide(color: PdfColor.fromInt(0xFFE2E8F0), width: 0.7),
        ),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            'SCOPE & OBJECTIVE',
            style: pw.TextStyle(
              fontSize: 7,
              fontWeight: pw.FontWeight.bold,
              color: PdfColor.fromHex('#2563EB'),
              letterSpacing: 0.4,
            ),
          ),
          pw.SizedBox(height: 2),
          pw.Text(
            displayText,
            style: pw.TextStyle(
              fontSize: 8.5,
              color: PdfColor.fromHex('#334155'),
              height: 1.25,
            ),
          ),
        ],
      ),
    );
  }

  // ── Notes, Comments & Observations (returns null if empty) ──────────────────
  static pw.Widget? _buildFieldNotes(WorkspaceData wsData) {
    final hasNotes = wsData.notes.trim().isNotEmpty;
    final hasEngComments = wsData.engineeringComments.trim().isNotEmpty;
    final hasComments = wsData.comments.isNotEmpty;

    if (!hasNotes && !hasEngComments && !hasComments) {
      return null;
    }

    final contentWidgets = <pw.Widget>[];

    if (hasNotes) {
      contentWidgets.addAll(_buildFormattedNotesContent(wsData.notes.trim()));
    }

    if (hasEngComments) {
      if (contentWidgets.isNotEmpty) contentWidgets.add(pw.SizedBox(height: 4));
      contentWidgets.add(
        pw.Container(
          width: double.infinity,
          padding: const pw.EdgeInsets.symmetric(horizontal: 7, vertical: 4),
          decoration: pw.BoxDecoration(
            color: PdfColor.fromHex('#F1F5F9'),
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(3)),
            border: pw.Border.all(color: PdfColor.fromHex('#E2E8F0'), width: 0.6),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Engineering Comments:',
                style: pw.TextStyle(
                  fontSize: 7.5,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColor.fromHex('#1E293B'),
                ),
              ),
              pw.SizedBox(height: 1),
              pw.Text(
                wsData.engineeringComments.trim(),
                style: pw.TextStyle(
                  fontSize: 8,
                  color: PdfColor.fromHex('#334155'),
                  height: 1.25,
                ),
              ),
            ],
          ),
        ),
      );
    }

    for (final comment in wsData.comments) {
      if (contentWidgets.isNotEmpty) contentWidgets.add(pw.SizedBox(height: 3));
      final authorStr = comment.author.trim().isEmpty ? 'Author' : comment.author.trim();
      final dateStr = DateFormat('dd MMM yyyy HH:mm').format(comment.createdAt);
      contentWidgets.add(
        pw.Padding(
          padding: const pw.EdgeInsets.only(left: 4),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                comment.content.trim(),
                style: pw.TextStyle(
                  fontSize: 8,
                  color: PdfColor.fromHex('#334155'),
                  height: 1.25,
                ),
              ),
              pw.SizedBox(height: 1),
              pw.Text(
                '- $authorStr on $dateStr',
                style: pw.TextStyle(
                  fontSize: 7,
                  color: PdfColor.fromHex('#64748B'),
                  fontStyle: pw.FontStyle.italic,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
          decoration: pw.BoxDecoration(
            color: PdfColor.fromHex('#F1F5F9'),
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(3)),
          ),
          child: pw.Text(
            'NOTES & ENGINEERING OBSERVATIONS',
            style: pw.TextStyle(
              fontSize: 7,
              fontWeight: pw.FontWeight.bold,
              color: PdfColor.fromHex('#334155'),
              letterSpacing: 0.4,
            ),
          ),
        ),
        pw.SizedBox(height: 3),
        ...contentWidgets,
      ],
    );
  }

  // ── Smart Line Formatter for Groq AI & Engineer Notes ──────────────────────
  static List<pw.Widget> _buildFormattedNotesContent(String rawNotes) {
    final widgets = <pw.Widget>[];
    final lines = rawNotes.split('\n');

    for (final rawLine in lines) {
      final line = rawLine.trim();
      if (line.isEmpty) {
        widgets.add(pw.SizedBox(height: 2.5));
        continue;
      }

      // Heading detection: ### or ## or #
      if (line.startsWith('### ') || line.startsWith('## ') || line.startsWith('# ')) {
        final headingText = line.replaceFirst(RegExp(r'^#{1,3}\s*'), '');
        widgets.add(
          pw.Padding(
            padding: const pw.EdgeInsets.only(top: 3, bottom: 1.5),
            child: pw.Text(
              headingText,
              style: pw.TextStyle(
                fontSize: 8.5,
                fontWeight: pw.FontWeight.bold,
                color: PdfColor.fromHex('#1E293B'),
              ),
            ),
          ),
        );
        continue;
      }

      // Bullet detection: * or - or •
      if (line.startsWith('* ') || line.startsWith('- ') || line.startsWith('• ')) {
        final bulletText = line.substring(2).trim();
        widgets.add(
          pw.Padding(
            padding: const pw.EdgeInsets.only(left: 6, bottom: 2),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Container(
                  width: 3,
                  height: 3,
                  margin: const pw.EdgeInsets.only(top: 4, right: 5),
                  decoration: const pw.BoxDecoration(
                    color: PdfColor.fromInt(0xFF2563EB),
                    shape: pw.BoxShape.circle,
                  ),
                ),
                pw.Expanded(
                  child: pw.Text(
                    bulletText,
                    style: pw.TextStyle(
                      fontSize: 8,
                      color: PdfColor.fromHex('#334155'),
                      height: 1.25,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
        continue;
      }

      // Numbered list detection: 1. 2. etc.
      final numMatch = RegExp(r'^(\d+)\.\s+(.*)').firstMatch(line);
      if (numMatch != null) {
        final numStr = numMatch.group(1)!;
        final itemText = numMatch.group(2)!;
        widgets.add(
          pw.Padding(
            padding: const pw.EdgeInsets.only(left: 6, bottom: 2),
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.SizedBox(
                  width: 12,
                  child: pw.Text(
                    '$numStr.',
                    style: pw.TextStyle(
                      fontSize: 8,
                      fontWeight: pw.FontWeight.bold,
                      color: PdfColor.fromHex('#2563EB'),
                    ),
                  ),
                ),
                pw.Expanded(
                  child: pw.Text(
                    itemText,
                    style: pw.TextStyle(
                      fontSize: 8,
                      color: PdfColor.fromHex('#334155'),
                      height: 1.25,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
        continue;
      }

      // Normal text
      widgets.add(
        pw.Text(
          line,
          style: pw.TextStyle(
            fontSize: 8,
            color: PdfColor.fromHex('#334155'),
            height: 1.25,
          ),
        ),
      );
    }

    return widgets;
  }

  // ── Evidence & Attachments (returns null if empty) ─────────────────────────
  static pw.Widget? _buildFieldEvidence(
    WorkspaceData wsData,
    Map<String, Uint8List> workspaceImages,
    Map<String, String> workspaceAttachmentUrls,
  ) {
    final allEvidenceRefs = {
      ...wsData.attachments,
      ...wsData.images,
      ...wsData.documents,
    }.where((s) => s.trim().isNotEmpty).toList();

    if (allEvidenceRefs.isEmpty) {
      return null;
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
        final imgWidget = pw.Container(
          margin: const pw.EdgeInsets.only(top: 3, bottom: 3),
          padding: const pw.EdgeInsets.all(4),
          decoration: pw.BoxDecoration(
            color: PdfColor.fromHex('#F8FAFC'),
            border: pw.Border.all(color: PdfColor.fromHex('#CBD5E1'), width: 0.8),
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(4)),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Center(
                child: pw.Image(
                  pw.MemoryImage(bytes),
                  height: 90,
                  fit: pw.BoxFit.contain,
                ),
              ),
              pw.SizedBox(height: 2),
              pw.Text(
                fileName,
                style: pw.TextStyle(
                  fontSize: 7.5,
                  color: url != null ? PdfColor.fromHex('#2563EB') : PdfColor.fromHex('#475569'),
                  fontWeight: pw.FontWeight.bold,
                  decoration: url != null ? pw.TextDecoration.underline : pw.TextDecoration.none,
                ),
              ),
            ],
          ),
        );

        items.add(url != null ? pw.UrlLink(destination: url, child: imgWidget) : imgWidget);
      } else {
        final (chipBg, chipFg, chipLabel) = _getFileTypeBadge(fileName);

        final docWidget = pw.Container(
          margin: const pw.EdgeInsets.only(top: 2, bottom: 2),
          padding: const pw.EdgeInsets.symmetric(horizontal: 7, vertical: 3.5),
          decoration: pw.BoxDecoration(
            color: PdfColor.fromHex('#F8FAFC'),
            border: pw.Border.all(color: PdfColor.fromHex('#E2E8F0'), width: 0.7),
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(3)),
          ),
          child: pw.Row(
            children: [
              pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                decoration: pw.BoxDecoration(
                  color: chipBg,
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(2)),
                ),
                child: pw.Text(
                  chipLabel,
                  style: pw.TextStyle(
                    fontSize: 6.5,
                    fontWeight: pw.FontWeight.bold,
                    color: chipFg,
                  ),
                ),
              ),
              pw.SizedBox(width: 5),
              pw.Expanded(
                child: pw.Text(
                  fileName,
                  style: pw.TextStyle(
                    fontSize: 8,
                    fontWeight: pw.FontWeight.bold,
                    color: url != null ? PdfColor.fromHex('#2563EB') : PdfColor.fromHex('#0F172A'),
                    decoration: url != null ? pw.TextDecoration.underline : pw.TextDecoration.none,
                  ),
                ),
              ),
              if (url != null)
                pw.Text(
                  'View File >',
                  style: pw.TextStyle(
                    fontSize: 7,
                    color: PdfColor.fromHex('#2563EB'),
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
            ],
          ),
        );

        items.add(url != null ? pw.UrlLink(destination: url, child: docWidget) : docWidget);
      }
    }

    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Container(
          padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
          decoration: pw.BoxDecoration(
            color: PdfColor.fromHex('#EFF6FF'),
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(3)),
          ),
          child: pw.Text(
            'EVIDENCE & ATTACHMENTS (${allEvidenceRefs.length})',
            style: pw.TextStyle(
              fontSize: 7,
              fontWeight: pw.FontWeight.bold,
              color: PdfColor.fromHex('#1D4ED8'),
              letterSpacing: 0.4,
            ),
          ),
        ),
        pw.SizedBox(height: 3),
        ...items,
      ],
    );
  }

  static (PdfColor, PdfColor, String) _getFileTypeBadge(String filename) {
    final ext = filename.split('.').last.toLowerCase();
    return switch (ext) {
      'pdf' => (PdfColor.fromHex('#FEE2E2'), PdfColor.fromHex('#DC2626'), 'PDF'),
      'dwg' || 'dxf' || 'step' || 'stp' || 'iges' || 'igs' || 'sldprt' => (
        PdfColor.fromHex('#F3E8FF'),
        PdfColor.fromHex('#7E22CE'),
        'CAD',
      ),
      'doc' || 'docx' => (PdfColor.fromHex('#DBEAFE'), PdfColor.fromHex('#1D4ED8'), 'DOC'),
      'xls' || 'xlsx' || 'csv' => (PdfColor.fromHex('#DCFCE7'), PdfColor.fromHex('#15803D'), 'SHEET'),
      'ppt' || 'pptx' => (PdfColor.fromHex('#FFEDD5'), PdfColor.fromHex('#C2410C'), 'SLIDES'),
      'png' || 'jpg' || 'jpeg' || 'webp' => (PdfColor.fromHex('#E0E7FF'), PdfColor.fromHex('#4338CA'), 'IMG'),
      _ => (PdfColor.fromHex('#F1F5F9'), PdfColor.fromHex('#475569'), ext.toUpperCase()),
    };
  }

  // ── Action Item Callout (returns null if empty) ─────────────────────────────
  static pw.Widget? _buildFieldActionDescription(WorkspaceData wsData) {
    final actionText = wsData.actionDescription.trim();
    if (actionText.isEmpty) {
      return null;
    }

    final isHigh = wsData.priority.trim().toLowerCase() == 'high' ||
        wsData.priority.trim().toLowerCase() == 'critical';
    final isMed = wsData.priority.trim().toLowerCase() == 'medium';

    final badgeBg = isHigh
        ? PdfColor.fromHex('#FEF2F2')
        : (isMed ? PdfColor.fromHex('#FEF3C7') : PdfColor.fromHex('#F1F5F9'));
    final badgeFg = isHigh
        ? PdfColor.fromHex('#DC2626')
        : (isMed ? PdfColor.fromHex('#D97706') : PdfColor.fromHex('#475569'));

    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: const pw.BoxDecoration(
        color: PdfColor.fromInt(0xFFFFFBEB),
        border: pw.Border(
          left: pw.BorderSide(color: PdfColor.fromInt(0xFFF59E0B), width: 2.2),
          top: pw.BorderSide(color: PdfColor.fromInt(0xFFFDE68A), width: 0.7),
          right: pw.BorderSide(color: PdfColor.fromInt(0xFFFDE68A), width: 0.7),
          bottom: pw.BorderSide(color: PdfColor.fromInt(0xFFFDE68A), width: 0.7),
        ),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            children: [
              pw.Text(
                'ACTION ITEM',
                style: pw.TextStyle(
                  fontSize: 7,
                  fontWeight: pw.FontWeight.bold,
                  color: PdfColor.fromHex('#B45309'),
                  letterSpacing: 0.4,
                ),
              ),
              if (wsData.priority.trim().isNotEmpty) ...[
                pw.SizedBox(width: 5),
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                  decoration: pw.BoxDecoration(
                    color: badgeBg,
                    borderRadius: const pw.BorderRadius.all(pw.Radius.circular(2)),
                  ),
                  child: pw.Text(
                    wsData.priority.trim().toUpperCase(),
                    style: pw.TextStyle(
                      fontSize: 6.5,
                      fontWeight: pw.FontWeight.bold,
                      color: badgeFg,
                    ),
                  ),
                ),
              ],
              if (wsData.dueDate != null) ...[
                pw.SizedBox(width: 5),
                pw.Text(
                  'Due: ${DateFormat('dd MMM yyyy').format(wsData.dueDate!)}',
                  style: pw.TextStyle(
                    fontSize: 7,
                    color: PdfColor.fromHex('#78350F'),
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
              ],
              if (wsData.assignee.trim().isNotEmpty) ...[
                pw.Spacer(),
                pw.Text(
                  'Assignee: ${wsData.assignee.trim()}',
                  style: pw.TextStyle(
                    fontSize: 7,
                    color: PdfColor.fromHex('#78350F'),
                  ),
                ),
              ],
            ],
          ),
          pw.SizedBox(height: 2.5),
          pw.Text(
            actionText,
            style: pw.TextStyle(
              fontSize: 8,
              color: PdfColor.fromHex('#1E293B'),
              height: 1.25,
            ),
          ),
        ],
      ),
    );
  }
}
