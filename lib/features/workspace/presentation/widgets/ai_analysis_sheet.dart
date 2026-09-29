import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/localization/locale_provider.dart';
import '../../../../core/utils/app_messenger.dart';
import '../../../../services/groq_service.dart';
import '../../../dashboard/presentation/theme/dashboard_design.dart';
import '../../domain/entities/engineering_report.dart';
import 'engineering_report_view.dart';

class AIAnalysisSheet extends ConsumerStatefulWidget {
  final String projectName;
  final String stageName;
  final String checklistItem;
  final String itemDescription;
  final String existingNotes;
  final void Function(String text, bool append) onApplyNotes;
  final String? initialRawAnalysis;
  final VoidCallback? onClose;
  final bool isInline;
  final bool autoStart;
  final void Function(String rawAnalysis)? onAnalysisCompleted;

  const AIAnalysisSheet({
    super.key,
    required this.projectName,
    required this.stageName,
    required this.checklistItem,
    required this.itemDescription,
    required this.existingNotes,
    required this.onApplyNotes,
    this.initialRawAnalysis,
    this.onClose,
    this.isInline = false,
    this.autoStart = false,
    this.onAnalysisCompleted,
  });

  @override
  ConsumerState<AIAnalysisSheet> createState() => _AIAnalysisSheetState();
}

class _AIAnalysisSheetState extends ConsumerState<AIAnalysisSheet> {
  bool _isLoading = false;
  EngineeringReport? _report;
  String? _errorMessage;
  bool _isMissingKey = false;
  int _viewModeIndex = 0; // 0: Report, 1: Notes Preview

