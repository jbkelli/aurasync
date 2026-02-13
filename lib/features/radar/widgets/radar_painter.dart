import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Paints the static radar background (concentric circles and grid lines)
class RadarBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = size.width / 2;

    // Draw concentric circles
    final circlePaint = Paint()
      ..color = const Color(0xFF00FFF0).withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    for (int i = 1; i <= 4; i++) {
      final radius = maxRadius * (i / 4);
      canvas.drawCircle(center, radius, circlePaint);
    }

    // Draw cross-hair lines
    final linePaint = Paint()
      ..color = const Color(0xFF00FFF0).withValues(alpha: 0.1)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    // Horizontal line
    canvas.drawLine(
      Offset(0, center.dy),
      Offset(size.width, center.dy),
      linePaint,
    );

    // Vertical line
    canvas.drawLine(
      Offset(center.dx, 0),
      Offset(center.dx, size.height),
      linePaint,
    );

    // Diagonal lines
    canvas.drawLine(
      const Offset(0, 0),
      Offset(size.width, size.height),
      linePaint,
    );

    canvas.drawLine(
      Offset(size.width, 0),
      Offset(0, size.height),
      linePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

/// Paints the rotating radar sweep effect
class RadarSweepPainter extends CustomPainter {
  final double rotation;

  RadarSweepPainter({required this.rotation});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Create gradient sweep
    final sweepGradient = SweepGradient(
      colors: [
        const Color(0xFF00FFF0).withValues(alpha: 0.0),
        const Color(0xFF00FFF0).withValues(alpha: 0.3),
        const Color(0xFF00FFF0).withValues(alpha: 0.0),
      ],
      stops: const [0.0, 0.05, 0.15],
      transform: GradientRotation(rotation),
    );

    final paint = Paint()
      ..shader = sweepGradient.createShader(Rect.fromCircle(
        center: center,
        radius: radius,
      ));

    canvas.drawCircle(center, radius, paint);

    // Draw sweep line
    final lineEndX = center.dx + radius * math.cos(rotation);
    final lineEndY = center.dy + radius * math.sin(rotation);

    final linePaint = Paint()
      ..color = const Color(0xFF00FFF0).withValues(alpha: 0.8)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    canvas.drawLine(
      center,
      Offset(lineEndX, lineEndY),
      linePaint,
    );
  }

  @override
  bool shouldRepaint(RadarSweepPainter oldDelegate) {
    return rotation != oldDelegate.rotation;
  }
}
