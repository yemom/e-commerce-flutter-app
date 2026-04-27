import 'package:flutter/material.dart';

class AdminChartSegment {
  const AdminChartSegment({
    required this.label,
    required this.count,
    required this.color,
    required this.share,
  });

  final String label;
  final int count;
  final Color color;
  final double share;
}
