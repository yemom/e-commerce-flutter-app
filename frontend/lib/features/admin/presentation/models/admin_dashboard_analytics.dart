import 'package:e_commerce_app_with_django/features/admin/presentation/models/admin_chart_segment.dart';

class AdminDashboardAnalytics {
  const AdminDashboardAnalytics({
    required this.totalRevenue,
    required this.averageOrderValue,
    required this.totalOrders,
    required this.verifiedPaymentCount,
    required this.revenueTrend,
    required this.statusSegments,
    required this.topCategorySegments,
    required this.topCategoryTotal,
    required this.trafficSegments,
  });

  final double totalRevenue;
  final double averageOrderValue;
  final int totalOrders;
  final int verifiedPaymentCount;
  final List<double> revenueTrend;
  final List<AdminChartSegment> statusSegments;
  final List<AdminChartSegment> topCategorySegments;
  final int topCategoryTotal;
  final List<AdminChartSegment> trafficSegments;
}
