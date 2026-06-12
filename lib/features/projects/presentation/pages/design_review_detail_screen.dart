import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import 'package:engineering_werk/core/utils/enums.dart';
import 'package:engineering_werk/features/reviews/domain/entities/design_review.dart';
import 'package:engineering_werk/features/reviews/domain/entities/stage.dart';
import 'package:engineering_werk/features/reviews/domain/entities/sub_step.dart';
import 'package:engineering_werk/features/reviews/domain/entities/stakeholder.dart';
import 'package:engineering_werk/features/reviews/presentation/providers/design_review_provider.dart';
import 'package:engineering_werk/features/settings/presentation/providers/theme_provider.dart';

class DesignReviewDetailScreen extends ConsumerStatefulWidget {
  final String reviewId;

  const DesignReviewDetailScreen({super.key, required this.reviewId});

  @override
  ConsumerState<DesignReviewDetailScreen> createState() =>
      _DesignReviewDetailScreenState();
}

class _DesignReviewDetailScreenState
    extends ConsumerState<DesignReviewDetailScreen> {
  final TextEditingController _stakeholderNameController =
      TextEditingController();
  final TextEditingController _stakeholderRoleController =
      TextEditingController();

  @override
  void dispose() {
    _stakeholderNameController.dispose();
    _stakeholderRoleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reviewsAsync = ref.watch(designReviewsStreamProvider);
    final themeMode = ref.watch(themeProvider);
    final isDark =
        themeMode == ThemeMode.dark ||
        (themeMode == ThemeMode.system &&
            MediaQuery.of(context).platformBrightness == Brightness.dark);

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF111827) : Colors.white,
      body: SafeArea(
        child: reviewsAsync.when(
          data: (reviews) {
            final review = reviews
                .where((r) => r.id == widget.reviewId)
                .firstOrNull;
            if (review == null) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text('Design Review not found'),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => context.pop(),
                      child: const Text('Go Back'),
                    ),
                  ],
                ),
              );
            }

            return SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: MediaQuery.sizeOf(context).width < 600 ? 16 : 24,
                vertical: 24,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHeader(isDark),
                  const SizedBox(height: 32),
                  _buildIntroSection(isDark),
                  const SizedBox(height: 24),
                  _buildBackButton(isDark),
                  const SizedBox(height: 32),
                  _buildStakeholdersSection(review, isDark),
                  const SizedBox(height: 48),
                  ...review.stages.asMap().entries.map((e) {
                    return _buildStageCard(review, e.value, e.key, isDark);
                  }),
                  const SizedBox(height: 100),
                ],
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(child: Text('Error: $err')),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Image.asset(
              'assets/logo.jpeg',
              height: 32,
              errorBuilder: (context, error, stackTrace) => const Icon(
                Icons.broken_image_outlined,
                color: Color(0xFF006D6A),
                size: 32,
              ),
            ),
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                'Design reviews',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF1F2937),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          'Track active reviews, open completed records,\nand start a new design review from one place.',
          style: TextStyle(
            fontSize: 15,
            color: isDark ? Colors.grey[400] : Colors.grey[600],
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildIntroSection(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Divider(),
        const SizedBox(height: 32),
        Text(
          'Design review steps',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : const Color(0xFF1F2937),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'The second page shows the full engineering review lifecycle in sequence so the user can understand the project flow from requirements through continuous improvement.',
          style: TextStyle(
            fontSize: 16,
            color: isDark ? Colors.grey[400] : Colors.grey[600],
            height: 1.6,
          ),
        ),
      ],
    );
  }

  Widget _buildBackButton(bool isDark) {
    return OutlinedButton(
      onPressed: () => context.pop(),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        side: BorderSide(color: isDark ? Colors.grey[700]! : Colors.grey[300]!),
      ),
      child: Text(
        'Back to Dashboard',
        style: TextStyle(
          color: isDark ? Colors.grey[300] : const Color(0xFF1F2937),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildStakeholdersSection(DesignReview review, bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F2937) : const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final label = Text(
                'STAKEHOLDERS',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.grey[400] : Colors.grey[500],
                  letterSpacing: 1.2,
                ),
              );
              final fields = Column(
                children: [
                  _buildSTField(
                    _stakeholderNameController,
                    'Stakeholder name',
                    isDark,
                  ),
                  const SizedBox(height: 12),
                  _buildSTField(
                    _stakeholderRoleController,
                    'Role or discipline',
                    isDark,
                  ),
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton(
                      onPressed: () => _addStakeholder(review),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF006D6A),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 24,
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Add stakeholder',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ],
              );

              if (constraints.maxWidth < 600) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [label, const SizedBox(height: 16), fields],
                );
              }

              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  label,
                  const SizedBox(width: 24),
                  Expanded(child: fields),
                ],
              );
            },
          ),
          if (review.stakeholders.isNotEmpty) ...[
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),
            ...review.stakeholders.map(
              (s) => Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: Row(
                  children: [
                    const Icon(
                      Icons.person_outline,
                      size: 18,
                      color: Color(0xFF006D6A),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${s.name} - ${s.role}',
                      style: TextStyle(
                        color: isDark ? Colors.grey[300] : Colors.black87,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSTField(
    TextEditingController controller,
    String hint,
    bool isDark,
  ) {
    return TextField(
      controller: controller,
      style: TextStyle(color: isDark ? Colors.white : Colors.black87),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: isDark ? Colors.grey[600] : Colors.grey[400],
          fontSize: 16,
        ),
        filled: true,
        fillColor: isDark ? const Color(0xFF111827) : Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDark ? Colors.grey[800]! : Colors.grey[300]!,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF006D6A), width: 1.5),
        ),
      ),
    );
  }

  Widget _buildStageCard(
    DesignReview review,
    Stage stage,
    int index,
    bool isDark,
  ) {
    final isMobile = MediaQuery.sizeOf(context).width < 700;
    return Padding(
      padding: const EdgeInsets.only(bottom: 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                margin: EdgeInsets.only(top: isMobile ? 7 : 10),
                width: isMobile ? 16 : 24,
                height: isMobile ? 16 : 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFF006D6A),
                    width: isMobile ? 3 : 4,
                  ),
                ),
              ),
              SizedBox(width: isMobile ? 10 : 20),
              Expanded(
                child: Container(
                  padding: EdgeInsets.all(isMobile ? 16 : 28),
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF1F2937).withValues(alpha: 0.5)
                        : const Color(0xFFF9FAFB),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildStageHeading(stage, index, isDark, isMobile),
                      SizedBox(height: isMobile ? 24 : 32),
                      _buildSubStepsTable(review, stage, isDark),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStageHeading(
    Stage stage,
    int index,
    bool isDark,
    bool isMobile,
  ) {
    final title = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'STEP ${index + 1}',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.grey[500] : Colors.grey[400],
            letterSpacing: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          stage.name,
          style: TextStyle(
            fontSize: isMobile ? 24 : 28,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : const Color(0xFF111827),
            height: 1.15,
          ),
        ),
      ],
    );
    final description = Text(
      _getStageDescription(stage.name),
      style: TextStyle(
        fontSize: 14,
        color: isDark ? Colors.grey[400] : Colors.grey[600],
        height: 1.5,
      ),
    );

    if (isMobile) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [title, const SizedBox(height: 12), description],
      );
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(child: title),
        const SizedBox(width: 16),
        Expanded(flex: 2, child: description),
      ],
    );
  }

  Widget _buildSubStepsTable(DesignReview review, Stage stage, bool isDark) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < 620) {
          return Column(
            children: stage.subSteps
                .map(
                  (subStep) =>
                      _buildMobileSubStepCard(review, stage, subStep, isDark),
                )
                .toList(),
          );
        }

        return Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF111827) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: Table(
            columnWidths: const {
              0: FlexColumnWidth(2.5),
              1: FlexColumnWidth(1.5),
              2: IntrinsicColumnWidth(),
            },
            defaultVerticalAlignment: TableCellVerticalAlignment.middle,
            children: [
              TableRow(
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.grey[800]!.withValues(alpha: 0.3)
                      : const Color(0xFFF3F4F6),
                ),
                children: [
                  _buildTableHeader('SUBSTEP', isDark),
                  _buildTableHeader('STATUS', isDark),
                  _buildTableHeader('ACTION', isDark),
                ],
              ),
              ...stage.subSteps.map(
                (ss) => _buildSubStepRow(review, stage, ss, isDark),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMobileSubStepCard(
    DesignReview review,
    Stage stage,
    SubStep subStep,
    bool isDark,
  ) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF111827) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            subStep.name,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.grey[200] : Colors.grey[800],
              height: 1.35,
            ),
          ),
          const SizedBox(height: 14),
          DropdownButtonFormField<StageStatus>(
            initialValue: subStep.status,
            isExpanded: true,
            dropdownColor: isDark ? const Color(0xFF1F2937) : Colors.white,
            decoration: InputDecoration(
              labelText: 'Status',
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            items: const [
              DropdownMenuItem(
                value: StageStatus.notStarted,
                child: Text('Open'),
              ),
              DropdownMenuItem(
                value: StageStatus.inProgress,
                child: Text('In Progress'),
              ),
              DropdownMenuItem(
                value: StageStatus.completed,
                child: Text('Completed'),
              ),
            ],
            onChanged: (value) {
              if (value != null) {
                _updateSubStepStatus(review, stage, subStep, value);
              }
            },
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => _openWorkspace(review, stage, subStep),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                side: BorderSide(
                  color: isDark ? Colors.grey[700]! : Colors.grey[400]!,
                ),
              ),
              child: const Text(
                'Open workspace',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _openWorkspace(DesignReview review, Stage stage, SubStep subStep) {
    context.push(
      Uri(
        path: '/workspace/${subStep.workspaceId}',
        queryParameters: {
          'reviewId': review.id,
          'projectName': review.name,
          'stageName': stage.name,
          'subStepName': subStep.name,
        },
      ).toString(),
    );
  }

  Widget _buildTableHeader(String label, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: isDark ? Colors.grey[400] : Colors.grey[500],
          letterSpacing: 1.0,
        ),
      ),
    );
  }

  TableRow _buildSubStepRow(
    DesignReview review,
    Stage stage,
    SubStep ss,
    bool isDark,
  ) {
    return TableRow(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: isDark ? Colors.grey[800]! : Colors.grey[100]!,
          ),
        ),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Text(
            ss.name,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.grey[300] : Colors.grey[800],
              height: 1.3,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[900] : Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
              ),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<StageStatus>(
                value: ss.status,
                isDense: true,
                isExpanded: true, // Allow it to fill the column
                dropdownColor: isDark ? const Color(0xFF1F2937) : Colors.white,
                icon: Icon(
                  Icons.arrow_drop_down,
                  color: isDark ? Colors.grey[500] : Colors.grey[400],
                  size: 20,
                ),
                style: TextStyle(
                  fontSize: 13,
                  color: isDark ? Colors.white : Colors.black87,
                ),
                items: const [
                  DropdownMenuItem(
                    value: StageStatus.notStarted,
                    child: Text('Open', overflow: TextOverflow.ellipsis),
                  ),
                  DropdownMenuItem(
                    value: StageStatus.inProgress,
                    child: Text('In Progress', overflow: TextOverflow.ellipsis),
                  ),
                  DropdownMenuItem(
                    value: StageStatus.completed,
                    child: Text('Completed', overflow: TextOverflow.ellipsis),
                  ),
                ],
                onChanged: (val) {
                  if (val != null) {
                    _updateSubStepStatus(review, stage, ss, val);
                  }
                },
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8),
          child: OutlinedButton(
            onPressed: () => _openWorkspace(review, stage, ss),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              side: BorderSide(
                color: isDark ? Colors.grey[700]! : Colors.grey[400]!,
              ),
              backgroundColor: isDark ? Colors.transparent : Colors.white,
            ),
            child: Text(
              'Open workspace',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.grey[200] : const Color(0xFF374151),
              ),
            ),
          ),
        ),
      ],
    );
  }

  String _getStageDescription(String stageName) {
    switch (stageName) {
      case 'Requirements':
        return 'Define the problem, project scope, stakeholders, requirements, constraints, and verification basis.';
      case 'Concept Review':
        return 'Compare solution concepts, feasibility, risks, and the preferred approach before deeper design work.';
      case 'Preliminary Design Review':
        return 'Confirm architecture, interfaces, requirement allocation, and early engineering evidence.';
      case 'Detailed Design Review':
        return 'Verify CAD, drawings, interfaces, materials, analyses, and manufacturability details.';
      case 'Simulation Review':
        return 'Review assumptions, load cases, model quality, and correlation plans.';
      case 'Prototype Review':
        return 'Check the first physical build, fit, function, and assembly or usability issues.';
      case 'Testing Validation':
        return 'Ensure test plans, execution, results, and corrective actions support compliance.';
      case 'Manufacturing Readiness':
        return 'Confirm tooling, suppliers, instructions, and process capability for production.';
      case 'Final Release':
        return 'Freeze the released configuration and complete cross-functional sign-off.';
      case 'Continuous Improvement':
        return 'Focus post-release work on weight, cost, and assembly improvements.';
      default:
        return 'Engineering review and validation for this development phase.';
    }
  }

  void _addStakeholder(DesignReview review) {
    if (_stakeholderNameController.text.isEmpty) return;

    final stakeholder = Stakeholder(
      id: const Uuid().v4(),
      name: _stakeholderNameController.text,
      role: _stakeholderRoleController.text,
    );

    ref
        .read(designReviewNotifierProvider.notifier)
        .addStakeholder(review.id, stakeholder);

    _stakeholderNameController.clear();
    _stakeholderRoleController.clear();
    FocusScope.of(context).unfocus();
  }

  void _updateSubStepStatus(
    DesignReview review,
    Stage stage,
    SubStep ss,
    StageStatus newStatus,
  ) {
    final updatedSubSteps = stage.subSteps
        .map((s) => s.id == ss.id ? s.copyWith(status: newStatus) : s)
        .toList();

    // Calculate progress
    int completedCount = updatedSubSteps
        .where((s) => s.status == StageStatus.completed)
        .length;
    double progress = updatedSubSteps.isEmpty
        ? 0.0
        : completedCount / updatedSubSteps.length;

    final updatedStage = stage.copyWith(
      subSteps: updatedSubSteps,
      progress: progress,
      status: progress == 1.0
          ? StageStatus.completed
          : (progress > 0 ? StageStatus.inProgress : StageStatus.notStarted),
    );

    final updatedStages = review.stages
        .map((s) => s.id == updatedStage.id ? updatedStage : s)
        .toList();

    // Overall project progress
    int totalStages = updatedStages.length;
    double totalProgress =
        updatedStages.fold(0.0, (sum, s) => sum + s.progress) / totalStages;

    final updatedReview = review.copyWith(
      stages: updatedStages,
      progress: totalProgress,
      status: totalProgress == 1.0
          ? ProjectStatus.completed
          : ProjectStatus.active,
    );

    ref.read(designReviewNotifierProvider.notifier).updateReview(updatedReview);
  }
}
