import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'package:e_commerce_app_with_django/features/admin/presentation/models/admin_chart_segment.dart';

class AdminDonutChartPainter extends CustomPainter {
  const AdminDonutChartPainter({required this.segments});

  final List<AdminChartSegment> segments;

  @override
  void paint(Canvas canvas, Size size) {
    final total = segments.fold<int>(0, (sum, segment) => sum + segment.count);
    final rect = Rect.fromCircle(
      center: Offset(size.width / 2, size.height / 2),
      radius: size.shortestSide / 2 - 10,
    );
    const strokeWidth = 18.0;

    final basePaint = Paint()
      ..color = const Color(0xFFE9ECF3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawArc(rect, 0, 2 * math.pi, false, basePaint);

    if (total == 0) {
      return;
    }

    var startAngle = -math.pi / 2;
    for (final segment in segments) {
      final sweep = (segment.count / total) * 2 * math.pi;
      final paint = Paint()
        ..color = segment.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(rect, startAngle, sweep, false, paint);
      startAngle += sweep;
    }
  }

  @override
  bool shouldRepaint(covariant AdminDonutChartPainter oldDelegate) {
    return oldDelegate.segments != segments;
  }
}
