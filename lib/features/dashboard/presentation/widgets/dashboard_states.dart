import 'package:flutter/material.dart';

import '../theme/dashboard_design.dart';
import 'dashboard_motion.dart';

class DashboardEmptyState extends StatelessWidget {
  const DashboardEmptyState({
    required this.isSearchResult,
    required this.onCreateReview,
    super.key,
  });

  final bool isSearchResult;
  final VoidCallback onCreateReview;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  color: DashboardDesign.subtleSurface(context),
                  borderRadius: BorderRadius.circular(17),
                  border: Border.all(color: DashboardDesign.border(context)),
                ),
                child: Icon(
                  isSearchResult
                      ? Icons.search_off_rounded
                      : Icons.rate_review_outlined,
                  color: DashboardDesign.primary,
                  size: 24,
                ),
              ),
              const SizedBox(height: 18),
              Text(
                isSearchResult
                    ? 'No matching reviews'
                    : 'No Design Reviews yet.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: DashboardDesign.text(context),
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  letterSpacing: -0.4,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                isSearchResult
                    ? 'Try a project name, owner, discipline, or status.'
                    : 'Click the button above to start one.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: DashboardDesign.mutedText(context),
                  fontSize: 14,
                  height: 1.5,
                ),
              ),
              if (!isSearchResult) ...[
                const SizedBox(height: 22),
                PressScale(
                  onTap: onCreateReview,
                  semanticLabel: 'Create a design review',
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: DashboardDesign.primary,
                      borderRadius: BorderRadius.circular(
                        DashboardDesign.controlRadius,
                      ),
                    ),
                    child: const Text(
                      'Create review',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class DashboardErrorState extends StatelessWidget {
  const DashboardErrorState({
    required this.onRetry,
    this.message,
    super.key,
  });

  final VoidCallback onRetry;
  final String? message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 48, 24, 90),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_off_outlined,
              color: DashboardDesign.mutedText(context),
              size: 28,
            ),
            const SizedBox(height: 14),
            Text(
              'Reviews could not be loaded',
              style: TextStyle(
                color: DashboardDesign.text(context),
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (message != null && message!.trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                message!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: DashboardDesign.mutedText(context),
                  fontSize: 14,
                  height: 1.4,
                ),
              ),
            ],
            const SizedBox(height: 8),
            TextButton(onPressed: onRetry, child: const Text('Try again')),
          ],
        ),
      ),
    );
  }
}

/// One controller drives every placeholder, avoiding a ticker per skeleton card.
class DashboardLoadingState extends StatefulWidget {
  const DashboardLoadingState({super.key});

  @override
  State<DashboardLoadingState> createState() => _DashboardLoadingStateState();
}

class _DashboardLoadingStateState extends State<DashboardLoadingState>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: DashboardMotion.skeletonDuration,
    )..repeat(reverse: true);
    _opacity = Tween<double>(begin: 0.46, end: 0.92).animate(
      CurvedAnimation(
        parent: _controller,
        curve: DashboardMotion.breathingCurve,
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final count = width >= DashboardDesign.desktopBreakpoint
        ? 3
        : (width >= DashboardDesign.mobileBreakpoint ? 2 : 1);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        width < 700 ? 18 : 28,
        20,
        width < 700 ? 18 : 28,
        80,
      ),
      child: FadeTransition(
        opacity: _opacity,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final gap = 18.0;
            final itemWidth =
                (constraints.maxWidth - gap * (count - 1)) / count;
            return Wrap(
              spacing: gap,
              runSpacing: gap,
              children: List.generate(
                count,
                (_) => SizedBox(
                  width: itemWidth,
                  height: 356,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: DashboardDesign.subtleSurface(context),
                      borderRadius: BorderRadius.circular(
                        DashboardDesign.cardRadius,
                      ),
                      border: Border.all(
                        color: DashboardDesign.border(context),
                      ),
                    ),
                    child: Column(
                      children: [
                        Container(
                          height: 146,
                          decoration: BoxDecoration(
                            color: DashboardDesign.offsetSurface(context),
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(DashboardDesign.cardRadius),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(18),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _SkeletonLine(width: itemWidth * 0.55),
                              const SizedBox(height: 14),
                              _SkeletonLine(
                                width: itemWidth * 0.38,
                                height: 10,
                              ),
                              const SizedBox(height: 62),
                              const _SkeletonLine(
                                width: double.infinity,
                                height: 6,
                              ),
                              const SizedBox(height: 20),
                              const _SkeletonLine(width: 104, height: 28),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _SkeletonLine extends StatelessWidget {
  const _SkeletonLine({required this.width, this.height = 14});

  final double width;
  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: DashboardDesign.offsetSurface(context),
        borderRadius: BorderRadius.circular(99),
      ),
    );
  }
}
