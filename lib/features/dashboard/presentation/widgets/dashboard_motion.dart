import 'package:flutter/material.dart';

import '../theme/dashboard_design.dart';

/// A small, composited scale interaction for buttons and cards.
///
/// Transform-only animation avoids relayout. The child is also isolated so the
/// interaction does not repaint neighboring slivers.
class PressScale extends StatefulWidget {
  const PressScale({
    required this.child,
    required this.onTap,
    this.semanticLabel,
    this.pressedScale = 0.985,
    this.hoveredScale = 1.006,
    super.key,
  });

  final Widget child;
  final VoidCallback? onTap;
  final String? semanticLabel;
  final double pressedScale;
  final double hoveredScale;

  @override
  State<PressScale> createState() => _PressScaleState();
}

class _PressScaleState extends State<PressScale> {
  bool _isPressed = false;
  bool _isHovered = false;
  bool _isFocused = false;

  void _setPressed(bool value) {
    if (_isPressed == value || widget.onTap == null) return;
    setState(() => _isPressed = value);
  }

  @override
  Widget build(BuildContext context) {
    final scale = _isPressed
        ? widget.pressedScale
        : ((_isHovered || _isFocused) && widget.onTap != null
              ? widget.hoveredScale
              : 1.0);

    return Semantics(
      button: widget.onTap != null,
      label: widget.semanticLabel,
      child: FocusableActionDetector(
        enabled: widget.onTap != null,
        mouseCursor: widget.onTap == null
            ? SystemMouseCursors.basic
            : SystemMouseCursors.click,
        onShowHoverHighlight: (value) => setState(() => _isHovered = value),
        onShowFocusHighlight: (value) => setState(() => _isFocused = value),
        actions: <Type, Action<Intent>>{
          ActivateIntent: CallbackAction<ActivateIntent>(
            onInvoke: (_) {
              widget.onTap?.call();
              return null;
            },
          ),
        },
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: widget.onTap,
          onTapDown: (_) => _setPressed(true),
          onTapCancel: () => _setPressed(false),
          onTapUp: (_) => _setPressed(false),
          child: AnimatedScale(
            scale: scale,
            duration: _isPressed
                ? DashboardMotion.pressDuration
                : DashboardMotion.hoverDuration,
            curve: DashboardMotion.interactionCurve,
            child: RepaintBoundary(child: widget.child),
          ),
        ),
      ),
    );
  }
}

/// Fades and translates a child through an explicit interval on the homepage's
/// single entrance controller. Translation is deliberately small and vertical.
class StaggeredReveal extends StatelessWidget {
  const StaggeredReveal({
    required this.animation,
    required this.interval,
    required this.child,
    this.offset = const Offset(0, 0.035),
    super.key,
  });

  final Animation<double> animation;
  final Interval interval;
  final Widget child;
  final Offset offset;

  @override
  Widget build(BuildContext context) {
    final curved = CurvedAnimation(parent: animation, curve: interval);
    final opacity = Tween<double>(begin: 0, end: 1).animate(curved);
    final slide = Tween<Offset>(
      begin: offset,
      end: Offset.zero,
    ).animate(curved);

    return FadeTransition(
      opacity: opacity,
      child: SlideTransition(position: slide, child: child),
    );
  }
}
