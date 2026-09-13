import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/utils/enums.dart';
import '../../../reviews/domain/entities/design_review.dart';
import '../theme/dashboard_design.dart';
import 'dashboard_motion.dart';
import 'drl_gauge.dart';

enum ReviewCardAction { uploadImage, prepareSlide, copy, createPdf, delete }

class PremiumReviewCard extends StatefulWidget {
  const PremiumReviewCard({
    required this.review,
    required this.onOpen,
    required this.onAction,
    required this.onStatusChanged,
    super.key,
  });

  final DesignReview review;
  final VoidCallback onOpen;
  final ValueChanged<ReviewCardAction> onAction;
  final ValueChanged<ProjectStatus> onStatusChanged;

  @override
  State<PremiumReviewCard> createState() => _PremiumReviewCardState();
}

class _PremiumReviewCardState extends State<PremiumReviewCard> {

  @override
  Widget build(BuildContext context) {
    final review = widget.review;
    return PressScale(
      semanticLabel: 'Open ${review.name}',
      onTap: widget.onOpen,
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: DashboardDesign.subtleSurface(context),
          borderRadius: BorderRadius.circular(DashboardDesign.cardRadius),
          border: Border.all(color: DashboardDesign.border(context)),
          boxShadow: DashboardDesign.softShadow(context),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(6, 6, 6, 0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(
                  DashboardDesign.cardRadius > 6
                      ? DashboardDesign.cardRadius - 6
                      : 6,
                ),
                child: RepaintBoundary(child: _ReviewImage(review: review)),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      physics: const NeverScrollableScrollPhysics(),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Expanded(
                                      child: Text(
                                        review.name,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: DashboardDesign.text(context),
                                          fontSize: 18,
                                          height: 1.2,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: -0.45,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    _ActionMenu(review: review, onSelected: widget.onAction),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  _reviewMeta(review),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    color: DashboardDesign.mutedText(context),
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Flexible(
                                            child: Text(
                                              'Design Readiness Level',
                                              overflow: TextOverflow.ellipsis,
                                              style: TextStyle(
                                                color: DashboardDesign.text(context),
                                                fontSize: 13,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 4),
                                          Icon(
                                            Icons.info_outline_rounded,
                                            size: 16,
                                            color: DashboardDesign.mutedText(context),
                                          ),
                                        ],
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.chevron_right_rounded, size: 20),
                                      style: IconButton.styleFrom(
                                        backgroundColor: DashboardDesign.surface(context),
                                        side: BorderSide(color: DashboardDesign.border(context)),
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                        minimumSize: const Size(36, 36),
                                        fixedSize: const Size(36, 36),
                                        padding: EdgeInsets.zero,
                                      ),
                                      onPressed: () {
                                        context.push('/project/${review.id}/drl');
                                      },
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Center(
                                  child: DrlGauge(progress: review.progress, size: 120),
                                ),
                                const SizedBox(height: 8),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Flexible(
                                      child: _StatusMenu(
                                        status: review.status,
                                        onChanged: widget.onStatusChanged,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          DateFormat('MMM d').format(review.lastUpdated),
                                          style: TextStyle(
                                            color: DashboardDesign.mutedText(context),
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        Icon(
                                          Icons.arrow_forward_rounded,
                                          color: DashboardDesign.mutedText(context),
                                          size: 14,
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _reviewMeta(DesignReview review) {
    final values = [
      if (review.owner.trim().isNotEmpty) 'Owner: ${review.owner.trim()}',
      if (review.discipline.trim().isNotEmpty) review.discipline.trim(),
    ];
    return values.isEmpty ? 'No owner or discipline added' : values.join(' / ');
  }
}


class _ReviewImage extends StatefulWidget {
  const _ReviewImage({required this.review});

  final DesignReview review;

  @override
  State<_ReviewImage> createState() => _ReviewImageState();
}

class _ReviewImageState extends State<_ReviewImage> {
  ImageProvider<Object>? _provider;

  @override
  void initState() {
    super.initState();
    _provider = _imageProvider(widget.review.imageUrl);
  }

  @override
  void didUpdateWidget(covariant _ReviewImage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.review.imageUrl != widget.review.imageUrl) {
      _provider = _imageProvider(widget.review.imageUrl);
    }
  }

  @override
  Widget build(BuildContext context) {
    final devicePixelRatio = MediaQuery.devicePixelRatioOf(context);
    final imageProvider = _provider == null
        ? null
        : ResizeImage.resizeIfNeeded(
            (600 * devicePixelRatio).round(),
            null,
            _provider!,
          );
    final disableAnimations =
        MediaQuery.maybeOf(context)?.disableAnimations ?? false;

    return SizedBox(
      height: 138,
      width: double.infinity,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: DashboardDesign.offsetSurface(context),
        ),
        child: imageProvider == null
            ? const _ImageFallback(hasCustomImage: false)
            : Image(
                image: imageProvider,
                fit: BoxFit.cover,
                filterQuality: FilterQuality.high,
                gaplessPlayback: true,
                frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
                  if (wasSynchronouslyLoaded) return child;
                  return AnimatedOpacity(
                    opacity: frame == null ? 0 : 1,
                    duration: disableAnimations
                        ? Duration.zero
                        : const Duration(milliseconds: 280),
                    curve: DashboardMotion.interactionCurve,
                    child: child,
                  );
                },
                errorBuilder: (context, error, stackTrace) =>
                    const _ImageFallback(hasCustomImage: true),
              ),
      ),
    );
  }

  ImageProvider<Object>? _imageProvider(String? source) {
    if (source == null || source.trim().isEmpty) {
      return null;
    }

    if (source.startsWith('data:')) {
      try {
        final encoded = source.substring(source.indexOf(',') + 1);
        final Uint8List bytes = base64Decode(encoded);
        return MemoryImage(bytes);
      } on FormatException {
        return null;
      }
    }

    if (source.startsWith('http://') ||
        source.startsWith('https://') ||
        source.startsWith('blob:')) {
      return NetworkImage(source);
    }

    return AssetImage(source);
  }
}

class _ImageFallback extends StatelessWidget {
  const _ImageFallback({required this.hasCustomImage});

  final bool hasCustomImage;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primary = DashboardDesign.primary;
    
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            primary.withValues(alpha: isDark ? 0.15 : 0.08),
            primary.withValues(alpha: isDark ? 0.05 : 0.02),
          ],
        ),
      ),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: primary.withValues(alpha: isDark ? 0.2 : 0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                hasCustomImage
                    ? Icons.broken_image_rounded
                    : Icons.add_photo_alternate_rounded,
                size: 28,
                color: primary,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              hasCustomImage ? 'Preview unavailable' : 'Add a preview image',
              style: TextStyle(
                color: primary.withValues(alpha: isDark ? 0.9 : 0.7),
                fontSize: 13,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}


class _StatusMenu extends StatelessWidget {
  const _StatusMenu({required this.status, required this.onChanged});

  final ProjectStatus status;
  final ValueChanged<ProjectStatus> onChanged;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (status) {
      ProjectStatus.active => ('In Progress', DashboardDesign.primary),
      ProjectStatus.reviewPending => (
        'Review Pending',
        DashboardDesign.reviewPending,
      ),
      ProjectStatus.completed => ('Completed', DashboardDesign.completed),
    };

    return PopupMenuButton<ProjectStatus>(
      tooltip: 'Change review status',
      onSelected: onChanged,
      itemBuilder: (context) => const [
        PopupMenuItem(value: ProjectStatus.active, child: Text('In Progress')),
        PopupMenuItem(
          value: ProjectStatus.reviewPending,
          child: Text('Review Pending'),
        ),
        PopupMenuItem(value: ProjectStatus.completed, child: Text('Completed')),
      ],
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(99),
          border: Border.all(color: color.withValues(alpha: 0.22)),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Icon(Icons.keyboard_arrow_down_rounded, size: 14, color: color),
            ],
          ),
        ),
      ),
    );
  }
}

