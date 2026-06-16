import 'package:flutter/material.dart';

import '../theme/dashboard_design.dart';


class PortfolioSummary extends StatelessWidget {
  const PortfolioSummary({
    required this.averageProgress,
    required this.activeCount,
    required this.completedCount,
    super.key,
  });

  final double averageProgress;
  final int activeCount;
  final int completedCount;

  @override
  Widget build(BuildContext context) {
    final compact =
        MediaQuery.sizeOf(context).width < DashboardDesign.mobileBreakpoint;

    return RepaintBoundary(
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: compact ? 18 : 28),
        padding: EdgeInsets.all(compact ? 18 : 22),
        decoration: BoxDecoration(
          color: DashboardDesign.subtleSurface(context),
          borderRadius: BorderRadius.circular(DashboardDesign.cardRadius),
          border: Border.all(color: DashboardDesign.border(context)),
        ),
        child: compact
            ? Column(
                children: [
                  _ProgressSummary(progress: averageProgress),
                  const SizedBox(height: 18),
                  const Divider(height: 1),
                  const SizedBox(height: 18),
                  _MetricRow(
                    activeCount: activeCount,
                    completedCount: completedCount,
                  ),
                ],
              )
            : Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: _ProgressSummary(progress: averageProgress),
                  ),
                  const SizedBox(width: 28),
                  SizedBox(
                    height: 54,
                    child: VerticalDivider(
                      color: DashboardDesign.border(context),
                      width: 1,
                    ),
                  ),
                  const SizedBox(width: 28),
                  Expanded(
                    flex: 2,
                    child: _MetricRow(
                      activeCount: activeCount,
                      completedCount: completedCount,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _ProgressSummary extends StatelessWidget {
  const _ProgressSummary({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    final percentage = (progress.clamp(0, 1) * 100).round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Active portfolio completion',
                style: TextStyle(
                  color: DashboardDesign.mutedText(context),
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            Text(
              '$percentage%',
              style: TextStyle(
                color: DashboardDesign.text(context),
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        ClipRRect(
          borderRadius: BorderRadius.circular(99),
          child: SizedBox(
            height: 7,
            child: TweenAnimationBuilder<double>(
              tween: Tween<double>(
                begin: 0,
                end: progress.clamp(0, 1).toDouble(),
              ),
              duration: const Duration(milliseconds: 720),
              curve: DashboardMotion.entranceCurve,
              builder: (context, value, _) => LinearProgressIndicator(
                value: value,
                backgroundColor: DashboardDesign.offsetSurface(context),
                valueColor: const AlwaysStoppedAnimation(
                  DashboardDesign.primary,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _MetricRow extends StatelessWidget {
  const _MetricRow({
    required this.activeCount,
    required this.completedCount,
  });

  final int activeCount;
  final int completedCount;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _Metric(value: activeCount, label: 'Active'),
        ),
        Expanded(
          child: _Metric(value: completedCount, label: 'Complete'),
        ),
      ],
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric({required this.value, required this.label});

  final int value;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '$value',
          style: TextStyle(
            color: DashboardDesign.text(context),
            fontSize: 21,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.6,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: TextStyle(
            color: DashboardDesign.mutedText(context),
            fontSize: 11,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
