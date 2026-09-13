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
          heightFactor: 0.88,
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
  String? _analysisResult;
  String? _errorMessage;
  bool _isMissingKey = false;
  bool _showKeySettings = false;

  final TextEditingController _keyInputController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _startAnalysis();
  }

  @override
  void dispose() {
    _keyInputController.dispose();
    super.dispose();
  }

  String Function(String, [Map<String, String>?]) get t =>
      ref.read(localeProvider.notifier).t;

  Future<void> _startAnalysis() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
      _isMissingKey = false;
      _showKeySettings = false;
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
        _analysisResult = result;
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

  Future<void> _saveKeyAndRetry() async {
    final key = _keyInputController.text.trim();
    if (key.isEmpty) return;

    await GroqService.setCustomApiKey(key);
    _keyInputController.clear();
    AppMessenger.success(t('ai_key_saved'));
    _startAnalysis();
  }

  void _copyToClipboard() {
    if (_analysisResult == null || _analysisResult!.isEmpty) return;
    Clipboard.setData(ClipboardData(text: _analysisResult!));
    AppMessenger.info(t('ai_copied_clipboard'));
  }

  void _applyToNotes({required bool append}) {
    if (_analysisResult == null || _analysisResult!.isEmpty) return;
    widget.onApplyNotes(_analysisResult!, append);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = DashboardDesign.isDark(context);
    final theme = Theme.of(context);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF111827) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
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
          // Drag handle
          Center(
            child: Container(
              width: 44,
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
                IconButton(
                  tooltip: 'Settings',
                  icon: Icon(
                    _showKeySettings ? Icons.close : Icons.key_outlined,
                    color: DashboardDesign.mutedText(context),
                    size: 20,
                  ),
                  onPressed: () {
                    setState(() => _showKeySettings = !_showKeySettings);
                  },
                ),
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

          // Main body
          Expanded(
            child: _showKeySettings
                ? _buildKeySettingsView(isDark)
                : _buildContent(isDark, theme),
          ),

          // Footer action bar (only if we have results)
          if (!_isLoading && _analysisResult != null && !_showKeySettings)
            _buildBottomActionBar(isDark),
        ],
      ),
    );
  }

  Widget _buildContent(bool isDark, ThemeData theme) {
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
                'Reviewing ${widget.checklistItem} (${widget.discipline})',
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
      return _buildKeyMissingPrompt(isDark);
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
                size: 48,
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

    if (_analysisResult != null) {
      return SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
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
                    size: 18,
                  ),
                  const SizedBox(width: 10),
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
            SelectableText(
              _analysisResult!,
              style: TextStyle(
                fontSize: 14,
                height: 1.6,
                color: DashboardDesign.text(context),
                fontFamily: 'monospace',
              ),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildKeyMissingPrompt(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.amber.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.vpn_key_rounded,
              color: Colors.amber,
              size: 36,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            t('ai_groq_key_missing_title'),
            style: TextStyle(
              fontSize: 18,
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
          TextField(
            controller: _keyInputController,
            obscureText: true,
            style: TextStyle(color: DashboardDesign.text(context), fontSize: 14),
            decoration: InputDecoration(
              hintText: t('ai_enter_groq_key'),
              hintStyle: TextStyle(
                color: DashboardDesign.mutedText(context),
                fontSize: 13,
              ),
              filled: true,
              fillColor: isDark ? const Color(0xFF1F2937) : const Color(0xFFF9FAFB),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                  color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: const BorderSide(
                  color: DashboardDesign.primary,
                  width: 1.5,
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _saveKeyAndRetry,
              icon: const Icon(Icons.check_circle_outline, size: 18),
              label: Text(t('ai_save_key')),
              style: ElevatedButton.styleFrom(
                backgroundColor: DashboardDesign.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildKeySettingsView(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Groq API Configuration',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: DashboardDesign.text(context),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'You can set a custom Groq API key here. It is safely stored in local device storage (SharedPreferences) and will override any .env key.',
            style: TextStyle(
              fontSize: 13,
              color: DashboardDesign.mutedText(context),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _keyInputController,
            obscureText: true,
            style: TextStyle(color: DashboardDesign.text(context), fontSize: 14),
            decoration: InputDecoration(
              hintText: t('ai_enter_groq_key'),
              hintStyle: TextStyle(
                color: DashboardDesign.mutedText(context),
                fontSize: 13,
              ),
              filled: true,
              fillColor: isDark ? const Color(0xFF1F2937) : const Color(0xFFF9FAFB),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(
                  color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: _saveKeyAndRetry,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: DashboardDesign.primary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(t('ai_save_key')),
                ),
              ),
              const SizedBox(width: 10),
              OutlinedButton(
                onPressed: () async {
                  await GroqService.clearCustomApiKey();
                  AppMessenger.info('Custom key cleared.');
                  setState(() => _showKeySettings = false);
                  _startAnalysis();
                },
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.redAccent,
                  side: const BorderSide(color: Colors.redAccent),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: Text(t('ai_clear_key')),
              ),
            ],
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
