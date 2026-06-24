import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:engineering_werk/features/dashboard/presentation/widgets/evalio_logo_svg.dart';
import 'package:uuid/uuid.dart';

import 'package:engineering_werk/core/utils/enums.dart';
import 'package:engineering_werk/features/dashboard/presentation/theme/dashboard_design.dart';
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
      backgroundColor: DashboardDesign.canvas(context),
      body: SafeArea(
        bottom: false,
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
                      onPressed: () => context.go('/'),
                      child: const Text('Go Back'),
                    ),
                  ],
                ),
              );
            }

            final horizontalPadding = MediaQuery.sizeOf(context).width < 600
                ? 16.0
                : 24.0;

            return Column(
              children: [
                Padding(
                  padding: EdgeInsets.fromLTRB(
                    horizontalPadding,
                    24,
                    horizontalPadding,
                    0,
                  ),
                  child: _buildHeader(review),
                ),
                Expanded(
                  child: CustomScrollView(
                    cacheExtent: 900,
                    slivers: [
                      SliverPadding(
                        padding: EdgeInsets.fromLTRB(
                          horizontalPadding,
                          24,
                          horizontalPadding,
                          0,
                        ),
                        sliver: SliverToBoxAdapter(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _buildBackButton(isDark),
                              const SizedBox(height: 32),
                              _buildStakeholdersSection(review, isDark),
                              const SizedBox(height: 48),
                            ],
                          ),
                        ),
                      ),
                      SliverPadding(
                        padding: EdgeInsets.fromLTRB(
                          horizontalPadding,
                          0,
                          horizontalPadding,
                          16,
                        ),
                        sliver: SliverToBoxAdapter(
                          child: _buildIntroSection(),
                        ),
                      ),
                      SliverPadding(
                        padding: EdgeInsets.symmetric(horizontal: horizontalPadding),
                        sliver: SliverList.builder(
                          itemCount: review.stages.length,
                          itemBuilder: (context, index) => RepaintBoundary(
                            child: _buildStageCard(
                              review,
                              review.stages[index],
                              index,
                              isDark,
                            ),
                          ),
                        ),
                      ),
                      const SliverToBoxAdapter(child: SizedBox(height: 100)),
                    ],
                  ),
                ),
              ],
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (err, stack) => Center(child: Text('Error: $err')),
        ),
      ),
    );
  }

  Widget _buildHeader(DesignReview review) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.only(bottom: 18),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(color: DashboardDesign.border(context)),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(11),
                  border: Border.all(
                    color: DashboardDesign.border(context),
                  ),
                ),
                clipBehavior: Clip.antiAlias,
                child: SvgPicture.string(
                  EvalioLogoSvg.getMonogram(isDark: false),
                  width: 40,
                  height: 40,
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      review.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        color: DashboardDesign.text(context),
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      'Design review workflow',
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
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: DashboardDesign.subtleSurface(context),
                  borderRadius: BorderRadius.circular(99),
                  border: Border.all(color: DashboardDesign.border(context)),
                ),
                child: Text(
                  '${review.stages.length} steps',
                  style: TextStyle(
                    color: DashboardDesign.text(context),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildIntroSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Design review steps',
          style: TextStyle(
            fontSize: 32,
            fontWeight: FontWeight.bold,
            color: DashboardDesign.text(context),
          ),
        ),
      ],
    );
  }

  Widget _buildBackButton(bool isDark) {
    return OutlinedButton(
      onPressed: () => context.go('/'),
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

  String getStageDisplayTitle(String stageName) {
    switch (stageName) {
      case 'Requirements':
        return 'REQUIREMENTS';
      case 'Concept':
        return 'CONCEPT';
      case 'Preliminary Design':
        return 'PRELIMINARY DESIGN';
      case 'Detailed Design':
        return 'DETAILED DESIGN';
      case 'Simulation (FEA,CFD...)':
        return 'SIMULATION REVIEW';
      case 'Prototype':
        return 'PROTOTYPE';
      case 'Testing Validation':
        return 'TESTING';
      case 'Manufacturing Readiness':
        return 'MANUFACTURING';
      case 'Final Release':
        return 'FINAL RELEASE';
      case 'Continuous Improvement':
        return 'CONTINUOUS IMPROVEMENT';
      default:
        return stageName.toUpperCase();
    }
  }

  Widget _buildStageCard(
    DesignReview review,
    Stage stage,
    int index,
    bool isDark,
  ) {
    final isMobile = MediaQuery.sizeOf(context).width < 700;

    if (isMobile) {
      return _buildMobileStageCard(review, stage, index, isDark);
    } else {
      return _buildDesktopStageCard(review, stage, index, isDark);
    }
  }

  Widget _buildDesktopStageCard(
    DesignReview review,
    Stage stage,
    int index,
    bool isDark,
  ) {
    const stageIcons = <String, IconData>{
      'Requirements': Icons.assignment_ind_outlined,
      'Concept': Icons.lightbulb_outline_rounded,
      'Preliminary Design': Icons.architecture_rounded,
      'Detailed Design': Icons.view_in_ar_outlined,
      'Simulation (FEA,CFD...)': Icons.query_stats_rounded,
      'Prototype': Icons.precision_manufacturing_outlined,
      'Testing Validation': Icons.biotech_rounded,
      'Manufacturing Readiness': Icons.factory_outlined,
      'Final Release': Icons.verified_outlined,
      'Continuous Improvement': Icons.trending_up_rounded,
    };
    final iconData = stageIcons[stage.name] ?? Icons.assignment_outlined;
    final displayTitle = getStageDisplayTitle(stage.name);

    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: DashboardDesign.surface(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: DashboardDesign.border(context),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Left Blue Gradient Card
            Container(
              width: 150,
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Color(0xFF1E60D5),
                    Color(0xFF0C3CA6),
                  ],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
              padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Step Number
                  Text(
                    '${index + 1}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 48,
                      fontWeight: FontWeight.w900,
                      height: 1.0,
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Title
                  Expanded(
                    child: Center(
                      child: Text(
                        displayTitle,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                          height: 1.25,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Icon
                  Icon(
                    iconData,
                    color: Colors.white,
                    size: 36,
                  ),
                ],
              ),
            ),
            // Vertical divider line
            Container(
              width: 1,
              color: DashboardDesign.border(context),
            ),
            // Right Sub-steps Panel
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ...stage.subSteps.asMap().entries.map((entry) {
                      final subStepIndex = entry.key;
                      final subStep = entry.value;
                      return Column(
                        children: [
                          _buildSubStepRowItem(review, stage, subStep, subStepIndex, isDark),
                          if (subStepIndex < stage.subSteps.length - 1)
                            Divider(
                              height: 8,
                              thickness: 0.5,
                              color: isDark ? Colors.grey[800] : Colors.grey[200],
                              indent: 12,
                              endIndent: 12,
                            ),
                        ],
                      );
                    }),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileStageCard(
    DesignReview review,
    Stage stage,
    int index,
    bool isDark,
  ) {
    const stageIcons = <String, IconData>{
      'Requirements': Icons.assignment_ind_outlined,
      'Concept': Icons.lightbulb_outline_rounded,
      'Preliminary Design': Icons.architecture_rounded,
      'Detailed Design': Icons.view_in_ar_outlined,
      'Simulation (FEA,CFD...)': Icons.query_stats_rounded,
      'Prototype': Icons.precision_manufacturing_outlined,
      'Testing Validation': Icons.biotech_rounded,
      'Manufacturing Readiness': Icons.factory_outlined,
      'Final Release': Icons.verified_outlined,
      'Continuous Improvement': Icons.trending_up_rounded,
    };
    final iconData = stageIcons[stage.name] ?? Icons.assignment_outlined;
    final displayTitle = getStageDisplayTitle(stage.name);

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: DashboardDesign.surface(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: DashboardDesign.border(context),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.05),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Top Blue Gradient Banner
          Container(
            height: 64,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF1E60D5),
                  Color(0xFF0C3CA6),
                ],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                // Step Number
                Text(
                  '${index + 1}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(width: 16),
                // Title
                Expanded(
                  child: Text(
                    displayTitle,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                // Icon
                Icon(
                  iconData,
                  color: Colors.white,
                  size: 28,
                ),
              ],
            ),
          ),
          // Sub-steps Panel
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ...stage.subSteps.asMap().entries.map((entry) {
                  final subStepIndex = entry.key;
                  final subStep = entry.value;
                  return Column(
                    children: [
                      _buildSubStepRowItem(review, stage, subStep, subStepIndex, isDark),
                      if (subStepIndex < stage.subSteps.length - 1)
                        Divider(
                          height: 8,
                          thickness: 0.5,
                          color: isDark ? Colors.grey[800] : Colors.grey[200],
                          indent: 8,
                          endIndent: 8,
                        ),
                    ],
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSubStepRowItem(
    DesignReview review,
    Stage stage,
    SubStep subStep,
    int subStepIndex,
    bool isDark,
  ) {
    final isNarrow = MediaQuery.sizeOf(context).width < 500;
    return InkWell(
      onTap: () => _openWorkspace(review, stage, subStep),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            // Sub-step index box
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                color: Colors.transparent,
                border: Border.all(
                  color: const Color(0xFF1E60D5),
                  width: 1.5,
                ),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Center(
                child: Text(
                  '${subStepIndex + 1}',
                  style: const TextStyle(
                    color: Color(0xFF1E60D5),
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Sub-step name
            Expanded(
              child: Text(
                subStep.name,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.grey[200] : Colors.grey[800],
                  height: 1.3,
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Status badge
            _buildStatusBadge(review, stage, subStep, isDark, isNarrow),
            const SizedBox(width: 8),
            // Open workspace chevron
            Icon(
              Icons.chevron_right_rounded,
              size: 18,
              color: isDark ? Colors.grey[600] : Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(
    DesignReview review,
    Stage stage,
    SubStep subStep,
    bool isDark,
    bool isNarrow,
  ) {
    Color bgColor;
    Color textColor;
    String label;
    IconData icon;

    switch (subStep.status) {
      case StageStatus.completed:
        bgColor = isDark ? const Color(0x204CAF50) : const Color(0xFFE8F5E9);
        textColor = isDark ? const Color(0xFF81C784) : const Color(0xFF2E7D32);
        label = 'Completed';
        icon = Icons.check_circle_rounded;
        break;
      case StageStatus.inProgress:
        bgColor = isDark ? const Color(0x202196F3) : const Color(0xFFE3F2FD);
        textColor = isDark ? const Color(0xFF64B5F6) : const Color(0xFF1565C0);
        label = 'In Progress';
        icon = Icons.pending_rounded;
        break;
      case StageStatus.notStarted:
        bgColor = isDark ? const Color(0x209E9E9E) : const Color(0xFFF5F5F5);
        textColor = isDark ? const Color(0xFFB0BEC5) : const Color(0xFF757575);
        label = 'Open';
        icon = Icons.radio_button_unchecked_rounded;
        break;
    }

    return PopupMenuButton<StageStatus>(
      initialValue: subStep.status,
      tooltip: 'Change Status',
      onSelected: (status) {
        _updateSubStepStatus(review, stage, subStep, status);
      },
      offset: const Offset(0, 30),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: DashboardDesign.border(context)),
      ),
      color: isDark ? const Color(0xFF1E2937) : Colors.white,
      child: Container(
        padding: isNarrow
            ? const EdgeInsets.all(8)
            : const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: textColor),
            if (!isNarrow) ...[
              const SizedBox(width: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
            ],
          ],
        ),
      ),
      itemBuilder: (context) => [
        PopupMenuItem(
          value: StageStatus.notStarted,
          child: Row(
            children: [
              Icon(Icons.radio_button_unchecked_rounded, size: 16, color: isDark ? const Color(0xFFB0BEC5) : const Color(0xFF757575)),
              const SizedBox(width: 8),
              Text('Open', style: TextStyle(color: isDark ? Colors.white : Colors.black87)),
            ],
          ),
        ),
        PopupMenuItem(
          value: StageStatus.inProgress,
          child: Row(
            children: [
              Icon(Icons.pending_rounded, size: 16, color: isDark ? const Color(0xFF64B5F6) : const Color(0xFF1565C0)),
              const SizedBox(width: 8),
              Text('In Progress', style: TextStyle(color: isDark ? Colors.white : Colors.black87)),
            ],
          ),
        ),
        PopupMenuItem(
          value: StageStatus.completed,
          child: Row(
            children: [
              Icon(Icons.check_circle_rounded, size: 16, color: isDark ? const Color(0xFF81C784) : const Color(0xFF2E7D32)),
              const SizedBox(width: 8),
              Text('Completed', style: TextStyle(color: isDark ? Colors.white : Colors.black87)),
            ],
          ),
        ),
      ],
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