class _ActionMenu extends StatelessWidget {
  const _ActionMenu({required this.review, required this.onSelected});

  final DesignReview review;
  final ValueChanged<ReviewCardAction> onSelected;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<ReviewCardAction>(
      tooltip: 'More actions for ${review.name}',
      onSelected: onSelected,
      itemBuilder: (context) => const [
        PopupMenuItem(
          value: ReviewCardAction.uploadImage,
          child: _MenuLabel(icon: Icons.image_outlined, label: 'Upload image'),
        ),
        PopupMenuItem(
          value: ReviewCardAction.prepareSlide,
          child: _MenuLabel(
            icon: Icons.slideshow_outlined,
            label: 'Prepare slide',
          ),
        ),
        PopupMenuItem(
          value: ReviewCardAction.copy,
          child: _MenuLabel(icon: Icons.copy_outlined, label: 'Make a copy'),
        ),
        PopupMenuItem(
          value: ReviewCardAction.createPdf,
          child: _MenuLabel(
            icon: Icons.picture_as_pdf_outlined,
            label: 'Create PDF',
          ),
        ),
        PopupMenuDivider(),
        PopupMenuItem(
          value: ReviewCardAction.delete,
          child: _MenuLabel(
            icon: Icons.delete_outline_rounded,
            label: 'Delete',
            destructive: true,
          ),
        ),
      ],
      icon: Icon(
        Icons.more_horiz_rounded,
        size: 20,
        color: DashboardDesign.mutedText(context),
      ),
      style: IconButton.styleFrom(
        backgroundColor: DashboardDesign.surface(context),
        side: BorderSide(color: DashboardDesign.border(context)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
        fixedSize: const Size(38, 38),
      ),
    );
  }
}

class _MenuLabel extends StatelessWidget {
  const _MenuLabel({
    required this.icon,
    required this.label,
    this.destructive = false,
  });

  final IconData icon;
  final String label;
  final bool destructive;

  @override
  Widget build(BuildContext context) {
    final color = destructive
        ? DashboardDesign.destructive
        : DashboardDesign.text(context);
    return Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 10),
        Text(
          label,
          style: TextStyle(color: color, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}
