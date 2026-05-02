import 'dart:math';
import 'package:flutter/material.dart';
import '../../core/theme_engine/turbo_colors.dart';

/// Painter for the static background of the radar (rings and crosshairs).
class StaticRadarPainter extends CustomPainter {
  final TurboColors colors;
  
  const StaticRadarPainter({required this.colors});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = min(size.width, size.height) / 2;

    // ── Concentric rings ───────────────────────────────────────────────
    final ringPaint = Paint()
      ..color = colors.radarRing
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;

    for (var i = 1; i <= 4; i++) {
      canvas.drawCircle(center, maxRadius * (i / 4), ringPaint);
    }

    // ── Cross-hair lines ───────────────────────────────────────────────
    final crossPaint = Paint()
      ..color = colors.radarRing.withValues(alpha: 0.4)
      ..strokeWidth = 0.5;

    canvas.drawLine(
      Offset(center.dx - maxRadius, center.dy),
      Offset(center.dx + maxRadius, center.dy),
      crossPaint,
    );
    canvas.drawLine(
      Offset(center.dx, center.dy - maxRadius),
      Offset(center.dx, center.dy + maxRadius),
      crossPaint,
    );
  }

  @override
  bool shouldRepaint(StaticRadarPainter oldDelegate) => colors != oldDelegate.colors;
}

/// Painter for the dynamic rotating sweep.
class SweepPainter extends CustomPainter {
  final double sweepAngle;
  final TurboColors colors;

  SweepPainter({required this.sweepAngle, required this.colors});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = min(size.width, size.height) / 2;

    // ── Sweep gradient (the "radar arm") ───────────────────────────────
    final sweepRect = Rect.fromCircle(center: center, radius: maxRadius);
    final sweepGradient = SweepGradient(
      startAngle: sweepAngle - 0.8,
      endAngle: sweepAngle,
      colors: [
        colors.radarSweep.withValues(alpha: 0.0),
        colors.radarSweep.withValues(alpha: 0.15),
      ],
      transform: const GradientRotation(0),
    );

    final sweepPaint = Paint()
      ..shader = sweepGradient.createShader(sweepRect)
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, maxRadius, sweepPaint);

    // ── Sweep line ─────────────────────────────────────────────────────
    final linePaint = Paint()
      ..color = colors.radarSweep.withValues(alpha: 0.6)
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    final lineEnd = Offset(
      center.dx + maxRadius * cos(sweepAngle),
      center.dy + maxRadius * sin(sweepAngle),
    );
    canvas.drawLine(center, lineEnd, linePaint);

    // ── Center dot ─────────────────────────────────────────────────────
    final centerDotPaint = Paint()
      ..color = colors.primaryGlow
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 4, centerDotPaint);

    final centerGlow = Paint()
      ..color = colors.primaryGlow.withValues(alpha: 0.2)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, 10, centerGlow);
  }

  @override
  bool shouldRepaint(SweepPainter oldDelegate) {
    return sweepAngle != oldDelegate.sweepAngle || colors != oldDelegate.colors;
  }
}
