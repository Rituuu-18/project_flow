import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/localization/locale_provider.dart';
import '../../../../core/utils/app_messenger.dart';
import '../../../../services/groq_service.dart';
import '../../../dashboard/presentation/theme/dashboard_design.dart';

class AIAnalysisSheet extends ConsumerStatefulWidget {
  final String projectName;
  final String? projectOwner;
  final String? projectStatus;
  final String stageName;
  final String? stageDescription;
  final String? subStepName;
  final String checklistItem;
  final String itemDescription;
  final String discipline;
  final String? priority;
  final String? assignee;
  final String? problemStatement;
  final List<String>? scopeIn;
  final List<String>? scopeOut;
  final String? engineeringComments;
  final String? actionDescription;
  final String existingNotes;
  final void Function(String text, bool append) onApplyNotes;

  const AIAnalysisSheet({
    super.key,
    required this.projectName,
    this.projectOwner,
    this.projectStatus,
    required this.stageName,
    this.stageDescription,
    this.subStepName,
    required this.checklistItem,
    required this.itemDescription,
    required this.discipline,
    this.priority,
    this.assignee,
    this.problemStatement,
    this.scopeIn,
    this.scopeOut,
    this.engineeringComments,
    this.actionDescription,
    required this.existingNotes,
    required this.onApplyNotes,
  });

  static Future<void> show(
    BuildContext context, {
    required String projectName,
    String? projectOwner,
    String? projectStatus,
    required String stageName,
    String? stageDescription,
    String? subStepName,
    required String checklistItem,
    required String itemDescription,
    required String discipline,
    String? priority,
    String? assignee,
    String? problemStatement,
    List<String>? scopeIn,
    List<String>? scopeOut,
    String? engineeringComments,
    String? actionDescription,
    required String existingNotes,
    required void Function(String text, bool append) onApplyNotes,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(ctx).viewInsets.bottom,
        ),
        child: FractionallySizedBox(
          heightFactor: 0.78,
          child: AIAnalysisSheet(
            projectName: projectName,
            projectOwner: projectOwner,
            projectStatus: projectStatus,
            stageName: stageName,
            stageDescription: stageDescription,
            subStepName: subStepName,
            checklistItem: checklistItem,
            itemDescription: itemDescription,
            discipline: discipline,
            priority: priority,
            assignee: assignee,
            problemStatement: problemStatement,
            scopeIn: scopeIn,
            scopeOut: scopeOut,
            engineeringComments: engineeringComments,
            actionDescription: actionDescription,
            existingNotes: existingNotes,
            onApplyNotes: onApplyNotes,
          ),
        ),
      ),
    );
  }

  @override
  ConsumerState<AIAnalysisSheet> createState() => _AIAnalysisSheetState();
}

class _AIAnalysisSheetState extends ConsumerState<AIAnalysisSheet> {
  bool _isLoading = false;
  String? _rawAnalysisResult;
  List<_AnalysisSection> _parsedSections = [];
  String? _errorMessage;
  bool _isMissingKey = false;
  int _viewModeIndex = 0; // 0: Formatted Cards, 1: Notes Preview

  String Function(String, [Map<String, String>?]) get t =>
      ref.read(localeProvider.notifier).t;

  String get _effectiveDescription {
    if (widget.itemDescription.trim().isNotEmpty) {
      return widget.itemDescription.trim();
    }
    if (widget.problemStatement != null &&
        widget.problemStatement!.trim().isNotEmpty) {
      return widget.problemStatement!.trim();
    }
    if (widget.stageDescription != null &&
        widget.stageDescription!.trim().isNotEmpty) {
      return widget.stageDescription!.trim();
    }
    return t('no_description_provided');
  }

  String get _effectiveProjectName {
    if (widget.projectName.trim().isNotEmpty) {
      return widget.projectName.trim();
    }
    return t('project_label');
  }

