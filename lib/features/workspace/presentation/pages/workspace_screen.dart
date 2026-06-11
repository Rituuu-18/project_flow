import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:engineering_werk/features/workspace/domain/entities/workspace_data.dart';
import 'package:engineering_werk/features/workspace/presentation/providers/workspace_provider.dart';
import 'package:engineering_werk/features/settings/presentation/providers/theme_provider.dart';
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

  late TextEditingController _descController;
  late TextEditingController _notesController;
  late TextEditingController _engCommentsController;
  late TextEditingController _actionDescController;
  late TextEditingController _assigneeController;
  late TextEditingController _priorityController;
  late TextEditingController _disciplineController;

  @override
  void initState() {
    super.initState();
    _descController = TextEditingController();
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
    _descController.dispose();
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
        "description": "Clarify the core problem the product must solve and for whom by defining use cases, user personas, and operating context, then define what is included in the project and what is explicitly out of scope to prevent feature creep.",
        "discipline": "Systems Engineering"
      },
      "Identify stakeholders and interfaces": {
        "description": "List all stakeholders including customers, internal departments, regulatory bodies, and suppliers, then identify the products, standards, infrastructure, or software interfaces the system must connect to or remain compatible with.",
        "discipline": "Systems Engineering"
      },
      "Capture user and business needs": {
        "description": "Gather high-level needs from interviews, workshops, field observations, issue reports, and competitor inputs, then translate them into structured needs such as reduced maintenance effort, faster installation, increased throughput, or compliance with a required standard.",
        "discipline": "Product Definition"
      },
      "Derive functional requirements": {
        "description": "Convert stakeholder and business needs into functions the system must perform, such as lifting a target load, logging data at a defined interval, or detecting overload and stopping, and define measurable success criteria for each function.",
        "discipline": "Requirements"
      },
      "Define performance and quality targets": {
        "description": "Specify targets for capacity, speed, efficiency, noise, energy use, lifetime, reliability, MTBF, and define robustness expectations such as temperature, vibration, IP rating, safety integrity, and allowed failure rates.",
        "discipline": "Requirements"
      },
      "Establish constraints and boundaries": {
        "description": "Document regulatory norms, company standards, safety rules, preferred technologies, material choices, platform reuse rules, and capture business constraints such as target cost, selling price, development budget, milestones, and target markets.",
        "discipline": "Program Management"
      },
      "Non-functional requirements": {
        "description": "Define usability and service expectations including ergonomics, accessibility, installation time, maintenance intervals, service access, required tools, and operational expectations such as maintainability, diagnostics, data logging, cybersecurity, documentation, and labeling.",
        "discipline": "Lifecycle Engineering"
      },
      "Validation and testability definition": {
        "description": "For each requirement, define how it will be verified through analysis, simulation, inspection, lab testing, field testing, or certification, and ensure each one is specific, measurable, achievable, relevant, time-bound, and traceable to a validation method.",
        "discipline": "Verification"
      },
      "Requirements document and structure": {
        "description": "Compile the requirements into a structured Requirements Specification or PRD with sections for scope, stakeholders, functional requirements, non-functional requirements, constraints, and verification, and use requirement IDs and hierarchy such as REQ-001 and REQ-001-a for traceability.",
        "discipline": "Documentation"
      },
      "Review, negotiate, and freeze baseline": {
        "description": "Hold a requirements review with key stakeholders to check completeness, consistency, conflicts, and feasibility, then resolve unrealistic requests, approve the final set, and baseline it so future changes are handled through change control.",
        "discipline": "Review Board"
      },
      "Sealing interface verified": {
        "description": "Explain what sealing conditions, materials, and tolerances must be verified for this interface.",
        "discipline": "Mechanical Design"
      }
    };
    return data[name] ?? {
      "description": "Record observations, design decisions, tolerance notes, simulation comments, or review outcomes here.",
      "discipline": "General Engineering"
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
        _descController.text = data!.itemDescription;
        _notesController.text = data.notes;
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
      itemDescription: _descController.text,
      notes: _notesController.text,
      engineeringComments: _engCommentsController.text,
      actionDescription: _actionDescController.text,
      assignee: _assigneeController.text,
      priority: _priorityController.text,
      discipline: _disciplineController.text,
    );
    await repo.saveWorkspace(updated);
    setState(() {
      _currentData = updated;
    });
  }

  void _addActivityLog(String log) {
    setState(() {
      _currentData = _currentData!.copyWith(
        activityLogs: [..._currentData!.activityLogs, "${DateFormat('HH:mm').format(DateTime.now())} - $log"]
      );
    });
    _saveData();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    
    final themeMode = ref.watch(themeProvider);
    final isDark = themeMode == ThemeMode.dark || 
                 (themeMode == ThemeMode.system && MediaQuery.of(context).platformBrightness == Brightness.dark);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF111827) : const Color(0xFFF9F8F5),
      appBar: AppBar(
        title: Text('${widget.projectName} / ${widget.stageName}', style: const TextStyle(fontSize: 16)),
        backgroundColor: isDark ? const Color(0xFF1F2937) : Colors.white,
        foregroundColor: isDark ? Colors.white : Colors.black87,
        elevation: 0,
        actions: [
          TextButton.icon(
             onPressed: () async {
               await _saveData();
               if (!mounted) return;
               ScaffoldMessenger.of(context).showSnackBar(
                 const SnackBar(content: Text('Progress Saved'), backgroundColor: Color(0xFF006D6A)),
               );
             },
             icon: const Icon(Icons.save, color: Color(0xFF006D6A), size: 20),
             label: const Text('Save Progress', style: TextStyle(color: Color(0xFF006D6A))),
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
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
              style: TextStyle(fontSize: 16, color: isDark ? Colors.grey[400] : Colors.grey[600]),
            ),
            const SizedBox(height: 24),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 3,
                  child: Column(
                    children: [
                      _buildItemDetailsCard(isDark),
                      const SizedBox(height: 16),
                      _buildAddDetailsCard(isDark),
                      const SizedBox(height: 16),
                      _buildEvidenceCard(isDark),
                      const SizedBox(height: 16),
                      _buildActionRequiredCard(isDark),
                    ],
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  flex: 2,
                  child: Column(
                    children: [
                      _buildAssignmentCard(isDark),
                      const SizedBox(height: 16),
                      _buildStakeholdersCard(isDark),
                      const SizedBox(height: 16),
                      _buildActivityCard(isDark),
                    ],
                  ),
                ),
              ],
            )
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
          _LabelText('Checklist item', isDark: isDark),
          _BoxContext(widget.subStepName, isDark: isDark),
          const SizedBox(height: 16),
          _LabelText('Description', isDark: isDark),
          TextField(
            controller: _descController,
            maxLines: 3,
            style: TextStyle(color: isDark ? Colors.white : Colors.black87),
            decoration: _boxDecoration('Enter description...', isDark),
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
      )
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
              border: Border.all(color: isDark ? Colors.grey[800]! : Colors.grey.withValues(alpha: 0.4), style: BorderStyle.solid),
              borderRadius: BorderRadius.circular(12),
              color: isDark ? const Color(0xFF111827) : const Color(0xFFF3F0EC),
            ),
            child: Column(
              children: [
                Icon(Icons.cloud_upload_outlined, size: 32, color: isDark ? Colors.grey[500] : Colors.grey),
                const SizedBox(height: 8),
                Text(
                  'Drop Images, PDFs, CAD Files, Drawings here', 
                  style: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () {
                     _addActivityLog('Uploaded a new evidence file.');
                  }, 
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF006D6A),
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Browse Files'),
                ),
              ],
            ),
          )
        ],
      )
    );
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
            value: _priorityController.text,
            dropdownColor: isDark ? const Color(0xFF1F2937) : Colors.white,
            style: TextStyle(color: isDark ? Colors.white : Colors.black87),
            decoration: _boxDecoration('', isDark),
            items: ['High', 'Medium', 'Low'].map((s) => DropdownMenuItem(value: s, child: Text(s))).toList(),
            onChanged: (v) {
              if (v != null) setState(() => _priorityController.text = v);
            },
          ),
        ]
      )
    );
  }

  Widget _buildAssignmentCard(bool isDark) {
    final reviewsAsync = ref.watch(designReviewsStreamProvider);
    final reviews = reviewsAsync.value ?? [];
    final review = reviews.where((r) => r.id == widget.reviewId).firstOrNull;
    final hasStakeholders = review != null && review.stakeholders.isNotEmpty;

    return _SectionCard(
      title: 'Assignment',
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _LabelText('Responsible Person', isDark: isDark),
          if (hasStakeholders)
            DropdownButtonFormField<String>(
              value: review.stakeholders.any((s) => s.name == _assigneeController.text) && _assigneeController.text.isNotEmpty
                  ? _assigneeController.text
                  : null,
              dropdownColor: isDark ? const Color(0xFF1F2937) : Colors.white,
              style: TextStyle(color: isDark ? Colors.white : Colors.black87),
              decoration: _boxDecoration('Select responsible...', isDark),
              items: review.stakeholders.map((s) => DropdownMenuItem(value: s.name, child: Text(s.name))).toList(),
              onChanged: (val) {
                if (val != null) {
                  final st = review.stakeholders.firstWhere((s) => s.name == val);
                  setState(() {
                    _assigneeController.text = val;
                    _disciplineController.text = st.role;
                    _currentData = _currentData!.copyWith(
                      assignee: val,
                      discipline: st.role,
                    );
                  });
                  _addActivityLog('Assigned responsible person to $val (${st.role})');
                }
              },
            )
          else
            TextField(
              controller: _assigneeController,
              style: TextStyle(color: isDark ? Colors.white : Colors.black87),
              decoration: _boxDecoration('Assignee name...', isDark),
              onChanged: (val) {
                setState(() {
                  _currentData = _currentData!.copyWith(assignee: val);
                });
              },
            ),
          const SizedBox(height: 12),
          _LabelText('Discipline', isDark: isDark),
          if (hasStakeholders)
            _BoxContext(_disciplineController.text.isEmpty ? 'Not set' : _disciplineController.text, isDark: isDark)
          else
            TextField(
              controller: _disciplineController,
              style: TextStyle(color: isDark ? Colors.white : Colors.black87),
              decoration: _boxDecoration('Discipline...', isDark),
              onChanged: (val) {
                setState(() {
                  _currentData = _currentData!.copyWith(discipline: val);
                });
              },
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
                    data: isDark ? ThemeData.dark().copyWith(
                      colorScheme: const ColorScheme.dark(primary: Color(0xFF006D6A)),
                    ) : ThemeData.light().copyWith(
                      colorScheme: const ColorScheme.light(primary: Color(0xFF006D6A)),
                    ),
                    child: child!,
                  );
                }
              );
              if (d != null) {
                setState(() { _currentData = _currentData!.copyWith(dueDate: d); });
                _addActivityLog('Changed due date to ${DateFormat('yyyy-MM-dd').format(d)}');
              }
            },
            child: _BoxContext(_currentData!.dueDate == null ? 'Select date' : DateFormat('dd MMM yyyy').format(_currentData!.dueDate!), isDark: isDark),
          ),
        ],
      ),
    );
  }

  Widget _buildStakeholdersCard(bool isDark) {
    final reviewsAsync = ref.watch(designReviewsStreamProvider);
    final reviews = reviewsAsync.value ?? [];
    final review = reviews.where((r) => r.id == widget.reviewId).firstOrNull;
    final displayStakeholders = review != null 
        ? review.stakeholders.map((s) => '${s.name} - ${s.role}').toList()
        : _currentData!.stakeholders;

    return _SectionCard(
      title: 'Stakeholders',
      isDark: isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ...displayStakeholders.map((s) => ListTile(
            leading: const Icon(Icons.person_outline, size: 18, color: Color(0xFF006D6A)),
            title: Text(s, style: TextStyle(fontSize: 14, color: isDark ? Colors.white : Colors.black87)),
            dense: true,
            contentPadding: EdgeInsets.zero,
          )),
          if (displayStakeholders.isEmpty)
            Text('No stakeholders added yet.', style: TextStyle(color: isDark ? Colors.grey[500] : Colors.grey)),
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
          ..._currentData!.activityLogs.map((log) => Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF111827) : Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: isDark ? Colors.grey[800]! : Colors.grey.withValues(alpha: 0.3)),
              ),
              child: Text(log, style: TextStyle(fontSize: 13, color: isDark ? Colors.grey[300] : Colors.black87)),
            ),
          )),
          if (_currentData!.activityLogs.isEmpty)
             Text('No recent activity.', style: TextStyle(color: isDark ? Colors.grey[500] : Colors.grey)),
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
          letterSpacing: 1.1
        )
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
        border: Border.all(color: isDark ? Colors.grey[800]! : Colors.grey.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(text, style: TextStyle(fontSize: 14, color: isDark ? Colors.white : Colors.black87)),
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
      borderSide: BorderSide(color: isDark ? Colors.grey[800]! : Colors.grey.withValues(alpha: 0.3))
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12), 
      borderSide: BorderSide(color: isDark ? Colors.grey[800]! : Colors.grey.withValues(alpha: 0.3))
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(12), 
      borderSide: const BorderSide(color: Color(0xFF006D6A), width: 1.5)
    ),
  );
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  final bool isDark;
  const _SectionCard({required this.title, required this.child, required this.isDark});
  
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F2937) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? Colors.grey[800]! : Colors.grey.withValues(alpha: 0.3)),
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
               color: isDark ? Colors.grey[400] : Colors.grey
             )
           ),
           const SizedBox(height: 16),
           child,
        ],
      ),
    );
  }
}
