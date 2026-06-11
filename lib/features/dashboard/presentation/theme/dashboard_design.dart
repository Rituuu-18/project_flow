import 'package:flutter/material.dart';

/// Homepage-specific design tokens extracted from the existing HTML plan.
///
/// Keeping these values centralized prevents small visual inconsistencies from
/// accumulating across the header, summary, cards, dialogs, and loading states.
abstract final class DashboardDesign {
  static const double maxContentWidth = 1240;
  static const double mobileBreakpoint = 700;
  static const double desktopBreakpoint = 1080;

  static const Color lightCanvas = Color(0xFFFCFCFD);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSubtleSurface = Color(0xFFF7F9FC);
  static const Color lightOffsetSurface = Color(0xFFF1F5F8);
  static const Color lightBorder = Color(0xFFD8E0E8);
  static const Color lightText = Color(0xFF17212B);
  static const Color lightMutedText = Color(0xFF667085);

  static const Color darkCanvas = Color(0xFF0D1318);
  static const Color darkSurface = Color(0xFF141C22);
  static const Color darkSubtleSurface = Color(0xFF182229);
  static const Color darkOffsetSurface = Color(0xFF202C34);
  static const Color darkBorder = Color(0xFF2A3943);
  static const Color darkText = Color(0xFFF4F7F8);
  static const Color darkMutedText = Color(0xFFA3B0B8);

  static const Color primary = Color(0xFF01696F);
  static const Color reviewPending = Color(0xFF9B5B1D);
  static const Color completed = Color(0xFF447A2A);
  static const Color destructive = Color(0xFFB42318);

  static const double cardRadius = 20;
  static const double controlRadius = 14;

  static bool isDark(BuildContext context) =>
      Theme.of(context).brightness == Brightness.dark;

  static Color canvas(BuildContext context) =>
      isDark(context) ? darkCanvas : lightCanvas;

  static Color surface(BuildContext context) =>
      isDark(context) ? darkSurface : lightSurface;

  static Color subtleSurface(BuildContext context) =>
      isDark(context) ? darkSubtleSurface : lightSubtleSurface;

  static Color offsetSurface(BuildContext context) =>
      isDark(context) ? darkOffsetSurface : lightOffsetSurface;

  static Color border(BuildContext context) =>
      isDark(context) ? darkBorder : lightBorder;

  static Color text(BuildContext context) =>
      isDark(context) ? darkText : lightText;

  static Color mutedText(BuildContext context) =>
      isDark(context) ? darkMutedText : lightMutedText;

  static List<BoxShadow> softShadow(BuildContext context) {
    if (isDark(context)) return const [];
    return const [
      BoxShadow(
        color: Color(0x0A101828),
        blurRadius: 28,
        offset: Offset(0, 12),
      ),
    ];
  }
}

/// Exact motion timings and curves used by the homepage.
///
/// These curves settle quickly without spring simulation or shader work, which
/// keeps motion polished while remaining inexpensive on low-end devices.
abstract final class DashboardMotion {
  static const Duration entranceDuration = Duration(milliseconds: 920);
  static const Duration pressDuration = Duration(milliseconds: 120);
  static const Duration hoverDuration = Duration(milliseconds: 180);
  static const Duration skeletonDuration = Duration(milliseconds: 1350);

  static const Curve entranceCurve = Cubic(0.16, 1, 0.3, 1);
  static const Curve interactionCurve = Cubic(0.2, 0.8, 0.2, 1);
  static const Curve breathingCurve = Cubic(0.45, 0, 0.55, 1);
}
