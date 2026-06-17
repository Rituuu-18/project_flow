import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'package:go_router/go_router.dart';
import 'package:engineering_werk/features/dashboard/presentation/theme/dashboard_design.dart';
import 'package:engineering_werk/features/reviews/domain/utils/default_stages.dart';
import 'package:engineering_werk/features/workspace/domain/entities/workspace_data.dart';
import 'package:engineering_werk/features/workspace/presentation/providers/workspace_provider.dart';
import 'package:engineering_werk/features/settings/presentation/providers/theme_provider.dart';

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

  Future<void> _saveData() async {
    final repo = ref.read(workspaceRepositoryProvider);
    final updated = _currentData!.copyWith(
      notes: _notesController.text,
      engineeringComments: _engineeringCommentsController.text,
      actionDescription: _actionDescController.text,
      priority: _priorityController.text,
      assignee: _assigneeController.text,
      discipline: _disciplineController.text,
    );
    await repo.saveWorkspace(updated);
    _currentData = updated;
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
    _saveData();
  }

  Future<void> _pickEvidence() async {
    final result = await FilePicker.pickFiles(allowMultiple: true);
    if (result == null || result.files.isEmpty) return;

    final selected = result.files
        .map((file) => file.path ?? file.name)
        .where((value) => value.trim().isNotEmpty);
    final attachments = {..._currentData!.attachments, ...selected}.toList();
    final updated = _currentData!.copyWith(
      attachments: attachments,
      activityLogs: [
        ..._currentData!.activityLogs,
        "${DateFormat('HH:mm').format(DateTime.now())} - Added ${result.files.length} evidence file(s).",
      ],
    );

    await ref.read(workspaceRepositoryProvider).saveWorkspace(updated);
    if (!mounted) return;
    setState(() => _currentData = updated);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: _WorkspaceLoadingState());

    final themeMode = ref.watch(themeProvider);
    final isDark =
        themeMode == ThemeMode.dark ||
        (themeMode == ThemeMode.system &&
            MediaQuery.of(context).platformBrightness == Brightness.dark);

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
              onToggleTheme: _toggleTheme,
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
                        foregroundColor: isDark
                            ? Colors.grey[200]
                            : const Color(0xFF374151),
                        side: BorderSide(
                          color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
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
                      'Substep workspace',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : const Color(0xFF1F2937),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Context, notes, status, evidence, and actions in one focused screen.',
                      style: TextStyle(
                        fontSize: 16,
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 24),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final primary = Column(
                          children: [
                            _buildItemDetailsCard(isDark),
                            const SizedBox(height: 16),
                            _buildAddDetailsCard(isDark),
                            const SizedBox(height: 16),
                            _buildEvidenceCard(isDark),
                            const SizedBox(height: 16),
                            _buildActionRequiredCard(isDark),
                          ],
                        );
                        final secondary = Column(
                          children: [
                            _buildAssignmentCard(isDark),
                            const SizedBox(height: 16),
                            _buildActivityCard(isDark),
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
    await _saveData();
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        const SnackBar(
          content: Text('Progress saved'),
          backgroundColor: Color(0xFF006D6A),
        ),
      );
  }

  void _toggleTheme() {
    ref.read(themeProvider.notifier).toggleTheme();
  }

  Widget _buildItemDetailsCard(bool isDark) {
    return _SectionCard(
      title: 'Item Details',
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.lock_outline_rounded,
                size: 16,
                color: Color(0xFF006D6A),
              ),
              const SizedBox(width: 7),
              Text(
                'Managed by admin',
                style: TextStyle(
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _LabelText('Checklist item', isDark: isDark),
          _ReadOnlyAdminField(
            text: _currentData!.checklistItem.isEmpty
                ? widget.subStepName
                : _currentData!.checklistItem,
            isDark: isDark,
          ),
          const SizedBox(height: 16),
          _LabelText('Description', isDark: isDark),
          _ReadOnlyAdminField(
            text: _currentData!.itemDescription,
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildAddDetailsCard(bool isDark) {
    return _SectionCard(
      title: 'Add Details',
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _LabelText('Notes', isDark: isDark),
          TextField(
            controller: _notesController,
            maxLines: 4,
            style: TextStyle(color: isDark ? Colors.white : Colors.black87),
            decoration: _boxDecoration('Enter notes...', isDark),
          ),

        ],
      ),
    );
  }

  Widget _buildEvidenceCard(bool isDark) {
    return _SectionCard(
      title: 'Evidence & Actions',
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _LabelText('File Upload', isDark: isDark),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              border: Border.all(
                color: isDark
                    ? Colors.grey[800]!
                    : Colors.grey.withValues(alpha: 0.4),
                style: BorderStyle.solid,
              ),
              borderRadius: BorderRadius.circular(12),
              color: isDark ? const Color(0xFF111827) : const Color(0xFFF3F0EC),
            ),
            child: Column(
              children: [
                Icon(
                  Icons.cloud_upload_outlined,
                  size: 32,
                  color: isDark ? Colors.grey[500] : Colors.grey,
                ),
                const SizedBox(height: 8),
                Text(
                  'Drop Images, PDFs, CAD Files, Drawings here',
                  style: TextStyle(
                    color: isDark ? Colors.grey[400] : Colors.grey,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: _pickEvidence,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF006D6A),
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
                      child: Row(
                        children: [
                          const Icon(
                            Icons.attach_file_rounded,
                            size: 17,
                            color: Color(0xFF006D6A),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              _attachmentLabel(attachment),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: isDark
                                    ? Colors.grey[300]
                                    : Colors.black87,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
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
    return value.split(RegExp(r'[/\\]')).last;
  }

  Widget _buildActionRequiredCard(bool isDark) {
    return _SectionCard(
      title: 'Action Required',
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _LabelText('Action Description', isDark: isDark),
          TextField(
            controller: _actionDescController,
            style: TextStyle(color: isDark ? Colors.white : Colors.black87),
            decoration: _boxDecoration('Describe action...', isDark),
          ),

        ],
      ),
    );
  }

  Widget _buildAssignmentCard(bool isDark) {
    return _SectionCard(
      title: 'Assignment',
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _LabelText('Responsible Person', isDark: isDark),
          TextField(
            controller: _assigneeController,
            style: TextStyle(color: isDark ? Colors.white : Colors.black87),
            decoration: _boxDecoration('Assignee name...', isDark),
          ),
          const SizedBox(height: 12),
          _LabelText('Discipline', isDark: isDark),
          TextField(
            controller: _disciplineController,
            style: TextStyle(color: isDark ? Colors.white : Colors.black87),
            decoration: _boxDecoration('Discipline...', isDark),
          ),
          const SizedBox(height: 12),
          _LabelText('Due Date', isDark: isDark),
          InkWell(
            onTap: () async {
              final d = await showDatePicker(
                context: context,
                initialDate: DateTime.now(),
                firstDate: DateTime.now(),
                lastDate: DateTime(2030),
                builder: (context, child) {
                  return Theme(
                    data: isDark
                        ? ThemeData.dark().copyWith(
                            colorScheme: const ColorScheme.dark(
                              primary: Color(0xFF006D6A),
                            ),
                          )
                        : ThemeData.light().copyWith(
                            colorScheme: const ColorScheme.light(
                              primary: Color(0xFF006D6A),
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
                  : DateFormat('dd MMM yyyy').format(_currentData!.dueDate!),
              isDark: isDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActivityCard(bool isDark) {
    return _SectionCard(
      title: 'Activity',
      isDark: isDark,
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
                  color: isDark ? const Color(0xFF111827) : Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isDark
                        ? Colors.grey[800]!
                        : Colors.grey.withValues(alpha: 0.3),
                  ),
                ),
                child: Text(
                  log,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.grey[300] : Colors.black87,
                  ),
                ),
              ),
            ),
          ),
          if (_currentData!.activityLogs.isEmpty)
            Text(
              'No recent activity.',
              style: TextStyle(color: isDark ? Colors.grey[500] : Colors.grey),
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
  final VoidCallback onToggleTheme;

  const _WorkspaceHeader({
    required this.projectName,
    required this.stageName,
    required this.onSave,
    required this.onToggleTheme,
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
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(
            maxWidth: DashboardDesign.maxContentWidth,
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: width < 700 ? 18 : 28,
              vertical: 10,
            ),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(11),
                  child: Image.asset(
                    'assets/logo.jpeg',
                    width: 40,
                    height: 40,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => Container(
                      width: 40,
                      height: 40,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: DashboardDesign.subtleSurface(context),
                        borderRadius: BorderRadius.circular(11),
                        border: Border.all(
                          color: DashboardDesign.border(context),
                        ),
                      ),
                      child: const Icon(
                        Icons.description_outlined,
                        size: 20,
                        color: DashboardDesign.primary,
                      ),
                    ),
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
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      Text(
                        stageName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: DashboardDesign.mutedText(context),
                          fontSize: 12,
                          height: 1.25,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                _HeaderIconButton(
                  tooltip: 'Toggle theme',
                  icon: DashboardDesign.isDark(context)
                      ? Icons.light_mode_outlined
                      : Icons.dark_mode_outlined,
                  onPressed: onToggleTheme,
                ),
                const SizedBox(width: 8),
                if (isCompact)
                  _HeaderIconButton(
                    tooltip: 'Save Progress',
                    icon: Icons.save_outlined,
                    onPressed: onSave,
                  )
                else
                  FilledButton.icon(
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
  final bool isDark;
  const _LabelText(this.text, {this.isDark = false});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.bold,
          color: isDark ? Colors.grey[400] : Colors.grey,
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
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.description_outlined, color: Color(0xFF006D6A)),
            SizedBox(height: 12),
            Text('Loading workspace...'),
          ],
        ),
      ),
    );
  }
}

class _BoxContext extends StatelessWidget {
  final String text;
  final bool isDark;
  const _BoxContext(this.text, {this.isDark = false});
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF111827) : Colors.white,
        border: Border.all(
          color: isDark
              ? Colors.grey[800]!
              : Colors.grey.withValues(alpha: 0.3),
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 14,
          color: isDark ? Colors.white : Colors.black87,
        ),
      ),
    );
  }
}

/// Admin-owned checklist content is rendered as plain context rather than an
/// editable input. Workspace saves never write these fields back.
class _ReadOnlyAdminField extends StatelessWidget {
  final String text;
  final bool isDark;

  const _ReadOnlyAdminField({required this.text, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF111827) : const Color(0xFFF7F9FC),
        border: Border.all(
          color: isDark
              ? Colors.grey[800]!
              : Colors.grey.withValues(alpha: 0.3),
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
                color: isDark ? Colors.grey[200] : Colors.black87,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Tooltip(
            message: 'Managed by admin',
            child: Icon(
              Icons.lock_outline_rounded,
              size: 17,
              color: isDark ? Colors.grey[500] : Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }
}

InputDecoration _boxDecoration(String hint, bool isDark) {
  return InputDecoration(
    hintText: hint,
    hintStyle: TextStyle(color: isDark ? Colors.grey[600] : Colors.grey[400]),
    filled: true,
    fillColor: isDark ? const Color(0xFF111827) : Colors.white,
    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(
        color: isDark ? Colors.grey[800]! : Colors.grey.withValues(alpha: 0.3),
      ),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: BorderSide(
        color: isDark ? Colors.grey[800]! : Colors.grey.withValues(alpha: 0.3),
      ),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12),
      borderSide: const BorderSide(color: Color(0xFF006D6A), width: 1.5),
    ),
  );
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  final bool isDark;
  const _SectionCard({
    required this.title,
    required this.child,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F2937) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? Colors.grey[800]!
              : Colors.grey.withValues(alpha: 0.3),
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
              color: isDark ? Colors.grey[400] : Colors.grey,
            ),
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}
