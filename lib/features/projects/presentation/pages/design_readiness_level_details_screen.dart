import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/enums.dart';
import '../../../dashboard/presentation/theme/dashboard_design.dart';
import '../../../dashboard/presentation/widgets/drl_gauge.dart';
import '../../../reviews/domain/entities/stage.dart';
import '../../../reviews/domain/utils/drl_weights.dart';
import '../../../reviews/presentation/providers/design_review_provider.dart';

class DesignReadinessLevelDetailsScreen extends ConsumerWidget {
  final String reviewId;

  const DesignReadinessLevelDetailsScreen({
    required this.reviewId,
    super.key,
  });

  double _getCompletedWeightForStage(Stage stage) {
    final weights = drlSubStepWeights[stage.name];
    if (weights == null) return 0.0;
    double completedWeight = 0.0;
    for (int i = 0; i < stage.subSteps.length; i++) {
      if (i >= weights.length) break;
      if (stage.subSteps[i].status == StageStatus.completed) {
        completedWeight += weights[i];
      }
    }
    return completedWeight;
  }

  double _getMaxWeightForStage(Stage stage) {
    final weights = drlSubStepWeights[stage.name];
    if (weights == null) return 0.0;
    double maxWeight = 0.0;
    for (int i = 0; i < stage.subSteps.length; i++) {
      if (i >= weights.length) break;
      maxWeight += weights[i];
    }
    return maxWeight;
  }

  Widget _buildHeader(BuildContext context, String reviewName) {
    final isDark = DashboardDesign.isDark(context);
    final horizontalPadding =
        MediaQuery.sizeOf(context).width < 600 ? 16.0 : 24.0;

    return Padding(
      padding: EdgeInsets.fromLTRB(horizontalPadding, 24, horizontalPadding, 0),
      child: Container(
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
                    shaderCallback: (bounds) => const LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Color(0xFF4D8FFF),
                        Color(0xFFF4F7F8),
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
                    reviewName,
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
                    'Design Readiness Level',
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
              onPressed: () => context.pop(),
              tooltip: 'Back',
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
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reviewsAsync = ref.watch(designReviewsStreamProvider);

    return Scaffold(
      backgroundColor: DashboardDesign.canvas(context),
      body: SafeArea(
        bottom: false,
        child: reviewsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(
            child: Text('Error loading project: $error'),
          ),
          data: (reviews) {
            final review = reviews.where((r) => r.id == reviewId).firstOrNull;
            if (review == null) {
              return const Center(
                child: Text('Project not found'),
              );
            }

            return Column(
              children: [
                _buildHeader(context, review.name),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Gauge Section
                        Center(
                          child: DrlGauge(
                            progress: review.progress,
                            size: 240,
                          ),
                        ),
                        const SizedBox(height: 32),

                        // Readiness by Design Review Steps Section
                        Container(
                          decoration: BoxDecoration(
                            color: DashboardDesign.subtleSurface(context),
                            borderRadius: BorderRadius.circular(DashboardDesign.cardRadius),
                            border: Border.all(color: DashboardDesign.border(context)),
                            boxShadow: DashboardDesign.softShadow(context),
                          ),
                          padding: const EdgeInsets.all(20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ...review.stages.asMap().entries.map((entry) {
                                final index = entry.key;
                                final stage = entry.value;
                                final stepNumber = index + 1;
                                final completedWeight = _getCompletedWeightForStage(stage);
                                final maxWeight = _getMaxWeightForStage(stage);
                                final progressValue = maxWeight > 0 ? completedWeight / maxWeight : 0.0;

                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 20),
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        children: [
                                          Container(
                                            width: 24,
                                            height: 24,
                                            decoration: const BoxDecoration(
                                              color: Color(0xFF0D9488), // Teal color
                                              shape: BoxShape.circle,
                                            ),
                                            alignment: Alignment.center,
                                            child: Text(
                                              '$stepNumber',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Text(
                                              stage.name,
                                              style: TextStyle(
                                                color: DashboardDesign.text(context),
                                                fontSize: 14,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ),
                                          Text(
                                            '${completedWeight.toStringAsFixed(2)}%',
                                            style: const TextStyle(
                                              color: Color(0xFF0D9488), // Teal color
                                              fontSize: 14,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(99),
                                        child: LinearProgressIndicator(
                                          value: progressValue,
                                          minHeight: 6,
                                          backgroundColor: DashboardDesign.offsetSurface(context),
                                          valueColor: const AlwaysStoppedAnimation(Color(0xFF0D9488)),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
