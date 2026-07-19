import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/database/supabase_storage.dart';
import '../../../../core/utils/app_messenger.dart';
import '../../../../core/utils/enums.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../reviews/domain/entities/design_review.dart';
import '../../../reviews/domain/utils/clone_for_copy.dart';
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
  bool _showCompleted = false;

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
          cacheExtent: 900,
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
            message: AppMessenger.describeError(error),
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
              final displayList = _showCompleted ? completed : active;
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
                          activeCount: active.length,
                          completedCount: completed.length,
                          showCompleted: _showCompleted,
                          onToggleCompleted: () {
                            setState(() {
                              _showCompleted = !_showCompleted;
                            });
                          },
                        ),
                      ),
                    ),
                  ),
                  if (displayList.isNotEmpty) ...[
                    _sectionHeader(
                      width: width,
                      title: _showCompleted
                          ? 'Completed Design Reviews'
                          : 'Active Design Reviews',
                      description: _showCompleted
                          ? 'Approved records and decision history'
                          : 'In progress and awaiting review',
                      count: displayList.length,
                    ),
                    _reviewGrid(displayList, width, startIndex: 0),
                  ] else
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: DashboardEmptyState(
                        isSearchResult: false,
                        onCreateReview: _showCreateReviewDialog,
                      ),
                    ),
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
    if (ref.read(currentUserProvider) == null) {
      AppMessenger.authRequired(onSignIn: () {
        if (mounted) context.go('/login');
      });
      return;
    }

    final draft = await showDialog<NewReviewDraft>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.42),
      builder: (context) => const NewReviewDialog(),
    );
    if (draft == null) return;

    final now = DateTime.now();
    final newId = const Uuid().v4();
    try {
      await ref.read(designReviewNotifierProvider.notifier).createReview(
            DesignReview(
              id: newId,
              name: draft.name,
              owner: draft.owner,
              discipline: draft.discipline,
              createdAt: now,
              lastUpdated: now,
            ),
          );
      AppMessenger.success('Review "${draft.name}" created.');
      if (mounted) {
        try {
          context.push('/project/$newId');
        } catch (_) {
          // Ignore navigation errors in tests if GoRouter is missing
        }
      }
    } catch (e) {
      if (AppMessenger.isAuthError(e)) {
        AppMessenger.authRequired(onSignIn: () {
          if (mounted) context.go('/login');
        });
      } else {
        AppMessenger.fromError(e, prefix: 'Could not create review.');
      }
    }
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
      case ReviewCardAction.createPdf:
        await _createPdf(review);
        return;
      case ReviewCardAction.delete:
        await _confirmDelete(review);
        return;
    }
  }

  Future<void> _uploadImage(DesignReview review) async {
    if (ref.read(currentUserProvider) == null) {
      AppMessenger.authRequired(onSignIn: () {
        if (mounted) context.go('/login');
      });
      return;
    }

    try {
      final file = await ImagePicker().pickImage(
        source: ImageSource.gallery,
        maxWidth: 1600,
        imageQuality: 85,
      );
      if (file == null) {
        AppMessenger.info('Image selection cancelled.');
        return;
      }

      final bytes = await file.readAsBytes();
      if (bytes.isEmpty) {
        AppMessenger.error('Could not read the selected image.');
        return;
      }
      if (bytes.length > 5 * 1024 * 1024) {
        AppMessenger.error(
          'Image is too large. Choose a photo under 5 MB.',
        );
        return;
      }

      AppMessenger.info('Uploading image…');
      final storage = SupabaseStorage(Supabase.instance.client);
      final publicUrl = await storage.uploadReviewImage(
        reviewId: review.id,
        bytes: bytes,
        mimeType: file.mimeType,
        fileName: file.name,
      );

      await ref
          .read(designReviewNotifierProvider.notifier)
          .updateImageUrl(review.id, publicUrl);
      await storage.deleteReviewImageIfOwned(review.imageUrl);
      AppMessenger.success('Preview image uploaded.');
    } catch (e) {
      if (AppMessenger.isAuthError(e)) {
        AppMessenger.authRequired(onSignIn: () {
          if (mounted) context.go('/login');
        });
        return;
      }
      AppMessenger.fromError(e, prefix: 'Could not upload image.');
    }
  }

  void _prepareSlide(DesignReview review) {
    AppMessenger.info(
      '${review.name} is ready for the presentation export flow.',
    );
  }

  Future<void> _copyReview(DesignReview review) async {
    try {
      await ref
          .read(designReviewNotifierProvider.notifier)
          .createReview(cloneForCopy(review));
      AppMessenger.success('Review copied.');
    } catch (e) {
      AppMessenger.fromError(e, prefix: 'Could not copy review.');
    }
  }

  Future<void> _createPdf(DesignReview review) async {
    AppMessenger.info('PDF export for "${review.name}" is not available yet.');
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

    try {
      await ref
          .read(designReviewNotifierProvider.notifier)
          .deleteReview(review.id);
      AppMessenger.success('Review deleted.');
    } catch (e) {
      AppMessenger.fromError(e, prefix: 'Could not delete review.');
    }
  }

  Future<void> _updateStatus(DesignReview review, ProjectStatus status) async {
    if (review.status == status) return;
    try {
      await ref.read(designReviewNotifierProvider.notifier).updateReview(
            review.copyWith(status: status, lastUpdated: DateTime.now()),
          );
      AppMessenger.success('Status updated.');
    } catch (e) {
      AppMessenger.fromError(e, prefix: 'Could not update status.');
    }
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
