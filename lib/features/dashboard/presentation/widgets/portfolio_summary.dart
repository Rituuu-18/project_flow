import 'package:flutter/material.dart';

import '../theme/dashboard_design.dart';

class PortfolioSummary extends StatelessWidget {
  const PortfolioSummary({
    required this.activeCount,
    required this.completedCount,
    required this.showCompleted,
    required this.onToggleCompleted,
    super.key,
  });

  final int activeCount;
  final int completedCount;
  final bool showCompleted;
  final VoidCallback onToggleCompleted;

  @override
  Widget build(BuildContext context) {
    final compact =
        MediaQuery.sizeOf(context).width < DashboardDesign.mobileBreakpoint;

    return RepaintBoundary(
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: compact ? 18 : 28),
        padding: EdgeInsets.all(compact ? 14 : 18),
        decoration: BoxDecoration(
          color: DashboardDesign.subtleSurface(context),
          borderRadius: BorderRadius.circular(DashboardDesign.cardRadius),
          border: Border.all(color: DashboardDesign.border(context)),
        ),
        child: Row(
          children: [
            Expanded(
              child: _FilterButton(
                label: 'Active',
                count: activeCount,
                isSelected: !showCompleted,
                onTap: showCompleted ? onToggleCompleted : null,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _FilterButton(
                label: 'Completed',
                count: completedCount,
                isSelected: showCompleted,
                onTap: !showCompleted ? onToggleCompleted : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FilterButton extends StatelessWidget {
  const _FilterButton({
    required this.label,
    required this.count,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final int count;
  final bool isSelected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: isSelected
            ? DashboardDesign.primary.withValues(alpha: isDark ? 0.18 : 0.10)
            : DashboardDesign.surface(context),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isSelected
              ? DashboardDesign.primary.withValues(alpha: 0.5)
              : DashboardDesign.border(context),
          width: isSelected ? 1.5 : 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$count',
                        style: TextStyle(
                          color: isSelected
                              ? DashboardDesign.primary
                              : DashboardDesign.text(context),
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.6,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        label,
                        style: TextStyle(
                          color: isSelected
                              ? DashboardDesign.primary
                              : DashboardDesign.mutedText(context),
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: DashboardDesign.primary,
                      shape: BoxShape.circle,
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
