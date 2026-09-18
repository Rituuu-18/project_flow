import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:engineering_werk/core/database/supabase_storage.dart';
import 'package:engineering_werk/core/utils/app_messenger.dart';
import 'package:engineering_werk/features/dashboard/presentation/theme/dashboard_design.dart';
import 'package:engineering_werk/features/reviews/domain/entities/stakeholder.dart';
import 'package:engineering_werk/features/reviews/domain/utils/default_stages.dart';
import 'package:engineering_werk/features/workspace/domain/entities/workspace_data.dart';
import 'package:engineering_werk/core/localization/locale_provider.dart';
import 'package:engineering_werk/features/workspace/presentation/providers/workspace_provider.dart';
import 'package:engineering_werk/features/reviews/presentation/providers/design_review_provider.dart';
import '../widgets/ai_analysis_sheet.dart';

class WorkspaceScreen extends ConsumerStatefulWidget {
  final String workspaceId;
  final String reviewId;
  final String projectName;
  final String stageName;
  final String subStepName;

  const WorkspaceScreen({
    super.key,
    required this.workspaceId,
    required this.reviewId,
    required this.projectName,
    required this.stageName,
    required this.subStepName,
  });

  @override
  ConsumerState<WorkspaceScreen> createState() => _WorkspaceScreenState();
}

class _WorkspaceScreenState extends ConsumerState<WorkspaceScreen> {
  WorkspaceData? _currentData;
  bool _isLoading = true;
  Future<void> _saveChain = Future.value();

  late TextEditingController _notesController;
  late TextEditingController _engineeringCommentsController;
  late TextEditingController _actionDescController;
  late TextEditingController _priorityController;
  late TextEditingController _assigneeController;
  late TextEditingController _disciplineController;
  final ScrollController _scrollController = ScrollController();
  final GlobalKey _aiPanelKey = GlobalKey();
  bool _isAIOpen = false;
  String? _cachedAIAnalysis;

  @override
  void initState() {
    super.initState();
    _notesController = TextEditingController();
    _engineeringCommentsController = TextEditingController();
    _actionDescController = TextEditingController();
    _priorityController = TextEditingController();
    _assigneeController = TextEditingController();
    _disciplineController = TextEditingController();
    _initData();
  }

