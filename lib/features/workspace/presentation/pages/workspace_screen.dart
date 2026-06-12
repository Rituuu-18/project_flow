import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:file_picker/file_picker.dart';
import 'package:go_router/go_router.dart';
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
  late TextEditingController _engCommentsController;
  late TextEditingController _actionDescController;
  late TextEditingController _assigneeController;
  late TextEditingController _priorityController;
  late TextEditingController _disciplineController;

  @override
  void initState() {
    super.initState();
    _notesController = TextEditingController();
    _engCommentsController = TextEditingController();
    _actionDescController = TextEditingController();
    _assigneeController = TextEditingController();
    _priorityController = TextEditingController(text: 'Medium');
    _disciplineController = TextEditingController();
    _initData();
  }

  @override
  void dispose() {
    _notesController.dispose();
    _engCommentsController.dispose();
    _actionDescController.dispose();
    _assigneeController.dispose();
    _priorityController.dispose();
    _disciplineController.dispose();
    super.dispose();
  }

  Map<String, String> _getDefaultInfo(String name) {
    const data = {
      "Define the problem and scope": {
        "description":
            "Clarify the core problem the product must solve and for whom by defining use cases, user personas, and operating context, then define what is included in the project and what is explicitly out of scope to prevent feature creep.",
        "discipline": "Systems Engineering",
      },
      "Identify stakeholders and interfaces": {
        "description":
            "List all stakeholders including customers, internal departments, regulatory bodies, and suppliers, then identify the products, standards, infrastructure, or software interfaces the system must connect to or remain compatible with.",
        "discipline": "Systems Engineering",
      },
      "Capture user and business needs": {
        "description":
            "Gather high-level needs from interviews, workshops, field observations, issue reports, and competitor inputs, then translate them into structured needs such as reduced maintenance effort, faster installation, increased throughput, or compliance with a required standard.",
        "discipline": "Product Definition",
      },
      "Derive functional requirements": {
        "description":
            "Convert stakeholder and business needs into functions the system must perform, such as lifting a target load, logging data at a defined interval, or detecting overload and stopping, and define measurable success criteria for each function.",
        "discipline": "Requirements",
      },
      "Define performance and quality targets": {
        "description":
            "Specify targets for capacity, speed, efficiency, noise, energy use, lifetime, reliability, MTBF, and define robustness expectations such as temperature, vibration, IP rating, safety integrity, and allowed failure rates.",
        "discipline": "Requirements",
      },
      "Establish constraints and boundaries": {
        "description":
            "Document regulatory norms, company standards, safety rules, preferred technologies, material choices, platform reuse rules, and capture business constraints such as target cost, selling price, development budget, milestones, and target markets.",
        "discipline": "Program Management",
      },
      "Non-functional requirements": {
        "description":
            "Define usability and service expectations including ergonomics, accessibility, installation time, maintenance intervals, service access, required tools, and operational expectations such as maintainability, diagnostics, data logging, cybersecurity, documentation, and labeling.",
        "discipline": "Lifecycle Engineering",
      },
      "Validation and testability definition": {
        "description":
            "For each requirement, define how it will be verified through analysis, simulation, inspection, lab testing, field testing, or certification, and ensure each one is specific, measurable, achievable, relevant, time-bound, and traceable to a validation method.",
        "discipline": "Verification",
      },
      "Requirements document and structure": {
        "description":
            "Compile the requirements into a structured Requirements Specification or PRD with sections for scope, stakeholders, functional requirements, non-functional requirements, constraints, and verification, and use requirement IDs and hierarchy such as REQ-001 and REQ-001-a for traceability.",
        "discipline": "Documentation",
      },
      "Review, negotiate, and freeze baseline": {
        "description":
            "Hold a requirements review with key stakeholders to check completeness, consistency, conflicts, and feasibility, then resolve unrealistic requests, approve the final set, and baseline it so future changes are handled through change control.",
        "discipline": "Review Board",
      },
      "Sealing interface verified": {
        "description":
            "Explain what sealing conditions, materials, and tolerances must be verified for this interface.",
        "discipline": "Mechanical Design",
      },
    };
    return data[name] ??
        {
          "description":
              "Record observations, design decisions, tolerance notes, simulation comments, or review outcomes here.",
          "discipline": "General Engineering",
        };
  }

  Future<void> _initData() async {
    final repo = ref.read(workspaceRepositoryProvider);
    var data = await repo.getWorkspaceById(widget.workspaceId);
    if (data == null) {
      final defaultInfo = _getDefaultInfo(widget.subStepName);
      data = WorkspaceData(
        id: widget.workspaceId,
        checklistItem: widget.subStepName,
        itemDescription: defaultInfo['description'] ?? '',
        discipline: defaultInfo['discipline'] ?? '',
      );
      await repo.saveWorkspace(data);
    }

    if (mounted) {
      setState(() {
        _currentData = data;
        _notesController.text = data!.notes;
        _engCommentsController.text = data.engineeringComments;
        _actionDescController.text = data.actionDescription;
        _assigneeController.text = data.assignee;
        _priorityController.text = data.priority;
        _disciplineController.text = data.discipline;
        _isLoading = false;
      });
    }
  }

  Future<void> _saveData() async {
    final repo = ref.read(workspaceRepositoryProvider);
    final updated = _currentData!.copyWith(
      notes: _notesController.text,
      engineeringComments: _engCommentsController.text,
      actionDescription: _actionDescController.text,
      assignee: _assigneeController.text,
      priority: _priorityController.text,
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
      backgroundColor: isDark
          ? const Color(0xFF111827)
          : const Color(0xFFF9F8F5),
      appBar: AppBar(
        title: Text(
          '${widget.projectName} / ${widget.stageName}',
          style: const TextStyle(fontSize: 16),
          overflow: TextOverflow.ellipsis,
        ),
        backgroundColor: isDark ? const Color(0xFF1F2937) : Colors.white,
        foregroundColor: isDark ? Colors.white : Colors.black87,
        elevation: 0,
        actions: [
          TextButton.icon(
            onPressed: () async {
              await _saveData();
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Progress Saved'),
                  backgroundColor: Color(0xFF006D6A),
                ),
              );
            },
            icon: const Icon(Icons.save, color: Color(0xFF006D6A), size: 20),
            label: const Text(
              'Save Progress',
              style: TextStyle(color: Color(0xFF006D6A)),
            ),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: SingleChildScrollView(
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
                    children: [primary, const SizedBox(height: 16), secondary],
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
    );
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
          const SizedBox(height: 16),
          _LabelText('Engineering Comments', isDark: isDark),
          TextField(
            controller: _engCommentsController,
            maxLines: 4,
            style: TextStyle(color: isDark ? Colors.white : Colors.black87),
            decoration: _boxDecoration('Enter engineering comments...', isDark),
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
          const SizedBox(height: 16),
          _LabelText('Priority', isDark: isDark),
          DropdownButtonFormField<String>(
            initialValue: _priorityController.text,
            dropdownColor: isDark ? const Color(0xFF1F2937) : Colors.white,
            style: TextStyle(color: isDark ? Colors.white : Colors.black87),
            decoration: _boxDecoration('', isDark),
            items: [
              'High',
              'Medium',
              'Low',
            ].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
            onChanged: (v) {
              if (v != null) _priorityController.text = v;
            },
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
