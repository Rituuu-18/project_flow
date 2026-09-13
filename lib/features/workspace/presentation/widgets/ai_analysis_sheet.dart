import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/localization/locale_provider.dart';
import '../../../../core/utils/app_messenger.dart';
import '../../../../services/groq_service.dart';
import '../../../dashboard/presentation/theme/dashboard_design.dart';

class AIAnalysisSheet extends ConsumerStatefulWidget {
  final String projectName;
  final String stageName;
  final String? stageDescription;
  final String checklistItem;
  final String itemDescription;
  final String discipline;
  final String existingNotes;
  final void Function(String text, bool append) onApplyNotes;

  const AIAnalysisSheet({
    super.key,
    required this.projectName,
    required this.stageName,
    this.stageDescription,
    required this.checklistItem,
    required this.itemDescription,
    required this.discipline,
    required this.existingNotes,
    required this.onApplyNotes,
  });

  static Future<void> show(
    BuildContext context, {
    required String projectName,
    required String stageName,
    String? stageDescription,
    required String checklistItem,
    required String itemDescription,
    required String discipline,
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
          heightFactor: 0.90,
          child: AIAnalysisSheet(
            projectName: projectName,
            stageName: stageName,
            stageDescription: stageDescription,
            checklistItem: checklistItem,
            itemDescription: itemDescription,
            discipline: discipline,
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

  @override
  void initState() {
    super.initState();
    _startAnalysis();
  }

  String Function(String, [Map<String, String>?]) get t =>
      ref.read(localeProvider.notifier).t;

  Future<void> _startAnalysis() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _isMissingKey = false;
    });

    try {
      final result = await GroqService.analyzeSubStep(
        projectName: widget.projectName,
        stageName: widget.stageName,
        stageDescription: widget.stageDescription,
        checklistItem: widget.checklistItem,
        itemDescription: widget.itemDescription,
        discipline: widget.discipline,
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

  /// Parses the raw AI response into cleanly structured sections with bullet points.
  List<_AnalysisSection> _parseSections(String text) {
    final sections = <_AnalysisSection>[];
    final lines = text.split('\n');

    String currentTitle = '';
    final currentBullets = <_AnalysisBullet>[];

    void commitCurrentSection() {
      if (currentTitle.isNotEmpty && currentBullets.isNotEmpty) {
        final config = _getSectionConfig(currentTitle);
        sections.add(_AnalysisSection(
          title: config.cleanTitle,
          icon: config.icon,
          accentColor: config.color,
          bullets: List.from(currentBullets),
        ));
      }
      currentBullets.clear();
    }

    for (final rawLine in lines) {
      final line = rawLine.trim();
      if (line.isEmpty) continue;

      // Check if line is a section header (e.g., "### 1. KEY VERIFICATION CHECKS")
      final isHeader = line.startsWith('#') ||
          (line.toUpperCase() == line &&
              line.length > 5 &&
              !line.startsWith('•') &&
              !line.startsWith('-'));

      if (isHeader) {
        commitCurrentSection();
        // Clean title
        var cleaned = line.replaceAll(RegExp(r'^[#\s\d\.\-:]+'), '').trim();
        cleaned = cleaned.replaceAll('###', '').replaceAll('##', '').trim();
        currentTitle = cleaned;
      } else if (line.startsWith('•') || line.startsWith('-') || line.startsWith('*')) {
        // Bullet item
        var bulletText = line.replaceFirst(RegExp(r'^[•\-\*]\s*'), '').trim();
        // Extract bold title prefix if present: **Title**: Body
        final boldMatch = RegExp(r'^\*\*(.+?)\*\*(?:\s*[:\-–]\s*|\s+)(.*)$').firstMatch(bulletText);
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
      }
    }

    commitCurrentSection();

    // Fallback: If no structured sections were detected, package as a single general section
    if (sections.isEmpty && text.trim().isNotEmpty) {
      final bullets = text
          .split('\n')
          .map((l) => l.trim())
          .where((l) => l.isNotEmpty)
          .map((l) => _AnalysisBullet(
                prefix: null,
                body: l.replaceFirst(RegExp(r'^[•\-\*]\s*'), ''),
              ))
          .toList();

      sections.add(_AnalysisSection(
        title: 'ENGINEERING REVIEW SUMMARY',
        icon: Icons.assignment_outlined,
        accentColor: DashboardDesign.primary,
        bullets: bullets,
      ));
    }

    return sections;
  }

  _SectionConfig _getSectionConfig(String rawTitle) {
    final upper = rawTitle.toUpperCase();
    if (upper.contains('VERIFICATION') || upper.contains('CHECK')) {
      return const _SectionConfig(
        cleanTitle: 'KEY VERIFICATION CHECKS',
        icon: Icons.verified_outlined,
        color: Color(0xFF2563EB), // Royal Blue
      );
    } else if (upper.contains('RISK') || upper.contains('FAILURE')) {
      return const _SectionConfig(
        cleanTitle: 'CRITICAL RISKS & FAILURE MODES',
        icon: Icons.warning_amber_rounded,
        color: Color(0xFFD97706), // Amber
      );
    } else if (upper.contains('EVIDENCE') || upper.contains('ARTIFACT')) {
      return const _SectionConfig(
        cleanTitle: 'RECOMMENDED EVIDENCE & ARTIFACTS',
        icon: Icons.folder_shared_outlined,
        color: Color(0xFF059669), // Emerald
      );
    } else if (upper.contains('ACTION') || upper.contains('STEP')) {
      return const _SectionConfig(
        cleanTitle: 'RECOMMENDED NEXT ACTIONS',
        icon: Icons.task_alt_rounded,
        color: Color(0xFF7C3AED), // Purple
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
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.28),
            blurRadius: 30,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      child: Column(
        children: [
          // Sheet drag bar
          Center(
            child: Container(
              width: 42,
              height: 4,
              margin: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[700] : Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: DashboardDesign.primary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.auto_awesome_rounded,
                    color: DashboardDesign.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t('ai_analysis_title'),
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.bold,
                          color: DashboardDesign.text(context),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${widget.stageName} • ${widget.checklistItem}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
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
                    padding: const EdgeInsets.all(3),
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
                  const SizedBox(width: 8),
                ],
                IconButton(
                  tooltip: 'Close',
                  icon: Icon(
                    Icons.close_rounded,
                    color: DashboardDesign.mutedText(context),
                  ),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          const Divider(height: 1),

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

    if (_viewModeIndex == 1) {
      // Notes Preview Mode
      return _buildNotesPreviewMode(isDark);
    }

    // Default: Formatted Engineering Report Mode
    return _buildFormattedCardsMode(isDark);
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
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Disclaimer pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.blue.withValues(alpha: 0.08)
                  : const Color(0xFFF0F7FF),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: DashboardDesign.primary.withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.info_outline_rounded,
                  color: DashboardDesign.primary,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    t('ai_analysis_disclaimer'),
                    style: TextStyle(
                      fontSize: 12,
                      color: DashboardDesign.text(context),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Structured Section Cards
          ..._parsedSections.map(
            (sec) => _buildSectionCard(sec, isDark),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionCard(_AnalysisSection sec, bool isDark) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: sec.accentColor.withValues(alpha: isDark ? 0.12 : 0.07),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(13)),
              border: Border(
                bottom: BorderSide(
                  color: sec.accentColor.withValues(alpha: 0.2),
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(sec.icon, color: sec.accentColor, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    sec.title,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: sec.accentColor.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${sec.bullets.length}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: sec.accentColor,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Bullet items
          Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: sec.bullets.asMap().entries.map((entry) {
                final idx = entry.key;
                final bullet = entry.value;
                final isLast = idx == sec.bullets.length - 1;

                return Padding(
                  padding: EdgeInsets.only(bottom: isLast ? 0 : 12),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        margin: const EdgeInsets.only(top: 7, right: 10),
                        decoration: BoxDecoration(
                          color: sec.accentColor,
                          shape: BoxShape.circle,
                        ),
                      ),
                      Expanded(
                        child: RichText(
                          text: TextSpan(
                            style: TextStyle(
                              fontSize: 13.5,
                              height: 1.45,
                              color: isDark
                                  ? const Color(0xFFCBD5E1)
                                  : const Color(0xFF334155),
                            ),
                            children: [
                              if (bullet.prefix != null) ...[
                                TextSpan(
                                  text: '${bullet.prefix}: ',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
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
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Preview of text that will be inserted into Notes:',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: DashboardDesign.mutedText(context),
            ),
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              ),
            ),
            child: SelectableText(
              formattedNotes,
              style: TextStyle(
                fontSize: 13,
                height: 1.5,
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
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
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
              icon: const Icon(Icons.copy_rounded, size: 20),
              color: DashboardDesign.text(context),
              onPressed: _copyToClipboard,
            ),
            IconButton(
              tooltip: t('ai_regenerate'),
              icon: const Icon(Icons.refresh_rounded, size: 20),
              color: DashboardDesign.text(context),
              onPressed: _startAnalysis,
            ),
            const Spacer(),
            if (hasExistingNotes) ...[
              OutlinedButton.icon(
                onPressed: () => _applyToNotes(append: true),
                icon: const Icon(Icons.playlist_add_rounded, size: 18),
                label: Text(t('ai_append_to_notes')),
                style: OutlinedButton.styleFrom(
                  foregroundColor: DashboardDesign.primary,
                  side: const BorderSide(color: DashboardDesign.primary),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              const SizedBox(width: 10),
            ],
            ElevatedButton.icon(
              onPressed: () => _applyToNotes(append: false),
              icon: const Icon(Icons.paste_rounded, size: 18),
              label: Text(t('ai_paste_to_notes')),
              style: ElevatedButton.styleFrom(
                backgroundColor: DashboardDesign.primary,
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
}

class _AnalysisSection {
  final String title;
  final IconData icon;
  final Color accentColor;
  final List<_AnalysisBullet> bullets;

  const _AnalysisSection({
    required this.title,
    required this.icon,
    required this.accentColor,
    required this.bullets,
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

  const _SectionConfig({
    required this.cleanTitle,
    required this.icon,
    required this.color,
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
