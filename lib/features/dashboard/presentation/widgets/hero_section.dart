import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/localization/locale_provider.dart';
import '../theme/dashboard_design.dart';
import 'clean_header.dart';
import 'dashboard_motion.dart';

class HeroSection extends ConsumerWidget {
  const HeroSection({
    required this.onCreateReview,
    required this.searchController,
    required this.onSearchChanged,
    super.key,
  });

  final VoidCallback onCreateReview;
  final TextEditingController searchController;
  final ValueChanged<String> onSearchChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.watch(localeProvider);
    final t = ref.read(localeProvider.notifier).t;

    final isMobile =
        MediaQuery.sizeOf(context).width < DashboardDesign.mobileBreakpoint;

    final copy = Text(
      t('dashboard_hero'),
      style: TextStyle(
        color: DashboardDesign.mutedText(context),
        fontSize: isMobile ? 15 : 16,
        height: 1.55,
      ),
    );

    final createButton = PressScale(
      semanticLabel: 'Create a new design review',
      onTap: onCreateReview,
      pressedScale: 0.975,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: DashboardDesign.primary,
          borderRadius: BorderRadius.circular(DashboardDesign.controlRadius),
          boxShadow: const [
            BoxShadow(
              color: Color(0x24005CFF),
              blurRadius: 18,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.add_rounded, color: Colors.white, size: 19),
              const SizedBox(width: 8),
              Text(
                t('new_design_review'),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );

    return Padding(
      padding: EdgeInsets.fromLTRB(
        isMobile ? 18 : 28,
        isMobile ? 12 : 28,
        isMobile ? 18 : 28,
        28,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isMobile) ...[
            copy,
            const SizedBox(height: 24),
            SizedBox(width: double.infinity, child: createButton),
            const SizedBox(height: 14),
            DashboardSearchField(
              controller: searchController,
              onChanged: onSearchChanged,
            ),
          ] else
            Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Expanded(child: copy),
                const SizedBox(width: 32),
                createButton,
              ],
            ),
        ],
      ),
    );
  }
}
