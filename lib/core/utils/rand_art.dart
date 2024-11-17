import 'package:flutter/material.dart';
import 'dart:math';
import '../constants/colors.dart';

enum PatternType { lines, curves, circles, polygons }

class RandomArtPainter extends CustomPainter {
  final Color primaryColor;
  final Color secondaryColor;
  final int numPoints;
  final PatternType patternType;
  final double animationValue;
  final int layers;
  final double opacity;
  final double strokeWidth;

  RandomArtPainter({
    this.primaryColor = AppColors.extraLightGray,
    this.secondaryColor = AppColors.blue,
    this.numPoints = 50,
    this.patternType = PatternType.lines,
    this.animationValue = 0.0,
    this.layers = 3,
    this.opacity = 0.15,
    this.strokeWidth = 2.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final random = Random();

    for (int layer = 0; layer < layers; layer++) {
      final progress = layer / layers;
      final paint = Paint()
        ..strokeWidth = strokeWidth - (progress * 0.5)
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;

      // Create gradient colors with custom opacity
      final gradientColors = [
        Color.lerp(primaryColor, secondaryColor, progress)!
            .withOpacity(opacity - (progress * 0.02)),
        Color.lerp(secondaryColor, primaryColor, progress)!
            .withOpacity(opacity - (progress * 0.02)),
      ];

      paint.shader = LinearGradient(
        colors: gradientColors,
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Offset.zero & size);

      switch (patternType) {
        case PatternType.lines:
          _drawLines(canvas, size, paint, random, layer);
          break;
        case PatternType.curves:
          _drawCurves(canvas, size, paint, random, layer);
          break;
        case PatternType.circles:
          _drawCircles(canvas, size, paint, random, layer);
          break;
        case PatternType.polygons:
          _drawPolygons(canvas, size, paint, random, layer);
          break;
      }
    }
  }

  void _drawLines(
      Canvas canvas, Size size, Paint paint, Random random, int layer) {
    for (var i = 0; i < numPoints; i++) {
      final phase = (i / numPoints) * 2 * pi;
      final amplitude = size.width * 0.1;

      final x1 = random.nextDouble() * size.width;
      final y1 = random.nextDouble() * size.height;
      final x2 = x1 + cos(phase + animationValue) * amplitude;
      final y2 = y1 + sin(phase + animationValue) * amplitude;

      canvas.drawLine(
        Offset(x1, y1),
        Offset(x2, y2),
        paint,
      );
    }
  }

  void _drawCurves(
      Canvas canvas, Size size, Paint paint, Random random, int layer) {
    for (var i = 0; i < numPoints; i++) {
      final path = Path();
      final startX = random.nextDouble() * size.width;
      final startY = random.nextDouble() * size.height;

      path.moveTo(startX, startY);

      final controlPoint1X =
          startX + random.nextDouble() * 100 * cos(animationValue);
      final controlPoint1Y =
          startY + random.nextDouble() * 100 * sin(animationValue);
      final controlPoint2X =
          startX + random.nextDouble() * 100 * cos(animationValue + pi / 2);
      final controlPoint2Y =
          startY + random.nextDouble() * 100 * sin(animationValue + pi / 2);
      final endX = startX + random.nextDouble() * 100;
      final endY = startY + random.nextDouble() * 100;

      path.cubicTo(
        controlPoint1X,
        controlPoint1Y,
        controlPoint2X,
        controlPoint2Y,
        endX,
        endY,
      );

      canvas.drawPath(path, paint);
    }
  }

  void _drawCircles(
      Canvas canvas, Size size, Paint paint, Random random, int layer) {
    for (var i = 0; i < numPoints; i++) {
      final centerX = random.nextDouble() * size.width;
      final centerY = random.nextDouble() * size.height;
      final radius = random.nextDouble() * 50 * (1 + sin(animationValue + i));

      canvas.drawCircle(
        Offset(centerX, centerY),
        radius,
        paint,
      );
    }
  }

  void _drawPolygons(
      Canvas canvas, Size size, Paint paint, Random random, int layer) {
    for (var i = 0; i < numPoints; i++) {
      final centerX = random.nextDouble() * size.width;
      final centerY = random.nextDouble() * size.height;
      final radius = random.nextDouble() * 30;
      final sides = random.nextInt(3) + 3; // 3 to 5 sides

      final path = Path();
      for (var j = 0; j < sides; j++) {
        final angle = (j / sides) * 2 * pi + animationValue;
        final x = centerX + cos(angle) * radius;
        final y = centerY + sin(angle) * radius;

        if (j == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      path.close();
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(RandomArtPainter oldDelegate) =>
      oldDelegate.animationValue != animationValue ||
      oldDelegate.patternType != patternType;
}
