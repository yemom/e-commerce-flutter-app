import 'package:flutter/material.dart';

class AdminLineChartPainter extends CustomPainter {
  const AdminLineChartPainter({
    required this.points,
    required this.lineColor,
    required this.fillColor,
  });

  final List<double> points;
  final Color lineColor;
  final Color fillColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) {
      return;
    }

    final maxValue = points.reduce((a, b) => a > b ? a : b);
    final positions = <Offset>[];
    for (var i = 0; i < points.length; i++) {
      final value = points[i];
      final normalized = maxValue == 0 ? 0.0 : value / maxValue;
      final x = points.length == 1
          ? size.width / 2
          : (size.width / (points.length - 1)) * i;
      final y = size.height - (normalized * (size.height - 16)) - 8;
      positions.add(Offset(x, y));
    }

    final linePaint = Paint()
      ..color = lineColor
      ..strokeWidth = 3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final fillPaint = Paint()
      ..color = fillColor
      ..style = PaintingStyle.fill;

    final fillPath = Path()..moveTo(positions.first.dx, size.height);
    for (final position in positions) {
      fillPath.lineTo(position.dx, position.dy);
    }
    fillPath.lineTo(positions.last.dx, size.height);
    fillPath.close();

    final linePath = Path()..moveTo(positions.first.dx, positions.first.dy);
    for (var index = 1; index < positions.length; index++) {
      linePath.lineTo(positions[index].dx, positions[index].dy);
    }

    canvas.drawPath(fillPath, fillPaint);
    canvas.drawPath(linePath, linePaint);

    final dotPaint = Paint()..color = lineColor;
    for (final position in positions) {
      canvas.drawCircle(position, 3.4, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant AdminLineChartPainter oldDelegate) {
    return oldDelegate.points != points ||
        oldDelegate.lineColor != lineColor ||
        oldDelegate.fillColor != fillColor;
  }
}
