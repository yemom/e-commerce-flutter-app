import 'package:flutter/material.dart';

import 'package:e_commerce_app_with_django/core/presentation/widgets/app_formatters.dart';
import 'package:e_commerce_app_with_django/features/admin/presentation/models/admin_dashboard_analytics.dart';
import 'package:e_commerce_app_with_django/features/admin/presentation/widgets/dashboard/admin_dashboard_chart_widgets.dart';
import 'package:e_commerce_app_with_django/features/admin/presentation/services/admin_dashboard_formatters.dart';
import 'package:e_commerce_app_with_django/features/admin/presentation/widgets/dashboard/dashboard_common_widgets.dart';

class AdminDashboardAnalyticsBoard extends StatelessWidget {
  const AdminDashboardAnalyticsBoard({
    super.key,
    required this.analytics,
    required this.branchCount,
    required this.productCount,
    required this.categoryCount,
    required this.paymentCount,
    required this.pendingAdminCount,
    required this.activeAdminCount,
  });

  final AdminDashboardAnalytics analytics;
  final int branchCount;
  final int productCount;
  final int categoryCount;
  final int paymentCount;
  final int pendingAdminCount;
  final int activeAdminCount;

  @override
  Widget build(BuildContext context) {
    // Break the analytics area into cards so each summary stays easy to scan.
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 900;

        final revenueCard = DashboardDataCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Revenue analytics',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Chip(label: Text('${analytics.totalOrders} orders')),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 170,
                child: DashboardMiniLineChart(points: analytics.revenueTrend),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: DashboardTinyStat(
                      label: 'Total sales',
                      value: formatPrice(analytics.totalRevenue),
                    ),
                  ),
                  Expanded(
                    child: DashboardTinyStat(
                      label: 'Avg order',
                      value: formatPrice(analytics.averageOrderValue),
                    ),
                  ),
                  Expanded(
                    child: DashboardTinyStat(
                      label: 'Verified',
                      value: '${analytics.verifiedPaymentCount}',
                    ),
                  ),
                ],
              ),
            ],
          ),
        );

        final categoryCard = DashboardDataCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Top categories',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Chip(
                    label: Text('${analytics.topCategorySegments.length} shown'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 132,
                child: Center(
                  child: DashboardMiniDonutChart(
                    segments: analytics.topCategorySegments,
                    centerTitle: '${analytics.topCategoryTotal}',
                    centerSubtitle: 'items',
                  ),
                ),
              ),
              const SizedBox(height: 10),
              for (final segment in analytics.topCategorySegments)
                DashboardBreakdownRow(
                  label: segment.label,
                  valueText: '${segment.count}',
                  percentText: formatDashboardPercent(segment.share),
                  color: segment.color,
                ),
            ],
          ),
        );

        final trafficCard = DashboardDataCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Traffic sources',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  Chip(
                    label: Text('${analytics.trafficSegments.length} branches'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (analytics.trafficSegments.isEmpty)
                const DashboardEmptyHint(text: 'No traffic data yet.')
              else
                // Each branch gets its own progress row to keep the chart readable.
                for (final segment in analytics.trafficSegments)
                  DashboardTrafficProgressRow(segment: segment),
            ],
          ),
        );

        final statsCard = DashboardDataCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Quick statistics',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              DashboardMiniMetric(label: 'Branches', value: '$branchCount'),
              DashboardMiniMetric(label: 'Products', value: '$productCount'),
              DashboardMiniMetric(label: 'Categories', value: '$categoryCount'),
              DashboardMiniMetric(
                label: 'Payment options',
                value: '$paymentCount',
              ),
              DashboardMiniMetric(
                label: 'Pending admins',
                value: '$pendingAdminCount',
              ),
              DashboardMiniMetric(
                label: 'Active admins',
                value: '$activeAdminCount',
              ),
            ],
          ),
        );

        if (isWide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 2, child: revenueCard),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  children: [
                    categoryCard,
                    const SizedBox(height: 12),
                    trafficCard,
                    const SizedBox(height: 12),
                    statsCard,
                  ],
                ),
              ),
            ],
          );
        }

        return Column(
          children: [
            revenueCard,
            const SizedBox(height: 12),
            categoryCard,
            const SizedBox(height: 12),
            trafficCard,
            const SizedBox(height: 12),
            statsCard,
          ],
        );
      },
    );
  }
}
