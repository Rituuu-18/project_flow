import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:uuid/uuid.dart';

import 'package:engineering_werk/core/utils/app_messenger.dart';
import 'package:engineering_werk/core/utils/enums.dart';
import 'package:engineering_werk/features/dashboard/presentation/theme/dashboard_design.dart';
import 'package:engineering_werk/features/reviews/domain/entities/design_review.dart';
import 'package:engineering_werk/features/reviews/domain/entities/stage.dart';
import 'package:engineering_werk/features/reviews/domain/entities/sub_step.dart';
import 'package:engineering_werk/features/reviews/domain/entities/stakeholder.dart';
import 'package:engineering_werk/features/reviews/domain/utils/drl_weights.dart';


import 'package:engineering_werk/core/localization/locale_provider.dart';
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
  int? _expandedStageIndex;
  bool _isStakeholdersExpanded = false;

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

    ref.watch(localeProvider);
    final t = ref.read(localeProvider.notifier).t;

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
                    Text(t('design_review_not_found')),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => context.go('/'),
                      child: Text(t('go_back')),
                    ),
                  ],
                ),
              );
            }

            final horizontalPadding = MediaQuery.sizeOf(context).width < 600
                ? 16.0
                : 24.0;
            final expandedStageIndex = _expandedStageIndex;

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
                              isExpanded: index == expandedStageIndex,
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
          error: (err, stack) => Center(child: Text('${t('try_again')}: $err')),
        ),
      ),
    );
  }

  Widget _buildHeader(DesignReview review) {
    final isDark = DashboardDesign.isDark(context);
    final t = ref.read(localeProvider.notifier).t;
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
              isDark
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
                        errorBuilder: (context, error, stackTrace) => Icon(
                          Icons.fact_check_outlined,
                          color: DashboardDesign.primary,
                          size: 28,
                        ),
                      ),
                    )
                  : Image.asset(
                      'assets/ed-logo.png',
                      height: 48,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => Icon(
                        Icons.fact_check_outlined,
                        color: DashboardDesign.primary,
                        size: 28,
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
                        letterSpacing: -0.3,
                      ),
                    ),
                    Text(
                      t('design_review_workflow'),
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
              IconButton(
                onPressed: () => context.go('/'),
                tooltip: t('back_to_dashboard'),
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
      ],
    );
  }

  Widget _buildIntroSection() {
    final t = ref.read(localeProvider.notifier).t;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          t('design_review_steps'),
          style: TextStyle(
            fontSize: 21,
            fontWeight: FontWeight.bold,
            color: DashboardDesign.text(context),
          ),
        ),
      ],
    );
  }



  Widget _buildStakeholdersSection(DesignReview review, bool isDark) {
    final t = ref.read(localeProvider.notifier).t;
    return Container(
      width: double.infinity,
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
          InkWell(
            borderRadius: _isStakeholdersExpanded
                ? const BorderRadius.vertical(top: Radius.circular(24))
                : BorderRadius.circular(24),
            onTap: () {
              setState(() {
                _isStakeholdersExpanded = !_isStakeholdersExpanded;
              });
            },
            child: Padding(
              padding: const EdgeInsets.all(28),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset(
                        'assets/stakeholders_icon.png',
                        width: 22,
                        height: 22,
                        color: isDark ? Colors.grey[400] : Colors.grey[700],
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Add Stakeholders',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.grey[400] : Colors.grey[700],
                        ),
                      ),
                    ],
                  ),
                  Icon(
                    _isStakeholdersExpanded
                        ? Icons.expand_less
                        : Icons.expand_more,
                    color: isDark ? Colors.grey[400] : Colors.grey[500],
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            alignment: Alignment.topCenter,
            child: !_isStakeholdersExpanded
                ? const SizedBox(width: double.infinity)
                : Padding(
                    padding: const EdgeInsets.only(
                        left: 28, right: 28, bottom: 28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Column(
                          children: [
                            _buildSTField(
                              _stakeholderNameController,
                              t('stakeholder_name'),
                              isDark,
                            ),
                            const SizedBox(height: 12),
                            _buildSTField(
                              _stakeholderRoleController,
                              t('role_or_discipline'),
                              isDark,
                            ),
                            const SizedBox(height: 16),
                            Align(
                              alignment: Alignment.centerRight,
                              child: ElevatedButton(
                                onPressed: () => _addStakeholder(review),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: DashboardDesign.primary,
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
                                child: Text(
                                  t('add_stakeholder'),
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                            ),
                          ],
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
                                    color: DashboardDesign.primary,
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
                  ),
          ),
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
          borderSide: const BorderSide(color: DashboardDesign.primary, width: 1.5),
        ),
      ),
    );
  }

  Widget _buildStageCard(
    DesignReview review,
    Stage stage,
    int index,
    bool isDark, {
    required bool isExpanded,
  }) {
    final isMobile = MediaQuery.sizeOf(context).width < 700;
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
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
                    color: DashboardDesign.primary,
                    width: isMobile ? 3 : 4,
                  ),
                ),
              ),
              SizedBox(width: isMobile ? 10 : 20),
              Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  curve: Curves.easeOutCubic,
                  decoration: BoxDecoration(
                    color: DashboardDesign.surface(context),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isExpanded
                          ? DashboardDesign.primary
                          : DashboardDesign.border(context),
                      width: isExpanded ? 1.4 : 1,
                    ),
                    boxShadow: isExpanded
                        ? DashboardDesign.softShadow(context)
                        : const [],
                  ),
                  clipBehavior: Clip.antiAlias,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            setState(() {
                              if (_expandedStageIndex == index) {
                                _expandedStageIndex = null;
                              } else {
                                _expandedStageIndex = index;
                              }
                            });
                          },
                          child: Padding(
                            padding: EdgeInsets.all(isMobile ? 16 : 22),
                            child: _buildStageHeading(
                              stage,
                              index,
                              isDark,
                              isMobile,
                              isExpanded,
                            ),
                          ),
                        ),
                      ),
                      if (isExpanded) ...[
                        Divider(
                          height: 1,
                          color: DashboardDesign.border(context),
                        ),
                        Padding(
                          padding: EdgeInsets.all(isMobile ? 14 : 18),
                          child: _buildSubStepsTable(review, stage, isDark),
                        ),
                      ],
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
    bool isExpanded,
  ) {
    final progressLabel = _stageProgressLabel(stage);

    // Map each stage name to a representative icon
    const stageIcons = <String, IconData>{
      'Requirements': Icons.checklist_rounded,
      'Concept': Icons.lightbulb_outline_rounded,
      'Preliminary Design': Icons.architecture,
      'Detailed Design': Icons.view_in_ar_outlined,
      'Simulation (FEA,CFD...)': Icons.science_outlined,
      'Prototype': Icons.precision_manufacturing_outlined,
      'Testing Validation': Icons.biotech_outlined,
      'Manufacturing Readiness': Icons.factory_outlined,
      'Final Release': Icons.verified_outlined,
      'Continuous Improvement': Icons.trending_up_rounded,
    };
    final iconData = stageIcons[stage.name] ?? Icons.assignment_outlined;
    final iconSize = isMobile ? 40.0 : 48.0;

    final stageIcon = Container(
      width: iconSize,
      height: iconSize,
      decoration: BoxDecoration(
        color: DashboardDesign.primary,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Center(
        child: Icon(iconData, color: Colors.white, size: isMobile ? 22 : 26),
      ),
    );

    final title = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [

        Text(
          stage.name,
          maxLines: isMobile ? 2 : 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: isMobile ? 19 : 22,
            fontWeight: FontWeight.bold,
            color: DashboardDesign.text(context),
            height: 1.15,
          ),
        ),
        const SizedBox(height: 10),
        _StageProgressPill(label: progressLabel),
      ],
    );
    final chevron = Icon(
      isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.chevron_right,
      color: isExpanded
          ? DashboardDesign.primary
          : DashboardDesign.mutedText(context),
      size: 26,
    );

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        stageIcon,
        const SizedBox(width: 14),
        Expanded(child: title),
        const SizedBox(width: 16),
        chevron,
      ],
    );
  }

  Widget _buildSubStepsTable(DesignReview review, Stage stage, bool isDark) {
    final t = ref.read(localeProvider.notifier).t;
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
              2: FixedColumnWidth(148),
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
                  _buildTableHeader(t('substep_header'), isDark),
                  _buildTableHeader(t('status_header'), isDark),
                  _buildTableHeader(t('action_header'), isDark),
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
    final t = ref.read(localeProvider.notifier).t;
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
              labelText: t('status_header'),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            items: [
              DropdownMenuItem(
                value: StageStatus.notStarted,
                child: Text(t('status_open')),
              ),
              DropdownMenuItem(
                value: StageStatus.completed,
                child: Text(t('status_completed')),
              ),
              DropdownMenuItem(
                value: StageStatus.notRequired,
                child: Text(t('status_not_required')),
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
              child: Text(
                t('open_workspace'),
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
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
    final t = ref.read(localeProvider.notifier).t;
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
              fontWeight: FontWeight.w600,
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
                items: [
                  DropdownMenuItem(
                    value: StageStatus.notStarted,
                    child: Text(t('status_open'), overflow: TextOverflow.ellipsis),
                  ),
                  DropdownMenuItem(
                    value: StageStatus.completed,
                    child: Text(t('status_completed'), overflow: TextOverflow.ellipsis),
                  ),
                  DropdownMenuItem(
                    value: StageStatus.notRequired,
                    child: Text(t('status_not_required'), overflow: TextOverflow.ellipsis),
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
              t('open_workspace'),
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



  String _stageProgressLabel(Stage stage) {
    final t = ref.read(localeProvider.notifier).t;
    if (stage.subSteps.isEmpty) return t('no_checklist');
    final completed = stage.subSteps
        .where((subStep) => subStep.status == StageStatus.completed)
        .length;
    final notRequired = stage.subSteps
        .where((subStep) => subStep.status == StageStatus.notRequired)
        .length;
    final applicable = stage.subSteps.length - notRequired;
    if (applicable == 0) return t('all_not_required');
    return t('stage_complete_progress', {
      'completed': '$completed',
      'applicable': '$applicable',
    });
  }

  Future<void> _addStakeholder(DesignReview review) async {
    final t = ref.read(localeProvider.notifier).t;
    if (_stakeholderNameController.text.isEmpty) {
      AppMessenger.error(t('enter_stakeholder_name'));
      return;
    }

    final stakeholder = Stakeholder(
      id: const Uuid().v4(),
      name: _stakeholderNameController.text,
      role: _stakeholderRoleController.text,
    );

    try {
      await ref
          .read(designReviewNotifierProvider.notifier)
          .addStakeholder(review.id, stakeholder);
      AppMessenger.success(t('stakeholder_added'));
      _stakeholderNameController.clear();
      _stakeholderRoleController.clear();
      if (mounted) FocusScope.of(context).unfocus();
    } catch (e) {
      AppMessenger.fromError(e, prefix: 'Could not add stakeholder.');
    }
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
    // 'notRequired' substeps are excluded from the denominator
    final applicableSubSteps = updatedSubSteps
        .where((s) => s.status != StageStatus.notRequired)
        .toList();
    int completedCount = applicableSubSteps
        .where((s) => s.status == StageStatus.completed)
        .length;
    double progress = applicableSubSteps.isEmpty
        ? 1.0 // All substeps are notRequired → treat stage as complete
        : completedCount / applicableSubSteps.length;

    final updatedStage = stage.copyWith(
      subSteps: updatedSubSteps,
      progress: progress,
      status: progress == 1.0
          ? StageStatus.completed
          : (completedCount > 0 ? StageStatus.inProgress : StageStatus.notStarted),
    );

    final updatedStages = review.stages
        .map((s) => s.id == updatedStage.id ? updatedStage : s)
        .toList();

    // Overall project progress based on DRL
    double totalProgress = calculateDrl(updatedStages) / 100.0;

    final updatedReview = review.copyWith(
      stages: updatedStages,
      progress: totalProgress,
      status: totalProgress == 1.0
          ? ProjectStatus.completed
          : ProjectStatus.active,
    );

    ref.read(designReviewNotifierProvider.notifier).updateReview(updatedReview).then((_) {
      // Quiet success for frequent checklist toggles — only announce failures.
    }).catchError((Object e) {
      final t = ref.read(localeProvider.notifier).t;
      AppMessenger.fromError(e, prefix: t('save_checklist_error'));
    });
  }
}

class _StageProgressPill extends StatelessWidget {
  final String label;

  const _StageProgressPill({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: DashboardDesign.subtleSurface(context),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: DashboardDesign.border(context)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: DashboardDesign.text(context),
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
