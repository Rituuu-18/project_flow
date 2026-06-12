import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/utils/enums.dart';
import '../../../reviews/domain/entities/design_review.dart';
import '../../../reviews/presentation/providers/design_review_provider.dart';
import '../../../settings/presentation/providers/theme_provider.dart';
import '../theme/dashboard_design.dart';
import '../widgets/clean_header.dart';
import '../widgets/dashboard_motion.dart';
import '../widgets/dashboard_states.dart';
import '../widgets/hero_section.dart';
import '../widgets/new_review_dialog.dart';
import '../widgets/portfolio_summary.dart';
import '../widgets/premium_review_card.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen>
    with SingleTickerProviderStateMixin {
  final _searchController = TextEditingController();
  final _searchQuery = ValueNotifier<String>('');

  late final AnimationController _entranceController;
  bool _entranceScheduled = false;

  @override
  void initState() {
    super.initState();
    _entranceController = AnimationController(
      vsync: this,
      duration: DashboardMotion.entranceDuration,
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchQuery.dispose();
    _entranceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reviewsAsync = ref.watch(designReviewsStreamProvider);
    final width = MediaQuery.sizeOf(context).width;

    return Scaffold(
      backgroundColor: DashboardDesign.canvas(context),
      body: SafeArea(
        bottom: false,
        child: CustomScrollView(
          slivers: [
            SliverPersistentHeader(
              pinned: true,
              delegate: _CleanHeaderDelegate(
                searchController: _searchController,
                onSearchChanged: _onSearchChanged,
                onToggleTheme: _toggleTheme,
                brightness: Theme.of(context).brightness,
              ),
            ),
            SliverToBoxAdapter(
              child: _ContentWidth(
                child: StaggeredReveal(
                  animation: _entranceController,
                  interval: const Interval(
                    0,
                    0.46,
                    curve: DashboardMotion.entranceCurve,
                  ),
                  child: HeroSection(
                    onCreateReview: _showCreateReviewDialog,
                    searchController: _searchController,
                    onSearchChanged: _onSearchChanged,
                  ),
                ),
              ),
            ),
            ..._buildReviewSlivers(reviewsAsync, width),
            const SliverToBoxAdapter(child: SizedBox(height: 56)),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildReviewSlivers(
    AsyncValue<List<DesignReview>> reviewsAsync,
    double width,
  ) {
    return reviewsAsync.when(
      loading: () => const [
        SliverToBoxAdapter(
          child: _ContentWidth(child: DashboardLoadingState()),
        ),
      ],
      error: (error, stackTrace) => [
        SliverFillRemaining(
          hasScrollBody: false,
          child: DashboardErrorState(
            onRetry: () => ref.invalidate(designReviewsStreamProvider),
          ),
        ),
      ],
      data: (reviews) {
        _scheduleEntrance();
        return [
          ValueListenableBuilder<String>(
            valueListenable: _searchQuery,
            builder: (context, query, _) {
              final filtered = _filterReviews(reviews, query);
              if (filtered.isEmpty) {
                return SliverFillRemaining(
                  hasScrollBody: false,
                  child: DashboardEmptyState(
                    isSearchResult: query.isNotEmpty,
                    onCreateReview: _showCreateReviewDialog,
                  ),
                );
              }

              final active = filtered
                  .where((review) => review.status != ProjectStatus.completed)
                  .toList();
              final completed = filtered
                  .where((review) => review.status == ProjectStatus.completed)
                  .toList();
              final averageProgress = active.isEmpty
                  ? 0.0
                  : active.fold<double>(
                          0,
                          (sum, review) => sum + review.progress,
                        ) /
                        active.length;
              final pendingCount = active
                  .where(
                    (review) => review.status == ProjectStatus.reviewPending,
                  )
                  .length;

              return SliverMainAxisGroup(
                slivers: [
                  SliverToBoxAdapter(
                    child: _ContentWidth(
                      child: StaggeredReveal(
                        animation: _entranceController,
                        interval: const Interval(
                          0.16,
                          0.58,
                          curve: DashboardMotion.entranceCurve,
                        ),
                        child: PortfolioSummary(
                          averageProgress: averageProgress,
                          activeCount: active.length,
                          pendingCount: pendingCount,
                          completedCount: completed.length,
                        ),
                      ),
                    ),
                  ),
                  if (active.isNotEmpty) ...[
                    _sectionHeader(
                      width: width,
                      title: 'Active Design Reviews',
                      description: 'In progress and awaiting review',
                      count: active.length,
                    ),
                    _reviewGrid(active, width, startIndex: 0),
                  ],
                  if (completed.isNotEmpty) ...[
                    _sectionHeader(
                      width: width,
                      title: 'Completed Design Reviews',
                      description: 'Approved records and decision history',
                      count: completed.length,
                    ),
                    _reviewGrid(completed, width, startIndex: active.length),
                  ],
                ],
              );
            },
          ),
        ];
      },
    );
  }

  Widget _sectionHeader({
    required double width,
    required String title,
    required String description,
    required int count,
  }) {
    return SliverPadding(
      padding: EdgeInsets.fromLTRB(
        _horizontalGutter(width),
        36,
        _horizontalGutter(width),
        16,
      ),
      sliver: SliverToBoxAdapter(
        child: StaggeredReveal(
          animation: _entranceController,
          interval: const Interval(
            0.28,
            0.68,
            curve: DashboardMotion.entranceCurve,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        color: DashboardDesign.text(context),
                        fontSize: width < DashboardDesign.mobileBreakpoint
                            ? 21
                            : 24,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.7,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      description,
                      style: TextStyle(
                        color: DashboardDesign.mutedText(context),
                        fontSize: 12,
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
                  '$count',
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
      ),
    );
  }

  Widget _reviewGrid(
    List<DesignReview> reviews,
    double width, {
    required int startIndex,
  }) {
    final columnCount = width >= DashboardDesign.desktopBreakpoint
        ? 3
        : (width >= DashboardDesign.mobileBreakpoint ? 2 : 1);

    return SliverPadding(
      padding: EdgeInsets.symmetric(horizontal: _horizontalGutter(width)),
      sliver: SliverGrid(
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: columnCount,
          crossAxisSpacing: 18,
          mainAxisSpacing: 18,
          mainAxisExtent: 356,
        ),
        delegate: SliverChildBuilderDelegate(
          (context, index) {
            final review = reviews[index];
            final staggerIndex = (startIndex + index).clamp(0, 8).toDouble();
            final start = 0.38 + staggerIndex * 0.045;
            final end = (start + 0.32).clamp(0.0, 1.0).toDouble();

            return StaggeredReveal(
              animation: _entranceController,
              interval: Interval(
                start,
                end,
                curve: DashboardMotion.entranceCurve,
              ),
              child: PremiumReviewCard(
                review: review,
                onOpen: () => context.push('/project/${review.id}'),
                onAction: (action) => _handleCardAction(action, review),
                onStatusChanged: (status) => _updateStatus(review, status),
              ),
            );
          },
          childCount: reviews.length,
          addAutomaticKeepAlives: false,
          addRepaintBoundaries: true,
          addSemanticIndexes: true,
        ),
      ),
    );
  }

  List<DesignReview> _filterReviews(
    List<DesignReview> reviews,
    String rawQuery,
  ) {
    final query = rawQuery.trim().toLowerCase();
    if (query.isEmpty) return reviews;

    return reviews.where((review) {
      final status = switch (review.status) {
        ProjectStatus.active => 'in progress active',
        ProjectStatus.reviewPending => 'review pending',
        ProjectStatus.completed => 'completed',
      };
      return [
        review.name,
        review.owner,
        review.discipline,
        status,
      ].any((value) => value.toLowerCase().contains(query));
    }).toList();
  }

  double _horizontalGutter(double width) {
    final base = width < DashboardDesign.mobileBreakpoint ? 18.0 : 28.0;
    final centered = (width - DashboardDesign.maxContentWidth) / 2;
    return centered > 0 ? centered + base : base;
  }

  void _onSearchChanged(String value) {
    _searchQuery.value = value;
  }

  void _scheduleEntrance() {
    if (_entranceScheduled ||
        _entranceController.status != AnimationStatus.dismissed) {
      return;
    }
    _entranceScheduled = true;
    if (MediaQuery.maybeOf(context)?.disableAnimations ?? false) {
      _entranceController.value = 1;
      return;
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _entranceController.forward();
    });
  }

  void _toggleTheme() {
    ref.read(themeProvider.notifier).toggleTheme();
  }

  Future<void> _showCreateReviewDialog() async {
    final draft = await showDialog<NewReviewDraft>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.42),
      builder: (context) => const NewReviewDialog(),
    );
    if (draft == null) return;

    final now = DateTime.now();
    await ref
        .read(designReviewNotifierProvider.notifier)
        .createReview(
          DesignReview(
            id: const Uuid().v4(),
            name: draft.name,
            owner: draft.owner,
            discipline: draft.discipline,
            createdAt: now,
            lastUpdated: now,
          ),
        );
  }

  Future<void> _handleCardAction(
    ReviewCardAction action,
    DesignReview review,
  ) async {
    switch (action) {
      case ReviewCardAction.uploadImage:
        await _uploadImage(review);
        return;
      case ReviewCardAction.prepareSlide:
        _prepareSlide(review);
        return;
      case ReviewCardAction.copy:
        await _copyReview(review);
        return;
      case ReviewCardAction.delete:
        await _confirmDelete(review);
        return;
    }
  }

  Future<void> _uploadImage(DesignReview review) async {
    final file = await ImagePicker().pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
      imageQuality: 82,
    );
    if (file == null) return;

    final bytes = await file.readAsBytes();
    final base64 = await compute(base64Encode, bytes);
    final encoded = 'data:image/*;base64,$base64';
    await ref
        .read(designReviewNotifierProvider.notifier)
        .updateReview(
          review.copyWith(imageUrl: encoded, lastUpdated: DateTime.now()),
        );
    _showMessage('Preview image updated');
  }

  void _prepareSlide(DesignReview review) {
    _showMessage('${review.name} is ready for the presentation export flow.');
  }

  Future<void> _copyReview(DesignReview review) async {
    final now = DateTime.now();
    await ref
        .read(designReviewNotifierProvider.notifier)
        .createReview(
          review.copyWith(
            id: const Uuid().v4(),
            name: 'Copy of ${review.name}',
            status: ProjectStatus.active,
            createdAt: now,
            lastUpdated: now,
          ),
        );
    _showMessage('Review copied');
  }

  Future<void> _confirmDelete(DesignReview review) async {
    final shouldDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete design review?'),
        content: Text(
          '"${review.name}" and its saved review data will be permanently removed.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: DashboardDesign.destructive,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (shouldDelete != true) return;

    await ref
        .read(designReviewNotifierProvider.notifier)
        .deleteReview(review.id);
    _showMessage('Review deleted');
  }

  Future<void> _updateStatus(DesignReview review, ProjectStatus status) async {
    if (review.status == status) return;
    await ref
        .read(designReviewNotifierProvider.notifier)
        .updateReview(
          review.copyWith(status: status, lastUpdated: DateTime.now()),
        );
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }
}

class _ContentWidth extends StatelessWidget {
  const _ContentWidth({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: const BoxConstraints(
          maxWidth: DashboardDesign.maxContentWidth,
        ),
        child: child,
      ),
    );
  }
}

class _CleanHeaderDelegate extends SliverPersistentHeaderDelegate {
  const _CleanHeaderDelegate({
    required this.searchController,
    required this.onSearchChanged,
    required this.onToggleTheme,
    required this.brightness,
  });

  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onToggleTheme;
  final Brightness brightness;

  @override
  double get minExtent => 72;

  @override
  double get maxExtent => 72;

  @override
  Widget build(
    BuildContext context,
    double shrinkOffset,
    bool overlapsContent,
  ) {
    return RepaintBoundary(
      child: CleanHeader(
        searchController: searchController,
        onSearchChanged: onSearchChanged,
        onToggleTheme: onToggleTheme,
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _CleanHeaderDelegate oldDelegate) {
    return brightness != oldDelegate.brightness;
  }
}