  @override
  void initState() {
    super.initState();
    if (widget.initialRawAnalysis != null &&
        widget.initialRawAnalysis!.isNotEmpty) {
      try {
        _report = EngineeringReport.fromResponse(widget.initialRawAnalysis!);
      } on FormatException {
        _errorMessage = t('ai_invalid_report');
      }
    } else if (widget.autoStart) {
      _isLoading = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _startAnalysis();
        }
      });
    }
  }

  String Function(String, [Map<String, String>?]) get t =>
      ref.read(localeProvider.notifier).t;

  String get _effectiveDescription {
    if (widget.itemDescription.trim().isNotEmpty) {
      return widget.itemDescription.trim();
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
        projectName: widget.projectName,
        checklistItem: widget.checklistItem,
        itemDescription: widget.itemDescription,
      );

      if (!mounted) return;
      final report = EngineeringReport.fromResponse(
        result,
        requireTables: true,
      );
      setState(() {
        _report = report;
        _isLoading = false;
      });
      widget.onAnalysisCompleted?.call(result);
    } on FormatException {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = t('ai_invalid_report');
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

  String _generateNotesFormattedText() => _report?.toNotesText() ?? '';

  void _copyToClipboard({bool summaryOnly = false}) {
    final text = summaryOnly
        ? _report?.toFocusedText() ?? ''
        : _generateNotesFormattedText();
    if (text.isEmpty) return;
    Clipboard.setData(ClipboardData(text: text));
    AppMessenger.info(t('ai_copied_clipboard'));
  }

  void _applyToNotes({required bool append, bool summaryOnly = false}) {
    final text = summaryOnly
        ? _report?.toFocusedText() ?? ''
        : _generateNotesFormattedText();
    if (text.isEmpty) return;
    widget.onApplyNotes(text, append);
    if (widget.onClose != null) {
      widget.onClose!();
    } else {
      Navigator.of(context).maybePop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = DashboardDesign.isDark(context);
    final isInline = widget.isInline;

    final content = Column(
      mainAxisSize: isInline ? MainAxisSize.min : MainAxisSize.max,
      children: [
        // Sheet drag bar (Compact - shown only in modal sheet mode)
        if (!isInline)
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
          padding: EdgeInsets.symmetric(
            horizontal: isInline ? 14 : 16,
            vertical: isInline ? 9 : 6,
          ),
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
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      t('ai_analysis_title'),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: isInline ? 13.5 : 15,
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
                        fontSize: 11,
                        color: DashboardDesign.mutedText(context),
                      ),
                    ),
                  ],
                ),
              ),
              if (!_isLoading &&
                  _report != null &&
                  _errorMessage == null &&
                  MediaQuery.sizeOf(context).width >= 520 &&
                  !isInline) ...[
                // Segmented view switcher (Only on wide desktop/modal screens)
                Container(
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF1F2937)
                        : const Color(0xFFF3F4F6),
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
                tooltip: isInline ? t('ai_close_panel') : 'Close',
                icon: Icon(
                  Icons.close_rounded,
                  size: isInline ? 18 : 20,
                  color: DashboardDesign.mutedText(context),
                ),
                onPressed: () {
                  if (widget.onClose != null) {
                    widget.onClose!();
                  } else {
                    Navigator.of(context).maybePop();
                  }
                },
              ),
            ],
          ),
        ),
        const Divider(height: 1),

        // Context Meta Bar (Shown once analyzed)
        if (_report != null) _buildContextBar(isDark),

        // Main body content
        if (isInline)
          ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 520),
            child: _buildBody(isDark),
          )
        else
          Expanded(child: _buildBody(isDark)),

        // Footer action bar
        if (!_isLoading && _report != null && _errorMessage == null)
          _buildBottomActionBar(isDark),
      ],
    );

    if (isInline) {
      return Container(
        decoration: BoxDecoration(
          color: isDark
              ? const Color(0xFF1E293B).withValues(alpha: 0.6)
              : const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: DashboardDesign.primary.withValues(
              alpha: isDark ? 0.35 : 0.22,
            ),
            width: 1.2,
          ),
          boxShadow: [
            BoxShadow(
              color: DashboardDesign.primary.withValues(alpha: 0.04),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: content,
      );
    }

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
      child: content,
    );
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
              icon: Icons.check_circle_outline_rounded,
              text: widget.checklistItem,
              isDark: isDark,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetaBadge({
    required IconData icon,
    required String text,
    required bool isDark,
  }) {
    final color = isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569);
    final bg = isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0);

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
                'Analyzing ${widget.checklistItem} for $_effectiveProjectName',
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

    if (_report == null) {
      return _buildPreAnalysisView(isDark);
    }

    if (_viewModeIndex == 1) {
      // Notes Preview Mode
      return _buildNotesPreviewMode(isDark);
    }

    // Engineering report with section headings and tables.
    return _buildReportMode(isDark);
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
                    color: DashboardDesign.primary.withValues(
                      alpha: isDark ? 0.16 : 0.1,
                    ),
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

              // The three fields used by the AI request.
              Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFF334155)
                        : const Color(0xFFE2E8F0),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(
                        alpha: isDark ? 0.15 : 0.03,
                      ),
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
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 9,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF0F172A).withValues(alpha: 0.5)
                            : const Color(0xFFF8FAFC),
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(11),
                        ),
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
                          _buildContextParamRow(
                            icon: Icons.check_circle_outline_rounded,
                            iconColor: DashboardDesign.primary,
                            label: t('checklist_item'),
                            value: widget.checklistItem,
                            isDark: isDark,
                            isBold: true,
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 10),
                            child: Divider(height: 1),
                          ),

                          // Project name from the review.
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

                          // Canonical checklist description.
                          _buildContextParamRow(
                            icon: Icons.description_outlined,
                            iconColor: const Color(0xFF10B981),
                            label: t('checklist_description'),
                            value: _effectiveDescription,
                            isDark: isDark,
                            isMutedIfEmpty:
                                _effectiveDescription ==
                                t('no_description_provided'),
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
                  fontStyle: isMutedIfEmpty
                      ? FontStyle.italic
                      : FontStyle.normal,
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

  Widget _buildReportMode(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          EngineeringReportView(
            report: _report!,
            horizontalScrollHint: t('ai_table_scroll_hint'),
            focusedHeading: t('ai_engineering_focused_version'),
            summaryActions: Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                TextButton.icon(
                  onPressed: () => _copyToClipboard(summaryOnly: true),
                  icon: const Icon(Icons.copy_rounded, size: 16),
                  label: Text(t('ai_copy_summary')),
                ),
                OutlinedButton.icon(
                  onPressed: () =>
                      _applyToNotes(append: false, summaryOnly: true),
                  icon: const Icon(Icons.paste_rounded, size: 16),
                  label: Text(t('ai_paste_summary')),
                ),
                if (widget.existingNotes.trim().isNotEmpty)
                  TextButton.icon(
                    onPressed: () =>
                        _applyToNotes(append: true, summaryOnly: true),
                    icon: const Icon(Icons.playlist_add_rounded, size: 16),
                    label: Text(t('ai_append_summary')),
                  ),
              ],
            ),
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

  Widget _buildNotesPreviewMode(bool isDark) {
    final formattedNotes = _generateNotesFormattedText();

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _report!.hasTables
                ? t('ai_report_notes_preview')
                : 'Preview of engineering statement ready for insertion:',
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
                color: isDark
                    ? const Color(0xFF334155)
                    : const Color(0xFFE2E8F0),
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
    final hasTables = _report!.hasTables;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
        border: Border(top: BorderSide(color: DashboardDesign.border(context))),
      ),
      child: SafeArea(
        top: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isNarrow = constraints.maxWidth < (hasTables ? 620 : 460);
            final utilityActions = Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton(
                  tooltip: hasTables ? t('ai_copy_full_report') : 'Copy',
                  icon: const Icon(Icons.copy_rounded, size: 17),
                  visualDensity: VisualDensity.compact,
                  color: DashboardDesign.text(context),
                  onPressed: _copyToClipboard,
                ),
                IconButton(
                  tooltip: t('ai_regenerate'),
                  icon: const Icon(Icons.refresh_rounded, size: 17),
                  visualDensity: VisualDensity.compact,
                  color: DashboardDesign.text(context),
                  onPressed: _startAnalysis,
                ),
              ],
            );
            final appendButton = OutlinedButton.icon(
              onPressed: () => _applyToNotes(append: true),
              icon: const Icon(Icons.playlist_add_rounded, size: 14),
              label: Text(
                hasTables
                    ? t('ai_append_full_report')
                    : t('ai_append_to_notes'),
                style: const TextStyle(fontSize: 11.5),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: DashboardDesign.primary,
                side: const BorderSide(color: DashboardDesign.primary),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                visualDensity: VisualDensity.compact,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            );
            final pasteButton = ElevatedButton.icon(
              onPressed: () => _applyToNotes(append: false),
              icon: const Icon(Icons.paste_rounded, size: 14),
              label: Text(
                hasTables ? t('ai_paste_full_report') : t('ai_paste_to_notes'),
                style: const TextStyle(fontSize: 11.5),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: DashboardDesign.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                visualDensity: VisualDensity.compact,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            );
            if (isNarrow) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      utilityActions,
                      if (hasExistingNotes)
                        Expanded(
                          child: Align(
                            alignment: Alignment.centerRight,
                            child: appendButton,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  pasteButton,
                ],
              );
            }
            return Row(
              children: [
                utilityActions,
                const Spacer(),
                if (hasExistingNotes) ...[
                  appendButton,
                  const SizedBox(width: 6),
                ],
                pasteButton,
              ],
            );
          },
        ),
      ),
    );
  }
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