  @override
  void didUpdateWidget(covariant WorkspaceScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.workspaceId != widget.workspaceId ||
        oldWidget.subStepName != widget.subStepName ||
        oldWidget.stageName != widget.stageName) {
      _cachedAIAnalysis = null;
      _isAIOpen = false;
      _initData();
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    _engineeringCommentsController.dispose();
    _actionDescController.dispose();
    _priorityController.dispose();
    _assigneeController.dispose();
    _disciplineController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _initData() async {
    final repo = ref.read(workspaceRepositoryProvider);
    var data = await repo.getWorkspaceById(widget.workspaceId);
    final defaultInfo = getDefaultSubStepInfo(
      stageName: widget.stageName,
      subStepName: widget.subStepName,
    );
    final hasCanonicalInfo =
        defaultStageContent[widget.stageName]?.subSteps.containsKey(
              widget.subStepName,
            ) ??
            false;
    if (data == null) {
      data = WorkspaceData(
        id: widget.workspaceId,
        checklistItem: widget.subStepName,
        itemDescription: defaultInfo.description,
        discipline: defaultInfo.discipline,
      );
      await repo.saveWorkspace(data);
    } else {
      final shouldRefreshAdminFields = hasCanonicalInfo &&
          (data.checklistItem != widget.subStepName ||
              data.itemDescription != defaultInfo.description);
      final shouldFillChecklistItem =
          !hasCanonicalInfo && data.checklistItem.trim().isEmpty;
      final shouldFillDiscipline =
          data.discipline.trim().isEmpty && defaultInfo.discipline.isNotEmpty;

      if (shouldRefreshAdminFields ||
          shouldFillChecklistItem ||
          shouldFillDiscipline) {
        data = data.copyWith(
          checklistItem: shouldRefreshAdminFields || shouldFillChecklistItem
              ? widget.subStepName
              : data.checklistItem,
          itemDescription: shouldRefreshAdminFields
              ? defaultInfo.description
              : data.itemDescription,
          discipline: shouldFillDiscipline
              ? defaultInfo.discipline
              : data.discipline,
        );
        await repo.saveWorkspace(data);
      }
    }

    if (mounted) {
      setState(() {
        _currentData = data;
        _notesController.text = data!.notes;
        _engineeringCommentsController.text = data.engineeringComments;
        _actionDescController.text = data.actionDescription;
        _priorityController.text = data.priority;
        _assigneeController.text = data.assignee;
        _disciplineController.text = data.discipline;
        _isLoading = false;
      });
    }
  }

  Future<void> _saveData({bool silent = false}) async {
    final repo = ref.read(workspaceRepositoryProvider);
    final updated = _currentData!.copyWith(
      notes: _notesController.text,
      engineeringComments: _engineeringCommentsController.text,
      actionDescription: _actionDescController.text,
      priority: _priorityController.text,
      assignee: _assigneeController.text,
      discipline: _disciplineController.text,
    );
    try {
      await repo.saveWorkspace(updated);
      _currentData = updated;
    } catch (e) {
      if (!silent) {
        AppMessenger.fromError(e, prefix: 'Could not save workspace.');
      }
      rethrow;
    }
  }

  Future<void> _enqueueSave({bool silent = false}) {
    final next = _saveChain.then((_) => _saveData(silent: silent));
    // Keep the chain alive after failures so later saves still run.
    _saveChain = next.catchError((Object e) {
      if (silent) {
        AppMessenger.fromError(e, prefix: 'Could not save activity.');
      }
    });
    return next;
  }

  void _addActivityLog(String log) {
    setState(() {
      _currentData = _currentData!.copyWith(
        activityLogs: [
          ..._currentData!.activityLogs,
          "${DateFormat('HH:mm').format(DateTime.now())} - $log",
        ],
      );
    });
    _enqueueSave(silent: true);
  }

  Future<void> _pickEvidence() async {
    final t = ref.read(localeProvider.notifier).t;
    final result = await FilePicker.pickFiles(
      allowMultiple: true,
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;

    final storage = SupabaseStorage(Supabase.instance.client);
    final uploadedRefs = <String>[];

    try {
      AppMessenger.info(t('uploading_evidence'));
      for (final file in result.files) {
        final bytes = file.bytes;
        if (bytes == null || bytes.isEmpty) {
          AppMessenger.error('${t('could_not_read')} "${file.name}".');
          continue;
        }
        if (bytes.length > 20 * 1024 * 1024) {
          AppMessenger.error('"${file.name}" ${t('file_too_large_max_20')}.');
          continue;
        }
        final refPath = await storage.uploadWorkspaceAttachment(
          workspaceId: widget.workspaceId,
          bytes: bytes,
          mimeType: file.extension == null
              ? null
              : _mimeFromExtension(file.extension!),
          fileName: file.name,
        );
        uploadedRefs.add(refPath);
      }

      if (uploadedRefs.isEmpty) {
        AppMessenger.error(t('no_evidence_uploaded'));
        return;
      }

      final attachments = {
        ..._currentData!.attachments,
        ...uploadedRefs,
      }.toList();
      final updated = _currentData!.copyWith(
        attachments: attachments,
        activityLogs: [
          ..._currentData!.activityLogs,
          "${DateFormat('HH:mm').format(DateTime.now())} - ${t('added_evidence_files', {'count': '${uploadedRefs.length}'})}",
        ],
      );

      await ref.read(workspaceRepositoryProvider).saveWorkspace(updated);
      if (!mounted) return;
      setState(() => _currentData = updated);
      AppMessenger.success(t('evidence_uploaded_success'));
    } catch (e) {
      AppMessenger.fromError(e, prefix: t('evidence_upload_failed'));
    }
  }

  Future<void> _openAttachment(String stored) async {
    final t = ref.read(localeProvider.notifier).t;
    try {
      final url = await SupabaseStorage(Supabase.instance.client)
          .resolveAttachmentUrl(stored);
      if (url == null) {
        AppMessenger.error(t('could_not_open_attachment'));
        return;
      }
      final uri = Uri.parse(url);
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!opened) {
        AppMessenger.error(t('could_not_open_attachment'));
      }
    } catch (e) {
      AppMessenger.fromError(e, prefix: t('could_not_open_attachment'));
    }
  }

  static String? _mimeFromExtension(String ext) {
    return switch (ext.toLowerCase()) {
      'png' => 'image/png',
      'jpg' || 'jpeg' => 'image/jpeg',
      'webp' => 'image/webp',
      'gif' => 'image/gif',
      'pdf' => 'application/pdf',
      _ => null,
    };
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(localeProvider);
    final t = ref.read(localeProvider.notifier).t;
    if (_isLoading) return const Scaffold(body: _WorkspaceLoadingState());

    return Scaffold(
      backgroundColor: DashboardDesign.canvas(context),
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            _WorkspaceHeader(
              projectName: widget.projectName,
              stageName: widget.stageName,
              reviewId: widget.reviewId,
              onSave: _saveWithMessage,
            ),
            Expanded(
              child: SingleChildScrollView(
                controller: _scrollController,
                padding: EdgeInsets.all(
                  MediaQuery.sizeOf(context).width < 600 ? 18 : 28,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.stageName,
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: DashboardDesign.text(context),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      defaultStageContent[widget.stageName]?.description ??
                          t('workspace_description_fallback'),
                      style: TextStyle(
                        fontSize: 16,
                        color: DashboardDesign.mutedText(context),
                      ),
                    ),
                    const SizedBox(height: 24),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final primary = Column(
                          children: [
                            _buildItemDetailsCard(context),
                            const SizedBox(height: 16),
                            _buildAddDetailsCard(context),
                            const SizedBox(height: 16),
                            _buildEvidenceCard(context),
                            const SizedBox(height: 16),
                            _buildActionRequiredCard(context),
                          ],
                        );
                        final secondary = Column(
                          children: [
                            _buildAssignmentCard(context),
                            const SizedBox(height: 16),
                            _buildActivityCard(context),
                          ],
                        );

                        if (constraints.maxWidth < 900) {
                          return Column(
                            children: [
                              primary,
                              const SizedBox(height: 16),
                              secondary,
                            ],
                          );
                        }

                        return Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(flex: 3, child: primary),
                            const SizedBox(width: 20),
                            Expanded(flex: 2, child: secondary),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _saveWithMessage() async {
    final t = ref.read(localeProvider.notifier).t;
    try {
      await _enqueueSave(silent: true);
      AppMessenger.success(t('save_progress_success'));
    } catch (e) {
      AppMessenger.fromError(e, prefix: 'Could not save progress.');
    }
  }


  void _toggleAIAnalysis() {
    if (_currentData == null) return;
    setState(() {
      _isAIOpen = !_isAIOpen;
    });
    if (_isAIOpen) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (_aiPanelKey.currentContext != null) {
          Scrollable.ensureVisible(
            _aiPanelKey.currentContext!,
            duration: const Duration(milliseconds: 380),
            curve: Curves.easeOutCubic,
            alignment: 0.15,
          );
        }
      });
    }
  }

  Widget _buildInlineAIPanel(BuildContext context) {
    if (_currentData == null) return const SizedBox.shrink();
    final t = ref.read(localeProvider.notifier).t;
    final stageDesc = defaultStageContent[widget.stageName]?.description;
    final defaultInfo = getDefaultSubStepInfo(
      stageName: widget.stageName,
      subStepName: widget.subStepName,
    );
    final rawItemDesc = _currentData!.itemDescription.trim();
    final effectiveDescription = rawItemDesc.isNotEmpty
        ? rawItemDesc
        : (defaultInfo.description.trim().isNotEmpty
            ? defaultInfo.description.trim()
            : (_currentData!.problemStatement.trim().isNotEmpty
                ? _currentData!.problemStatement.trim()
                : (stageDesc ?? '')));

    final checklist = _currentData!.checklistItem.isEmpty
        ? widget.subStepName
        : _currentData!.checklistItem;

    final reviewsAsync = ref.read(designReviewsStreamProvider);
    final currentReview = reviewsAsync.valueOrNull
        ?.where((r) => r.id == widget.reviewId)
        .firstOrNull;

    final discipline = _disciplineController.text.trim().isNotEmpty
        ? _disciplineController.text.trim()
        : _currentData!.discipline;

    final priority = _priorityController.text.trim().isNotEmpty
        ? _priorityController.text.trim()
        : _currentData!.priority;

    final assignee = _assigneeController.text.trim().isNotEmpty
        ? _assigneeController.text.trim()
        : _currentData!.assignee;

    final engineeringComments =
        _engineeringCommentsController.text.trim().isNotEmpty
            ? _engineeringCommentsController.text.trim()
            : _currentData!.engineeringComments;

    final actionDescription = _actionDescController.text.trim().isNotEmpty
        ? _actionDescController.text.trim()
        : _currentData!.actionDescription;

    return AIAnalysisSheet(
      key: ValueKey('ai_analysis_${widget.workspaceId}'),
      projectName: widget.projectName,
      projectOwner: currentReview?.owner,
      projectStatus: currentReview?.status.name,
      stageName: widget.stageName,
      stageDescription: stageDesc,
      subStepName: widget.subStepName,
      checklistItem: checklist,
      itemDescription: effectiveDescription,
      discipline: discipline,
      priority: priority,
      assignee: assignee,
      problemStatement: _currentData!.problemStatement,
      scopeIn: _currentData!.scopeIn,
      scopeOut: _currentData!.scopeOut,
      engineeringComments: engineeringComments,
      actionDescription: actionDescription,
      existingNotes: _notesController.text,
      initialRawAnalysis: _cachedAIAnalysis,
      isInline: true,
      autoStart: true,
      onClose: () => setState(() => _isAIOpen = false),
      onAnalysisCompleted: (result) {
        _cachedAIAnalysis = result;
      },
      onApplyNotes: (analysisText, append) {
        setState(() {
          if (append && _notesController.text.trim().isNotEmpty) {
            _notesController.text =
                '${_notesController.text.trim()}\n\n$analysisText';
          } else {
            _notesController.text = analysisText;
          }
          _isAIOpen = false;
        });
        _enqueueSave(silent: true);
        _addActivityLog(t('ai_notes_updated'));
        AppMessenger.success(t('ai_notes_updated'));
      },
    );
  }

  Widget _buildItemDetailsCard(BuildContext context) {
    final t = ref.read(localeProvider.notifier).t;
    return _SectionCard(
      title: t('item_details'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.lock_outline_rounded,
                size: 16,
                color: DashboardDesign.primary,
              ),
              const SizedBox(width: 7),
              Text(
                t('managed_by_admin'),
                style: TextStyle(
                  color: DashboardDesign.mutedText(context),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _LabelText(t('checklist_item')),
          _ReadOnlyAdminField(
            text: _currentData!.checklistItem.isEmpty
                ? widget.subStepName
                : _currentData!.checklistItem,
          ),
          const SizedBox(height: 16),
          _LabelText(t('description_label')),
          _ReadOnlyAdminField(
            text: _currentData!.itemDescription,
          ),
        ],
      ),
    );
  }

  Widget _buildAddDetailsCard(BuildContext context) {
    final t = ref.read(localeProvider.notifier).t;
    return _SectionCard(
      title: t('add_details'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              _LabelText(t('notes')),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: _toggleAIAnalysis,
                  borderRadius: BorderRadius.circular(8),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: _isAIOpen
                          ? DashboardDesign.primary.withValues(alpha: 0.18)
                          : DashboardDesign.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _isAIOpen
                            ? DashboardDesign.primary
                            : DashboardDesign.primary.withValues(alpha: 0.35),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.auto_awesome_rounded,
                          size: 14,
                          color: DashboardDesign.primary,
                        ),
                        const SizedBox(width: 5),
                        Text(
                          _isAIOpen
                              ? t('ai_close_panel')
                              : t('ai_analyze_button'),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight:
                                _isAIOpen ? FontWeight.bold : FontWeight.w600,
                            color: DashboardDesign.primary,
                          ),
                        ),
                        if (_isAIOpen) ...[
                          const SizedBox(width: 4),
                          const Icon(
                            Icons.keyboard_arrow_up_rounded,
                            size: 14,
                            color: DashboardDesign.primary,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 320),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            clipBehavior: Clip.antiAlias,
            child: _isAIOpen
                ? Padding(
                    key: _aiPanelKey,
                    padding: const EdgeInsets.only(top: 10, bottom: 8),
                    child: _buildInlineAIPanel(context),
                  )
                : const SizedBox.shrink(),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: _notesController,
            maxLines: 4,
            style: TextStyle(color: DashboardDesign.text(context)),
            decoration: _boxDecoration(context, t('enter_notes')),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed: _saveWithMessage,
              icon: const Icon(Icons.check_rounded, size: 15),
              label: Text(
                t('save_progress'),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: DashboardDesign.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildEvidenceCard(BuildContext context) {
    final t = ref.read(localeProvider.notifier).t;
    return _SectionCard(
      title: t('evidence_actions'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _LabelText(t('file_upload')),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              border: Border.all(
                color: DashboardDesign.border(context),
                style: BorderStyle.solid,
              ),
              borderRadius: BorderRadius.circular(12),
              color: DashboardDesign.subtleSurface(context),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.cloud_upload_outlined,
                  size: 32,
                  color: DashboardDesign.mutedText(context),
                ),
                const SizedBox(height: 8),
                Text(
                  t('drop_files_here'),
                  style: TextStyle(
                    color: DashboardDesign.mutedText(context),
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: _pickEvidence,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: DashboardDesign.primary,
                    foregroundColor: Colors.white,
                  ),
                  child: Text(t('browse_files')),
                ),
                if (_currentData!.attachments.isNotEmpty) ...[
                  const SizedBox(height: 16),
                  const Divider(height: 1),
                  const SizedBox(height: 12),
                  ..._currentData!.attachments.map(
                    (attachment) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: InkWell(
                        onTap: () => _openAttachment(attachment),
                        borderRadius: BorderRadius.circular(8),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.attach_file_rounded,
                              size: 17,
                              color: DashboardDesign.primary,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _attachmentLabel(attachment),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: DashboardDesign.text(context),
                                  fontSize: 13,
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                            Icon(
                              Icons.open_in_new_rounded,
                              size: 16,
                              color: DashboardDesign.mutedText(context),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _attachmentLabel(String value) {
    return SupabaseStorage.attachmentDisplayName(value);
  }

  Widget _buildActionRequiredCard(BuildContext context) {
    final t = ref.read(localeProvider.notifier).t;
    return _SectionCard(
      title: t('action_required'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _LabelText(t('action_description')),
          TextField(
            controller: _actionDescController,
            style: TextStyle(color: DashboardDesign.text(context)),
            decoration: _boxDecoration(context, t('describe_action')),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton.icon(
              onPressed: _saveWithMessage,
              icon: const Icon(Icons.check_rounded, size: 15),
              label: Text(
                t('save_progress'),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.2,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: DashboardDesign.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAssignmentCard(BuildContext context) {
    final reviewsAsync = ref.watch(designReviewsStreamProvider);
    final reviewStakeholders = reviewsAsync.valueOrNull
            ?.where((r) => r.id == widget.reviewId)
            .firstOrNull
            ?.stakeholders;
    final stakeholders = reviewStakeholders ?? const <Stakeholder>[];
    final streamReady = reviewsAsync.hasValue || reviewsAsync.hasError;
    final hasStakeholders = stakeholders.isNotEmpty;
    final currentAssignee = _assigneeController.text.trim();

    final matchedByName = stakeholders
        .where((s) => s.name.trim() == currentAssignee)
        .toList();
    String? selectedId = matchedByName.length == 1 ? matchedByName.first.id : null;

    final dropdownItems = <DropdownMenuItem<String>>[
      ...stakeholders.map(
        (s) => DropdownMenuItem(
          value: s.id,
          child: Text(
            s.role.trim().isEmpty ? s.name : '${s.name} — ${s.role}',
            style: TextStyle(color: DashboardDesign.text(context)),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    ];

    // Orphan assignee (saved name not in stakeholder list).
    const orphanValue = '__orphan_assignee__';
    if (currentAssignee.isNotEmpty &&
        !stakeholders.any((s) => s.name.trim() == currentAssignee)) {
      dropdownItems.insert(
        0,
        DropdownMenuItem(
          value: orphanValue,
          child: Text(
            currentAssignee,
            style: TextStyle(color: DashboardDesign.text(context)),
          ),
        ),
      );
      selectedId = orphanValue;
    }

    final t = ref.read(localeProvider.notifier).t;
    return _SectionCard(
      title: t('assignment'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _LabelText(t('responsible_person')),
          if (reviewsAsync.isLoading && !streamReady) ...[
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                children: [
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    currentAssignee.isEmpty
                        ? t('loading_stakeholders_empty')
                        : t('loading_stakeholders_current', {'assignee': currentAssignee}),
                    style: TextStyle(
                      color: DashboardDesign.mutedText(context),
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ] else if (reviewsAsync.hasError) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: DashboardDesign.subtleSurface(context),
                border: Border.all(color: DashboardDesign.border(context)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    currentAssignee.isEmpty
                        ? t('could_not_load_stakeholders_empty')
                        : t('could_not_load_stakeholders_current', {'assignee': currentAssignee}),
                    style: TextStyle(
                      color: DashboardDesign.mutedText(context),
                      height: 1.4,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () =>
                        ref.invalidate(designReviewsStreamProvider),
                    child: Text(t('retry')),
                  ),
                ],
              ),
            ),
          ] else if (!hasStakeholders) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: DashboardDesign.subtleSurface(context),
                border: Border.all(color: DashboardDesign.border(context)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                currentAssignee.isEmpty
                    ? t('no_stakeholders_yet_empty')
                    : t('no_stakeholders_yet_current', {'assignee': currentAssignee}),
                style: TextStyle(
                  color: DashboardDesign.mutedText(context),
                  height: 1.4,
                  fontSize: 13,
                ),
              ),
            ),
          ] else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
              decoration: BoxDecoration(
                color: DashboardDesign.surface(context),
                border: Border.all(color: DashboardDesign.border(context)),
                borderRadius: BorderRadius.circular(12),
              ),
              child: DropdownButtonHideUnderline(
                child: DropdownButton<String>(
                  value: selectedId,
                  isExpanded: true,
                  hint: Text(
                    t('select_stakeholder'),
                    style: TextStyle(
                      color: DashboardDesign.mutedText(context),
                    ),
                  ),
                  dropdownColor: DashboardDesign.surface(context),
                  icon: Icon(
                    Icons.arrow_drop_down,
                    color: DashboardDesign.mutedText(context),
                  ),
                  style: TextStyle(
                    color: DashboardDesign.text(context),
                    fontSize: 14,
                  ),
                  items: dropdownItems,
                  onChanged: (value) {
                    if (value == null || value == orphanValue) return;
                    final matched =
                        stakeholders.where((s) => s.id == value).firstOrNull;
                    if (matched == null) return;
                    final role = matched.role.trim();
                    setState(() {
                      _assigneeController.text = matched.name;
                      if (role.isNotEmpty) {
                        _disciplineController.text = role;
                      }
                      _currentData = _currentData!.copyWith(
                        assignee: matched.name,
                        discipline: role.isNotEmpty
                            ? role
                            : _currentData!.discipline,
                      );
                    });
                    _addActivityLog(
                      role.isEmpty
                          ? t('assigned_to_name', {'name': matched.name})
                          : t('assigned_to_name_role', {'name': matched.name, 'role': role}),
                    );
                  },
                ),
              ),
            ),
          const SizedBox(height: 12),
          _LabelText(t('discipline')),
          TextField(
            controller: _disciplineController,
            readOnly: hasStakeholders,
            style: TextStyle(color: DashboardDesign.text(context)),
            decoration: _boxDecoration(
              context,
              hasStakeholders
                  ? t('auto_filled_role')
                  : t('discipline_hint'),
            ),
          ),
          const SizedBox(height: 12),
          _LabelText(t('due_date')),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  onTap: () async {
                    final d = await showDatePicker(
                      context: context,
                      initialDate: _currentData!.dueDate ?? DateTime.now(),
                      firstDate: DateTime(2020),
                      lastDate: DateTime(2030),
                      builder: (context, child) {
                        return Theme(
                           data: Theme.of(context).copyWith(
                             colorScheme: Theme.of(context).colorScheme.copyWith(
                                   primary: DashboardDesign.primary,
                                 ),
                           ),
                          child: child!,
                        );
                      },
                    );
                    if (d != null) {
                      setState(() {
                        _currentData = _currentData!.copyWith(dueDate: d);
                      });
                      _addActivityLog(
                        t('changed_due_date', {'date': DateFormat('yyyy-MM-dd').format(d)}),
                      );
                    }
                  },
                  child: _BoxContext(
                    _currentData!.dueDate == null
                        ? t('select_date')
                        : DateFormat('dd MMM yyyy')
                            .format(_currentData!.dueDate!),
                  ),
                ),
              ),
              if (_currentData!.dueDate != null) ...[
                const SizedBox(width: 8),
                TextButton(
                  onPressed: () {
                    setState(() {
                      _currentData =
                          _currentData!.copyWith(clearDueDate: true);
                    });
                    _addActivityLog(t('cleared_due_date'));
                  },
                  child: Text(t('clear')),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActivityCard(BuildContext context) {
    final t = ref.read(localeProvider.notifier).t;
    return _SectionCard(
      title: t('activity'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ..._currentData!.activityLogs.map(
            (log) => Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: DashboardDesign.surface(context),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: DashboardDesign.border(context),
                  ),
                ),
                child: Text(
                  log,
                  style: TextStyle(
                    fontSize: 13,
                    color: DashboardDesign.text(context),
                  ),
                ),
              ),
            ),
          ),
          if (_currentData!.activityLogs.isEmpty)
            Text(
              t('no_recent_activity'),
              style: TextStyle(color: DashboardDesign.mutedText(context)),
            ),
        ],
      ),
    );
  }
}

class _WorkspaceHeader extends ConsumerWidget {
  final String projectName;
  final String stageName;
  final String reviewId;
  final VoidCallback onSave;

  const _WorkspaceHeader({
    required this.projectName,
    required this.stageName,
    required this.reviewId,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final t = ref.watch(localeProvider.notifier).t;
    final width = MediaQuery.sizeOf(context).width;
    final isCompact = width < DashboardDesign.mobileBreakpoint;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: DashboardDesign.canvas(context),
        border: Border(
          bottom: BorderSide(color: DashboardDesign.border(context)),
        ),
      ),
      child: SizedBox(
        height: 72,
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(
              maxWidth: DashboardDesign.maxContentWidth,
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: width < 700 ? 18 : 28),
              child: Row(
                children: [
                  // Left side: Small logo + Project and stage info
                  Expanded(
                    child: Row(
                      children: [
                        Theme.of(context).brightness == Brightness.dark
                            ? ShaderMask(
                                blendMode: BlendMode.srcIn,
                                shaderCallback: (bounds) =>
                                    const LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        Color(0xFF4D8FFF), // brand-blue (top-left)
                                        Color(0xFFF4F7F8), // near-white (bottom-right)
                                      ],
                                      stops: [0.0, 1.0],
                                    ).createShader(bounds),
                                child: Image.asset(
                                  'assets/ed-logo.png',
                                  height: 48,
                                  fit: BoxFit.contain,
                                  errorBuilder:
                                      (context, error, stackTrace) => Icon(
                                    Icons.description_outlined,
                                    size: 28,
                                    color: DashboardDesign.primary,
                                  ),
                                ),
                              )
                            : Image.asset(
                                'assets/ed-logo.png',
                                height: 48,
                                fit: BoxFit.contain,
                                errorBuilder:
                                    (context, error, stackTrace) => Icon(
                                  Icons.description_outlined,
                                  size: 28,
                                  color: DashboardDesign.primary,
                                ),
                              ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                projectName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: DashboardDesign.text(context),
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              Text(
                                stageName,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: DashboardDesign.mutedText(context),
                                  fontSize: 11,
                                  height: 1.25,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Right side: Save button + Back button
                  isCompact
                      ? _HeaderIconButton(
                          tooltip: 'Save Progress',
                          icon: Icons.save_outlined,
                          onPressed: onSave,
                        )
                      : FilledButton.icon(
                          onPressed: onSave,
                          icon: const Icon(Icons.save_outlined, size: 18),
                          label: const Text('Save Progress'),
                          style: FilledButton.styleFrom(
                            backgroundColor: DashboardDesign.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 14,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(
                                DashboardDesign.controlRadius,
                              ),
                            ),
                          ),
                        ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: () => GoRouter.of(context).go('/project/$reviewId'),
                    tooltip: t('back_to_review'),
                    icon: const Icon(Icons.arrow_back_rounded, size: 20),
                    style: IconButton.styleFrom(
                      foregroundColor: DashboardDesign.text(context),
                      backgroundColor: DashboardDesign.surface(context),
                      side: BorderSide(color: DashboardDesign.border(context)),
                      shape: const CircleBorder(),
                      fixedSize: const Size(40, 40),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  final String tooltip;
  final IconData icon;
  final VoidCallback onPressed;

  const _HeaderIconButton({
    required this.tooltip,
    required this.icon,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      icon: Icon(icon, size: 20),
      style: IconButton.styleFrom(
        foregroundColor: DashboardDesign.text(context),
        backgroundColor: DashboardDesign.surface(context),
        side: BorderSide(color: DashboardDesign.border(context)),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DashboardDesign.controlRadius),
        ),
        fixedSize: const Size(44, 44),
      ),
    );
  }
}

class _LabelText extends StatelessWidget {
  final String text;
  const _LabelText(this.text);
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: DashboardDesign.mutedText(context),
          letterSpacing: 1.1,
        ),
      ),
    );
  }
}

class _WorkspaceLoadingState extends StatelessWidget {
  const _WorkspaceLoadingState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: const Duration(milliseconds: 420),
        curve: Curves.easeOutCubic,
        builder: (context, opacity, child) =>
            Opacity(opacity: opacity, child: child),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.description_outlined, color: DashboardDesign.primary),
            const SizedBox(height: 12),
            const Text('Loading workspace...'),
          ],
        ),
      ),
    );
  }
}

class _BoxContext extends StatelessWidget {
  final String text;
  const _BoxContext(this.text);
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: DashboardDesign.surface(context),
        border: Border.all(
          color: DashboardDesign.border(context),
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 14,
          color: DashboardDesign.text(context),
        ),
      ),
    );
  }
}

/// Admin-owned checklist content is rendered as plain context rather than an
/// editable input. Workspace saves never write these fields back.
class _ReadOnlyAdminField extends StatelessWidget {
  final String text;

  const _ReadOnlyAdminField({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: DashboardDesign.subtleSurface(context),
        border: Border.all(
          color: DashboardDesign.border(context),
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              text.isEmpty ? 'Not provided' : text,
              style: TextStyle(
                fontSize: 14,
                height: 1.5,
                color: DashboardDesign.text(context),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Tooltip(
            message: 'Managed by admin',
            child: Icon(
              Icons.lock_outline_rounded,
              size: 17,
              color: DashboardDesign.mutedText(context),
            ),
          ),
        ],
      ),
    );
  }
}

InputDecoration _boxDecoration(BuildContext context, String hint) {
  return InputDecoration(
    hintText: hint,
    hintStyle: TextStyle(color: DashboardDesign.mutedText(context)),
    filled: true,
    fillColor: DashboardDesign.surface(context),
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(
        color: DashboardDesign.border(context),
      ),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(
        color: DashboardDesign.border(context),
      ),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: DashboardDesign.primary, width: 1.5),
    ),
  );
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  const _SectionCard({
    required this.title,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: DashboardDesign.surface(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: DashboardDesign.border(context),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: TextStyle(
              fontSize: 11,
              letterSpacing: 1.1,
              fontWeight: FontWeight.bold,
              color: DashboardDesign.mutedText(context),
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}
