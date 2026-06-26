import 'package:flutter/material.dart';

import '../theme/dashboard_design.dart';
import 'clean_header.dart';
import 'dashboard_motion.dart';

class HeroSection extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final isMobile =
        MediaQuery.sizeOf(context).width < DashboardDesign.mobileBreakpoint;

    final copy = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Design review workspace',
          style: TextStyle(
            color: DashboardDesign.text(context),
            fontSize: isMobile ? 21 : 24,
            height: 1.08,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.7,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'Track active reviews, revisit completed records, and keep the next decision moving.',
          style: TextStyle(
            color: DashboardDesign.mutedText(context),
            fontSize: isMobile ? 15 : 16,
            height: 1.55,
          ),
        ),
      ],
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
              color: Color(0x2401696F),
              blurRadius: 18,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: const Padding(
          padding: EdgeInsets.symmetric(horizontal: 18, vertical: 15),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.add_rounded, color: Colors.white, size: 19),
              SizedBox(width: 8),
              Text(
                'New Design Review',
                style: TextStyle(
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
        isMobile ? 16 : 36,
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
              crossAxisAlignment: CrossAxisAlignment.end,
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
