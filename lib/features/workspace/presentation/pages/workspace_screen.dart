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
import 'package:engineering_werk/features/workspace/presentation/providers/workspace_provider.dart';
import 'package:engineering_werk/features/reviews/presentation/providers/design_review_provider.dart';

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
  void dispose() {
    _notesController.dispose();
    _engineeringCommentsController.dispose();
    _actionDescController.dispose();
    _priorityController.dispose();
    _assigneeController.dispose();
    _disciplineController.dispose();
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
    final result = await FilePicker.pickFiles(
      allowMultiple: true,
      withData: true,
    );
    if (result == null || result.files.isEmpty) return;

    final storage = SupabaseStorage(Supabase.instance.client);
    final uploadedRefs = <String>[];

    try {
      AppMessenger.info('Uploading evidence…');
      for (final file in result.files) {
        final bytes = file.bytes;
        if (bytes == null || bytes.isEmpty) {
          AppMessenger.error('Could not read "${file.name}".');
          continue;
        }
        if (bytes.length > 20 * 1024 * 1024) {
          AppMessenger.error('"${file.name}" is too large (max 20 MB).');
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
        AppMessenger.error('No evidence files were uploaded.');
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
          "${DateFormat('HH:mm').format(DateTime.now())} - Added ${uploadedRefs.length} evidence file(s).",
        ],
      );

      await ref.read(workspaceRepositoryProvider).saveWorkspace(updated);
      if (!mounted) return;
      setState(() => _currentData = updated);
      AppMessenger.success('Evidence files uploaded.');
    } catch (e) {
      AppMessenger.fromError(e, prefix: 'Could not upload evidence.');
    }
  }

  Future<void> _openAttachment(String stored) async {
    try {
      final url = await SupabaseStorage(Supabase.instance.client)
          .resolveAttachmentUrl(stored);
      if (url == null) {
        AppMessenger.error('Could not open this attachment.');
        return;
      }
      final uri = Uri.parse(url);
      final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!opened) {
        AppMessenger.error('Could not open this attachment.');
      }
    } catch (e) {
      AppMessenger.fromError(e, prefix: 'Could not open attachment.');
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
              onSave: _saveWithMessage,
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(
                  MediaQuery.sizeOf(context).width < 600 ? 18 : 28,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    OutlinedButton.icon(
                      onPressed: () => context.go('/project/${widget.reviewId}'),
                      icon: const Icon(Icons.arrow_back_rounded, size: 18),
                      label: const Text('Back to review page'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: DashboardDesign.text(context),
                        side: BorderSide(
                          color: DashboardDesign.border(context),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 12,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
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
                          'Context, notes, status, evidence, and actions in one focused screen.',
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
    try {
      await _enqueueSave(silent: true);
      AppMessenger.success('Progress saved.');
    } catch (e) {
      AppMessenger.fromError(e, prefix: 'Could not save progress.');
    }
  }

  Widget _buildItemDetailsCard(BuildContext context) {
    return _SectionCard(
      title: 'Item Details',
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
                'Managed by admin',
                style: TextStyle(
                  color: DashboardDesign.mutedText(context),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _LabelText('Checklist item'),
          _ReadOnlyAdminField(
            text: _currentData!.checklistItem.isEmpty
                ? widget.subStepName
                : _currentData!.checklistItem,
          ),
          const SizedBox(height: 16),
          _LabelText('Description'),
          _ReadOnlyAdminField(
            text: _currentData!.itemDescription,
          ),
        ],
      ),
    );
  }

  Widget _buildAddDetailsCard(BuildContext context) {
    return _SectionCard(
      title: 'Add Details',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _LabelText('Notes'),
          TextField(
            controller: _notesController,
            maxLines: 4,
            style: TextStyle(color: DashboardDesign.text(context)),
            decoration: _boxDecoration(context, 'Enter notes...'),
          ),
        ],
      ),
    );
  }

  Widget _buildEvidenceCard(BuildContext context) {
    return _SectionCard(
      title: 'Evidence & Actions',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _LabelText('File Upload'),
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
                  'Drop Images, PDFs, CAD Files, Drawings here',
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
                  child: const Text('Browse Files'),
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
    return _SectionCard(
      title: 'Action Required',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _LabelText('Action Description'),
          TextField(
            controller: _actionDescController,
            style: TextStyle(color: DashboardDesign.text(context)),
            decoration: _boxDecoration(context, 'Describe action...'),
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

    return _SectionCard(
      title: 'Assignment',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _LabelText('Responsible Person (stakeholder)'),
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
                        ? 'Loading stakeholders…'
                        : 'Loading stakeholders… Current: $currentAssignee',
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
                        ? 'Could not load stakeholders.'
                        : 'Could not load stakeholders. Current assignee: $currentAssignee',
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
                    child: const Text('Retry'),
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
                    ? 'No stakeholders yet. Add them on the design review page — they will appear here, and discipline will fill from their role.'
                    : 'No stakeholders yet. Current assignee: $currentAssignee. Add stakeholders on the design review page to pick from the list.',
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
                    'Select stakeholder...',
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
                          ? 'Assigned to ${matched.name}'
                          : 'Assigned to ${matched.name} ($role)',
                    );
                  },
                ),
              ),
            ),
          const SizedBox(height: 12),
          const _LabelText('Discipline'),
          TextField(
            controller: _disciplineController,
            readOnly: hasStakeholders,
            style: TextStyle(color: DashboardDesign.text(context)),
            decoration: _boxDecoration(
              context,
              hasStakeholders
                  ? 'Auto-filled from stakeholder role'
                  : 'Discipline...',
            ),
          ),
          const SizedBox(height: 12),
          const _LabelText('Due Date'),
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
                        'Changed due date to ${DateFormat('yyyy-MM-dd').format(d)}',
                      );
                    }
                  },
                  child: _BoxContext(
                    _currentData!.dueDate == null
                        ? 'Select date'
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
                    _addActivityLog('Cleared due date');
                  },
                  child: const Text('Clear'),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildActivityCard(BuildContext context) {
    return _SectionCard(
      title: 'Activity',
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
              'No recent activity.',
              style: TextStyle(color: DashboardDesign.mutedText(context)),
            ),
        ],
      ),
    );
  }
}

class _WorkspaceHeader extends StatelessWidget {
  final String projectName;
  final String stageName;
  final VoidCallback onSave;

  const _WorkspaceHeader({
    required this.projectName,
    required this.stageName,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
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
                  // Right side: Save button action
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