  Future<void> _startAnalysis() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _isMissingKey = false;
    });

    try {
      final result = await GroqService.analyzeSubStep(
        projectName: _effectiveProjectName,
        projectOwner: widget.projectOwner,
        projectStatus: widget.projectStatus,
        stageName: widget.stageName,
        stageDescription: widget.stageDescription,
        subStepName: widget.subStepName,
        checklistItem: widget.checklistItem,
        itemDescription: _effectiveDescription,
        discipline: widget.discipline,
        priority: widget.priority,
        assignee: widget.assignee,
        problemStatement: widget.problemStatement,
        scopeIn: widget.scopeIn,
        scopeOut: widget.scopeOut,
        engineeringComments: widget.engineeringComments,
        actionDescription: widget.actionDescription,
        existingNotes: widget.existingNotes,
      );

      if (!mounted) return;
      setState(() {
        _rawAnalysisResult = result;
        _parsedSections = _parseSections(result);
        _isLoading = false;
      });
    } on GroqException catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e.message;
        _isMissingKey = e.isMissingKey;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString();
      });
    }
  }

  /// Parses the raw AI response into cleanly structured sections with narrative and bullets.
  List<_AnalysisSection> _parseSections(String text) {
    final sections = <_AnalysisSection>[];
    final lines = text.split('\n');

    String currentTitle = '';
    final currentBullets = <_AnalysisBullet>[];
    final currentNarrative = StringBuffer();

    void commitCurrentSection() {
      final narrativeText = currentNarrative.toString().trim();
      if (currentTitle.isNotEmpty &&
          (currentBullets.isNotEmpty || narrativeText.isNotEmpty)) {
        final config = _getSectionConfig(currentTitle);
        sections.add(_AnalysisSection(
          title: config.cleanTitle,
          icon: config.icon,
          accentColor: config.color,
          bullets: List.from(currentBullets),
          narrative: narrativeText.isNotEmpty ? narrativeText : null,
        ));
      }
      currentBullets.clear();
      currentNarrative.clear();
    }

    for (final rawLine in lines) {
      final line = rawLine.trim();
      if (line.isEmpty) continue;

      // Check if line is a section header (e.g., "### 1. GENERAL PROBLEM STATEMENT")
      final isHeader = line.startsWith('#') ||
          (line.toUpperCase() == line &&
              line.length > 5 &&
              !line.startsWith('•') &&
              !line.startsWith('-') &&
              !line.startsWith('>'));

      if (isHeader) {
        commitCurrentSection();
        // Clean title
        var cleaned = line.replaceAll(RegExp(r'^[#\s\d\.\-:]+'), '').trim();
        cleaned = cleaned.replaceAll('###', '').replaceAll('##', '').trim();
        currentTitle = cleaned;
      } else if (line.startsWith('•') ||
          line.startsWith('-') ||
          line.startsWith('*')) {
        // Bullet item
        var bulletText = line.replaceFirst(RegExp(r'^[•\-\*]\s*'), '').trim();
        // Extract bold title prefix if present: **Title**: Body
        final boldMatch =
            RegExp(r'^\*\*(.+?)\*\*(?:\s*[:\-–]\s*|\s+)(.*)$').firstMatch(bulletText);
        if (boldMatch != null) {
          final prefix = boldMatch.group(1)?.trim();
          final body = boldMatch.group(2)?.trim() ?? '';
          currentBullets.add(_AnalysisBullet(prefix: prefix, body: body));
        } else {
          currentBullets.add(_AnalysisBullet(prefix: null, body: bulletText));
        }
      } else if (currentBullets.isNotEmpty) {
        // Continuation line of previous bullet
        final last = currentBullets.removeLast();
        currentBullets.add(_AnalysisBullet(
          prefix: last.prefix,
          body: '${last.body} $line',
        ));
      } else if (currentTitle.isNotEmpty) {
        // Narrative paragraph under this section
        final cleanText = line.replaceFirst(RegExp(r'^>\s*'), '').trim();
        if (cleanText.isNotEmpty) {
          if (currentNarrative.isNotEmpty) currentNarrative.write(' ');
          currentNarrative.write(cleanText);
        }
      }
    }

    commitCurrentSection();

    // Fallback: If no structured sections were detected, package as a single general section
    if (sections.isEmpty && text.trim().isNotEmpty) {
      sections.add(_AnalysisSection(
        title: 'GENERAL PROBLEM STATEMENT',
        icon: Icons.lightbulb_outline_rounded,
        accentColor: DashboardDesign.primary,
        bullets: const [],
        narrative: text.trim(),
      ));
    }

    return sections;
  }

  _SectionConfig _getSectionConfig(String rawTitle) {
    final upper = rawTitle.toUpperCase();
    if (upper.contains('GENERAL') ||
        (upper.contains('PROBLEM') && !upper.contains('ENGINEERING'))) {
      return const _SectionConfig(
        cleanTitle: 'General problem statement',
        icon: Icons.lightbulb_outline_rounded,
        color: Color(0xFF0284C7), // Sky Blue
        isCallout: true,
      );
    } else if (upper.contains('ENGINEERING')) {
      return const _SectionConfig(
        cleanTitle: 'Engineering-focused version',
        icon: Icons.precision_manufacturing_outlined,
        color: Color(0xFF0D9488), // Teal
        isCallout: true,
      );
    } else if (upper.contains('CHECK') || upper.contains('VERIFICATION')) {
      return const _SectionConfig(
        cleanTitle: 'KEY CHECKS',
        icon: Icons.verified_outlined,
        color: Color(0xFF2563EB), // Royal Blue
      );
    } else if (upper.contains('RISK') || upper.contains('FAILURE')) {
      return const _SectionConfig(
        cleanTitle: 'KEY RISKS',
        icon: Icons.warning_amber_rounded,
        color: Color(0xFFD97706), // Amber
      );
    } else if (upper.contains('ACTION') || upper.contains('STEP')) {
      return const _SectionConfig(
        cleanTitle: 'NEXT ACTIONS',
        icon: Icons.task_alt_rounded,
        color: Color(0xFF7C3AED), // Purple
      );
    } else if (upper.contains('EVIDENCE') || upper.contains('ARTIFACT')) {
      return const _SectionConfig(
        cleanTitle: 'RECOMMENDED EVIDENCE',
        icon: Icons.folder_shared_outlined,
        color: Color(0xFF059669), // Emerald
      );
    }

    return _SectionConfig(
      cleanTitle: rawTitle,
      icon: Icons.checklist_rounded,
      color: DashboardDesign.primary,
    );
  }

  /// Formats the parsed sections into clean, human-readable plain text for the Notes field.
  String _generateNotesFormattedText() {
    if (_parsedSections.isEmpty) {
      return _rawAnalysisResult ?? '';
    }

    final buffer = StringBuffer();
    for (int i = 0; i < _parsedSections.length; i++) {
      final sec = _parsedSections[i];
      buffer.writeln(sec.title);
      if (sec.narrative != null && sec.narrative!.isNotEmpty) {
        buffer.writeln(sec.narrative);
      }
      for (final bullet in sec.bullets) {
        if (bullet.prefix != null && bullet.prefix!.isNotEmpty) {
          buffer.writeln('• ${bullet.prefix}: ${bullet.body}');
        } else {
          buffer.writeln('• ${bullet.body}');
        }
      }
      if (i < _parsedSections.length - 1) {
        buffer.writeln();
      }
    }
    return buffer.toString().trim();
  }

  void _copyToClipboard() {
    final text = _generateNotesFormattedText();
    if (text.isEmpty) return;
    Clipboard.setData(ClipboardData(text: text));
    AppMessenger.info(t('ai_copied_clipboard'));
  }

  void _applyToNotes({required bool append}) {
    final text = _generateNotesFormattedText();
    if (text.isEmpty) return;
    widget.onApplyNotes(text, append);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = DashboardDesign.isDark(context);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF111827) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.25),
            blurRadius: 24,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: Column(
        children: [
          // Sheet drag bar (Compact)
          Center(
            child: Container(
              width: 36,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 10),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[700] : Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header (Compact & Minimal)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: DashboardDesign.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.auto_awesome_rounded,
                    color: DashboardDesign.primary,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t('ai_analysis_title'),
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: DashboardDesign.text(context),
                        ),
                      ),
                      const SizedBox(height: 1),
                      Text(
                        '${widget.stageName} • ${widget.checklistItem}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11.5,
                          color: DashboardDesign.mutedText(context),
                        ),
                      ),
                    ],
                  ),
                ),
                if (!_isLoading && _parsedSections.isNotEmpty) ...[
                  // Segmented view switcher (Cards vs Raw Notes)
                  Container(
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1F2937) : const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: const EdgeInsets.all(2.5),
                    child: Row(
                      children: [
                        _ViewModeTab(
                          label: 'Report',
                          icon: Icons.dashboard_outlined,
                          isSelected: _viewModeIndex == 0,
                          onTap: () => setState(() => _viewModeIndex = 0),
                        ),
                        _ViewModeTab(
                          label: 'Notes',
                          icon: Icons.notes_rounded,
                          isSelected: _viewModeIndex == 1,
                          onTap: () => setState(() => _viewModeIndex = 1),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 6),
                ],
                IconButton(
                  tooltip: 'Close',
                  icon: Icon(
                    Icons.close_rounded,
                    size: 20,
                    color: DashboardDesign.mutedText(context),
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

          // Context Meta Bar (Shown once analyzed)
          if (_rawAnalysisResult != null) _buildContextBar(isDark),

          // Main body content
          Expanded(
            child: _buildBody(isDark),
          ),

          // Footer action bar
          if (!_isLoading && _parsedSections.isNotEmpty)
            _buildBottomActionBar(isDark),
        ],
      ),
    );
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
      case 'critical':
        return Colors.redAccent;
      case 'medium':
        return Colors.amber.shade700;
      case 'low':
        return Colors.blueAccent;
      default:
        return DashboardDesign.primary;
    }
  }

  Widget _buildContextBar(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF0F172A).withValues(alpha: 0.7)
            : const Color(0xFFF8FAFC),
        border: Border(
          bottom: BorderSide(
            color: DashboardDesign.border(context).withValues(alpha: 0.5),
          ),
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _buildMetaBadge(
              icon: Icons.folder_open_rounded,
              text: widget.projectName,
              isDark: isDark,
            ),
            const SizedBox(width: 6),
            _buildMetaBadge(
              icon: Icons.layers_outlined,
              text: widget.stageName,
              isDark: isDark,
            ),
            if (widget.discipline.trim().isNotEmpty) ...[
              const SizedBox(width: 6),
              _buildMetaBadge(
                icon: Icons.engineering_outlined,
                text: widget.discipline.trim(),
                isDark: isDark,
              ),
            ],
            if (widget.priority != null && widget.priority!.trim().isNotEmpty) ...[
              const SizedBox(width: 6),
              _buildMetaBadge(
                icon: Icons.flag_outlined,
                text: widget.priority!.trim(),
                badgeColor: _getPriorityColor(widget.priority!.trim()),
                isDark: isDark,
              ),
            ],
            if (widget.assignee != null && widget.assignee!.trim().isNotEmpty) ...[
              const SizedBox(width: 6),
              _buildMetaBadge(
                icon: Icons.person_outline_rounded,
                text: widget.assignee!.trim(),
                isDark: isDark,
              ),
            ],
            if (widget.problemStatement != null &&
                widget.problemStatement!.trim().isNotEmpty) ...[
              const SizedBox(width: 6),
              _buildMetaBadge(
                icon: Icons.task_alt_rounded,
                text: 'Scope Included',
                badgeColor: const Color(0xFF059669),
                isDark: isDark,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMetaBadge({
    required IconData icon,
    required String text,
    Color? badgeColor,
    required bool isDark,
  }) {
    final color = badgeColor ??
        (isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569));
    final bg = badgeColor != null
        ? badgeColor.withValues(alpha: isDark ? 0.16 : 0.1)
        : (isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0));

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11.5, color: color),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody(bool isDark) {
    if (_isLoading) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(
                width: 44,
                height: 44,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    DashboardDesign.primary,
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                t('ai_generating'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: DashboardDesign.text(context),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Analyzing ${widget.checklistItem} (${widget.discipline})',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: DashboardDesign.mutedText(context),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_isMissingKey) {
      return _buildKeyMissingState(isDark);
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                size: 44,
                color: Colors.redAccent,
              ),
              const SizedBox(height: 14),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: DashboardDesign.text(context),
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton.icon(
                onPressed: _startAnalysis,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: Text(t('retry')),
                style: ElevatedButton.styleFrom(
                  backgroundColor: DashboardDesign.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_rawAnalysisResult == null) {
      return _buildPreAnalysisView(isDark);
    }

    if (_viewModeIndex == 1) {
      // Notes Preview Mode
      return _buildNotesPreviewMode(isDark);
    }

    // Default: Formatted Engineering Report Mode
    return _buildFormattedCardsMode(isDark);
  }

  Widget _buildPreAnalysisView(bool isDark) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Spark & Title Badge
              Center(
                child: Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: DashboardDesign.primary.withValues(alpha: isDark ? 0.16 : 0.1),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: DashboardDesign.primary.withValues(alpha: 0.3),
                      width: 1.5,
                    ),
                  ),
                  child: const Icon(
                    Icons.auto_awesome_rounded,
                    color: DashboardDesign.primary,
                    size: 26,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                t('analyze_with_ai'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.2,
                  color: DashboardDesign.text(context),
                ),
              ),
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  t('ai_review_subtitle'),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12.5,
                    height: 1.4,
                    color: DashboardDesign.mutedText(context),
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Context Parameters Card (Highlighting Project Name & Description)
              Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.03),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Card Header
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF0F172A).withValues(alpha: 0.5)
                            : const Color(0xFFF8FAFC),
                        borderRadius:
                            const BorderRadius.vertical(top: Radius.circular(11)),
                        border: Border(
                          bottom: BorderSide(
                            color: isDark
                                ? const Color(0xFF334155)
                                : const Color(0xFFE2E8F0),
                          ),
                        ),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.tune_rounded,
                            size: 14,
                            color: DashboardDesign.primary,
                          ),
                          const SizedBox(width: 7),
                          Text(
                            t('context_parameters').toUpperCase(),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                              color: isDark
                                  ? const Color(0xFF94A3B8)
                                  : const Color(0xFF64748B),
                            ),
                          ),
                        ],
                      ),
                    ),

                    Padding(
                      padding: const EdgeInsets.all(14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // 1. Project Name (Highlight)
                          _buildContextParamRow(
                            icon: Icons.folder_open_rounded,
                            iconColor: const Color(0xFF3B82F6),
                            label: t('project_label'),
                            value: _effectiveProjectName,
                            isDark: isDark,
                            isBold: true,
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 10),
                            child: Divider(height: 1),
                          ),

                          // 2. Description & Scope (Highlight)
                          _buildContextParamRow(
                            icon: Icons.description_outlined,
                            iconColor: const Color(0xFF10B981),
                            label: t('description_label'),
                            value: _effectiveDescription,
                            isDark: isDark,
                            isMutedIfEmpty:
                                _effectiveDescription == t('no_description_provided'),
                          ),

                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 10),
                            child: Divider(height: 1),
                          ),

                          // Secondary Badges Row
                          Wrap(
                            spacing: 6,
                            runSpacing: 6,
                            children: [
                              _buildMetaBadge(
                                icon: Icons.layers_outlined,
                                text: widget.stageName,
                                isDark: isDark,
                              ),
                              _buildMetaBadge(
                                icon: Icons.check_circle_outline_rounded,
                                text: widget.checklistItem,
                                isDark: isDark,
                              ),
                              if (widget.discipline.trim().isNotEmpty)
                                _buildMetaBadge(
                                  icon: Icons.engineering_outlined,
                                  text: widget.discipline.trim(),
                                  isDark: isDark,
                                ),
                              if (widget.priority != null &&
                                  widget.priority!.trim().isNotEmpty)
                                _buildMetaBadge(
                                  icon: Icons.flag_outlined,
                                  text: widget.priority!.trim(),
                                  badgeColor:
                                      _getPriorityColor(widget.priority!.trim()),
                                  isDark: isDark,
                                ),
                              if (widget.assignee != null &&
                                  widget.assignee!.trim().isNotEmpty)
                                _buildMetaBadge(
                                  icon: Icons.person_outline_rounded,
                                  text: widget.assignee!.trim(),
                                  isDark: isDark,
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Prominent Action Button
              SizedBox(
                height: 44,
                child: ElevatedButton.icon(
                  onPressed: _startAnalysis,
                  icon: const Icon(Icons.auto_awesome_rounded, size: 18),
                  label: Text(
                    t('analyze_with_ai'),
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.2,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: DashboardDesign.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                t('ready_to_analyze'),
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  color: DashboardDesign.mutedText(context),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContextParamRow({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    required bool isDark,
    bool isBold = false,
    bool isMutedIfEmpty = false,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(5),
          margin: const EdgeInsets.only(top: 1),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: isDark ? 0.18 : 0.1),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Icon(icon, size: 14, color: iconColor),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: DashboardDesign.mutedText(context),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: isBold ? FontWeight.w600 : FontWeight.w400,
                  fontStyle: isMutedIfEmpty ? FontStyle.italic : FontStyle.normal,
                  color: isMutedIfEmpty
                      ? DashboardDesign.mutedText(context)
                      : DashboardDesign.text(context),
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildKeyMissingState(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.amber.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.vpn_key_off_rounded,
                color: Colors.amber,
                size: 36,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              t('ai_groq_key_missing_title'),
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.bold,
                color: DashboardDesign.text(context),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              t('ai_groq_key_missing_desc'),
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                height: 1.4,
                color: DashboardDesign.mutedText(context),
              ),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: _startAnalysis,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: Text(t('retry')),
              style: ElevatedButton.styleFrom(
                backgroundColor: DashboardDesign.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormattedCardsMode(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Structured Section Cards (Compact & High Signal)
          ..._parsedSections.map(
            (sec) => _buildSectionCard(sec, isDark),
          ),
          const SizedBox(height: 6),
          // Footnote disclaimer
          Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.info_outline_rounded,
                  size: 12,
                  color: DashboardDesign.mutedText(context),
                ),
                const SizedBox(width: 5),
                Flexible(
                  child: Text(
                    t('ai_analysis_disclaimer'),
                    style: TextStyle(
                      fontSize: 11,
                      color: DashboardDesign.mutedText(context),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard(_AnalysisSection sec, bool isDark) {
    final hasNarrative = sec.narrative != null && sec.narrative!.isNotEmpty;
    final hasBullets = sec.bullets.isNotEmpty;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 9),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.15 : 0.02),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header banner (Compact)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: sec.accentColor.withValues(alpha: isDark ? 0.12 : 0.07),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(9)),
              border: Border(
                bottom: BorderSide(
                  color: sec.accentColor.withValues(alpha: 0.18),
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(sec.icon, color: sec.accentColor, size: 15),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    sec.title,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                ),
                IconButton(
                  tooltip: 'Copy statement',
                  icon: const Icon(Icons.copy_rounded, size: 14),
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                  constraints:
                      const BoxConstraints(minWidth: 26, minHeight: 26),
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                  onPressed: () {
                    final text = sec.narrative ??
                        (sec.bullets.map((b) => b.body).join('\n'));
                    if (text.isNotEmpty) {
                      Clipboard.setData(ClipboardData(text: text));
                      AppMessenger.info(t('ai_copied_clipboard'));
                    }
                  },
                ),
                if (hasBullets) ...[
                  const SizedBox(width: 4),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                    decoration: BoxDecoration(
                      color: sec.accentColor.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '${sec.bullets.length}',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: sec.accentColor,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),

          // Narrative callout block (formal statement with vertical accent bar)
          if (hasNarrative)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 8),
              child: Container(
                padding:
                    const EdgeInsets.only(left: 12, top: 2, bottom: 2, right: 6),
                decoration: BoxDecoration(
                  border: Border(
                    left: BorderSide(
                      color: isDark
                          ? const Color(0xFF94A3B8)
                          : const Color(0xFF475569),
                      width: 3.5,
                    ),
                  ),
                ),
                child: Text(
                  sec.narrative!,
                  style: TextStyle(
                    fontSize: 13,
                    height: 1.52,
                    color: isDark
                        ? const Color(0xFFE2E8F0)
                        : const Color(0xFF1E293B),
                  ),
                ),
              ),
            ),

          // Bullet items (Compact & high density)
          if (hasBullets)
            Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Column(
              children: sec.bullets.asMap().entries.map((entry) {
                final idx = entry.key;
                final bullet = entry.value;
                final isLast = idx == sec.bullets.length - 1;

                return Padding(
                  padding: EdgeInsets.only(bottom: isLast ? 0 : 7),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 5,
                        height: 5,
                        margin: const EdgeInsets.only(top: 6, right: 8),
                        decoration: BoxDecoration(
                          color: sec.accentColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      Expanded(
                        child: RichText(
                          text: TextSpan(
                            style: TextStyle(
                              fontSize: 12.5,
                              height: 1.38,
                              color: isDark
                                  ? const Color(0xFFCBD5E1)
                                  : const Color(0xFF334155),
                            ),
                            children: [
                              if (bullet.prefix != null) ...[
                                TextSpan(
                                  text: '${bullet.prefix}: ',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w600,
                                    color: isDark
                                        ? Colors.white
                                        : const Color(0xFF0F172A),
                                  ),
                                ),
                              ],
                              TextSpan(text: bullet.body),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotesPreviewMode(bool isDark) {
    final formattedNotes = _generateNotesFormattedText();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Preview of compact notes ready for insertion:',
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w600,
              color: DashboardDesign.mutedText(context),
            ),
          ),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              ),
            ),
            child: SelectableText(
              formattedNotes,
              style: TextStyle(
                fontSize: 12.5,
                height: 1.45,
                color: isDark ? Colors.grey[200] : const Color(0xFF1E293B),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActionBar(bool isDark) {
    final hasExistingNotes = widget.existingNotes.trim().isNotEmpty;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
        border: Border(
          top: BorderSide(
            color: DashboardDesign.border(context),
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            IconButton(
              tooltip: 'Copy',
              icon: const Icon(Icons.copy_rounded, size: 18),
              color: DashboardDesign.text(context),
              onPressed: _copyToClipboard,
            ),
            IconButton(
              tooltip: t('ai_regenerate'),
              icon: const Icon(Icons.refresh_rounded, size: 18),
              color: DashboardDesign.text(context),
              onPressed: _startAnalysis,
            ),
            const Spacer(),
            if (hasExistingNotes) ...[
              OutlinedButton.icon(
                onPressed: () => _applyToNotes(append: true),
                icon: const Icon(Icons.playlist_add_rounded, size: 16),
                label: Text(t('ai_append_to_notes')),
                style: OutlinedButton.styleFrom(
                  foregroundColor: DashboardDesign.primary,
                  side: const BorderSide(color: DashboardDesign.primary),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
            ElevatedButton.icon(
              onPressed: () => _applyToNotes(append: false),
              icon: const Icon(Icons.paste_rounded, size: 16),
              label: Text(t('ai_paste_to_notes')),
              style: ElevatedButton.styleFrom(
                backgroundColor: DashboardDesign.primary,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnalysisSection {
  final String title;
  final IconData icon;
  final Color accentColor;
  final List<_AnalysisBullet> bullets;
  final String? narrative;

  const _AnalysisSection({
    required this.title,
    required this.icon,
    required this.accentColor,
    required this.bullets,
    this.narrative,
  });
}

class _AnalysisBullet {
  final String? prefix;
  final String body;

  const _AnalysisBullet({this.prefix, required this.body});
}

class _SectionConfig {
  final String cleanTitle;
  final IconData icon;
  final Color color;
  final bool isCallout;

  const _SectionConfig({
    required this.cleanTitle,
    required this.icon,
    required this.color,
    this.isCallout = false,
  });
}

class _ViewModeTab extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _ViewModeTab({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = DashboardDesign.isDark(context);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? const Color(0xFF374151) : Colors.white)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.06),
                    blurRadius: 4,
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              size: 14,
              color: isSelected
                  ? DashboardDesign.primary
                  : DashboardDesign.mutedText(context),
            ),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                color: isSelected
                    ? DashboardDesign.text(context)
                    : DashboardDesign.mutedText(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
