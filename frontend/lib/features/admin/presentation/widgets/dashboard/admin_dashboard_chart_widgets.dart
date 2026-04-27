import 'package:flutter/material.dart';

import 'package:e_commerce_app_with_django/features/admin/presentation/models/admin_chart_segment.dart';
import 'package:e_commerce_app_with_django/features/admin/presentation/painters/admin_donut_chart_painter.dart';
import 'package:e_commerce_app_with_django/features/admin/presentation/painters/admin_line_chart_painter.dart';
import 'package:e_commerce_app_with_django/features/admin/presentation/services/admin_dashboard_formatters.dart';

class DashboardMiniLineChart extends StatelessWidget {
  const DashboardMiniLineChart({super.key, required this.points});

  final List<double> points;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: AdminLineChartPainter(
        points: points,
        lineColor: const Color(0xFFFF8A00),
        fillColor: const Color(0x33FF8A00),
      ),
      child: const SizedBox.expand(),
    );
  }
}

class DashboardMiniDonutChart extends StatelessWidget {
  const DashboardMiniDonutChart({
    super.key,
    required this.segments,
    required this.centerTitle,
    required this.centerSubtitle,
  });

  final List<AdminChartSegment> segments;
  final String centerTitle;
  final String centerSubtitle;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 140,
      height: 140,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            painter: AdminDonutChartPainter(segments: segments),
            child: const SizedBox.expand(),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                centerTitle,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                centerSubtitle,
                style: const TextStyle(color: Color(0xFF7B8091)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class DashboardTrafficProgressRow extends StatelessWidget {
  const DashboardTrafficProgressRow({super.key, required this.segment});

  final AdminChartSegment segment;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  segment.label,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
              Text(
                formatDashboardPercent(segment.share),
                style: const TextStyle(color: Color(0xFF7B8091)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              minHeight: 10,
              value: segment.share,
              backgroundColor: const Color(0xFFF1F3F8),
              valueColor: AlwaysStoppedAnimation<Color>(segment.color),
            ),
          ),
        ],
      ),
    );
  }
}
