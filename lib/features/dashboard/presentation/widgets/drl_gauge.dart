import 'dart:math' as math;
import 'package:flutter/material.dart';

import 'package:engineering_werk/features/dashboard/presentation/theme/dashboard_design.dart';

class DrlGauge extends StatelessWidget {
  const DrlGauge({
    required this.progress,
    this.size = 200,
    super.key,
  });

  final double progress;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      // Height is half the width plus some padding for bottom text
      height: (size / 2) + 40,
      child: CustomPaint(
        painter: _DrlGaugePainter(
          progress: progress,
          backgroundColor: DashboardDesign.offsetSurface(context),
          progressColor: DashboardDesign.primary,
          needleColor: Colors.grey.shade600,
          textColor: DashboardDesign.text(context),
        ),
      ),
    );
  }
}

class _DrlGaugePainter extends CustomPainter {
  _DrlGaugePainter({
    required this.progress,
    required this.backgroundColor,
    required this.progressColor,
    required this.needleColor,
    required this.textColor,
  });

  final double progress;
  final Color backgroundColor;
  final Color progressColor;
  final Color needleColor;
  final Color textColor;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height - 40);
    final radius = size.width / 2;
    final strokeWidth = size.width * 0.15; // 15% of width for the arc thickness

    // 1. Draw background arc
    final bgPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;

    final rect = Rect.fromCircle(center: center, radius: radius - (strokeWidth / 2));
    
    // Flutter angles: 0 is right (3 o'clock), pi is left (9 o'clock)
    canvas.drawArc(rect, math.pi, math.pi, false, bgPaint);

    // 2. Draw progress arc
    final progressPaint = Paint()
      ..color = progressColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.butt;
    
    final sweepAngle = math.pi * progress;
    canvas.drawArc(rect, math.pi, sweepAngle, false, progressPaint);

    // 3. Draw needle
    final needleAngle = math.pi + sweepAngle;
    // Needle tip is near the inner edge of the arc
    final needleLength = radius - strokeWidth;
    final needleTip = Offset(
      center.dx + needleLength * math.cos(needleAngle),
      center.dy + needleLength * math.sin(needleAngle),
    );

    final needlePaint = Paint()
      ..color = needleColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = size.width * 0.02
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(center, needleTip, needlePaint);

    // Draw a small circle at the base of the needle
    final pivotPaint = Paint()
      ..color = needleColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, size.width * 0.04, pivotPaint);

    // 4. Draw labels
    _drawText(canvas, '0%', Offset(strokeWidth / 2, center.dy + 10), size.width * 0.07, Alignment.topCenter, fontWeight: FontWeight.w600);
    _drawText(canvas, '100%', Offset(size.width - (strokeWidth / 2), center.dy + 10), size.width * 0.07, Alignment.topCenter, fontWeight: FontWeight.w600);
    
    final richTextSpan = TextSpan(
      children: [
        TextSpan(
          text: '${(progress * 100).toStringAsFixed(2)}%',
          style: TextStyle(
            color: progressColor,
            fontSize: size.width * 0.09,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );

    _drawRichText(
      canvas,
      richTextSpan,
      Offset(center.dx, center.dy - (size.width * 0.25)),
      Alignment.topCenter,
      textAlign: TextAlign.center,
    );
  }

  void _drawRichText(
    Canvas canvas,
    TextSpan textSpan,
    Offset position,
    Alignment alignment, {
    TextAlign textAlign = TextAlign.left,
  }) {
    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
      textAlign: textAlign,
    );
    textPainter.layout();

    // Adjust position based on alignment
    double dx = position.dx;
    double dy = position.dy;

    if (alignment == Alignment.topLeft) {
      // position is top-left, no adjustment
    } else if (alignment == Alignment.topRight) {
      dx -= textPainter.width;
    } else if (alignment == Alignment.topCenter) {
      dx -= textPainter.width / 2;
    }

    textPainter.paint(canvas, Offset(dx, dy));
  }

  void _drawText(
    Canvas canvas,
    String text,
    Offset position,
    double fontSize,
    Alignment alignment, {
    TextAlign textAlign = TextAlign.left,
    FontWeight fontWeight = FontWeight.normal,
  }) {
    final textSpan = TextSpan(
      text: text,
      style: TextStyle(
        color: textColor,
        fontSize: fontSize,
        fontWeight: fontWeight,
      ),
    );

    _drawRichText(
      canvas,
      textSpan,
      position,
      alignment,
      textAlign: textAlign,
    );
  }

  @override
  bool shouldRepaint(covariant _DrlGaugePainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.backgroundColor != backgroundColor ||
        oldDelegate.progressColor != progressColor ||
        oldDelegate.textColor != textColor;
  }
}
