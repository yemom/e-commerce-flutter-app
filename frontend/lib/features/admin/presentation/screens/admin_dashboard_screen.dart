/// Shows admin controls for branches, orders, categories, payments, and admins.
library;

import 'package:flutter/material.dart';

import 'package:e_commerce_app_with_django/core/presentation/widgets/app_formatters.dart';
import 'package:e_commerce_app_with_django/features/admin/presentation/providers/admin_settings_provider.dart';
import 'package:e_commerce_app_with_django/features/auth/domain/models/user_role.dart';
import 'package:e_commerce_app_with_django/features/branches/domain/models/branch.dart';
import 'package:e_commerce_app_with_django/features/categories/domain/models/category.dart';
import 'package:e_commerce_app_with_django/features/orders/domain/models/order.dart';
import 'package:e_commerce_app_with_django/features/payment/domain/models/payment.dart';
import 'package:e_commerce_app_with_django/features/products/domain/models/product.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({
    super.key,
    required this.branches,
    required this.orders,
    required this.onAddProduct,
    required this.onVerifyPayment,
    required this.onMarkOrderShipped,
    required this.onMarkOrderDelivered,
    required this.onLogout,
    this.dashboardTitle = 'Admin dashboard',
    this.roleSections = const ['Products', 'Orders', 'Payments', 'Categories'],
    this.showBranchesSection = true,
    this.products = const [],
    this.adminCategories = const [],
    this.adminPaymentOptions = const [],
    this.adminAccounts = const [],
    this.onAddCategory,
    this.onToggleCategory,
    this.onFetchCategory,
    this.onUpdateCategory,
    this.onDeleteCategory,
    this.onAddPaymentOption,
    this.onFetchPaymentOption,
    this.onUpdatePaymentOption,
    this.onDeletePaymentOption,
    this.onTogglePaymentOption,
    this.onUpdateProductPrice,
    this.onDeleteProduct,
    this.onCreateAdminAccount,
    this.onFetchAdminAccount,
    this.onUpdateAdminAccount,
    this.onApproveAdmin,
    this.onRemoveAdmin,
    this.onFetchBranch,
    this.onUpdateBranch,
    this.onDeleteBranch,
    this.onOpenOrdersPage,
    this.onOpenInventoryPage,
    this.onOpenBranchesPage,
    this.onOpenCategoriesPage,
    this.onOpenAdminRequestsPage,
    this.onOpenPaymentOptionsPage,
  });

  final List<Branch> branches;
  final List<Order> orders;
  final VoidCallback onAddProduct;
  final ValueChanged<String> onVerifyPayment;
  final ValueChanged<String> onMarkOrderShipped;
  final ValueChanged<String> onMarkOrderDelivered;
  final Future<void> Function() onLogout;
  final String dashboardTitle;
  final List<String> roleSections;
  final bool showBranchesSection;
  final List<Product> products;
  final List<Category> adminCategories;
  final List<PaymentOption> adminPaymentOptions;
  final List<AdminAccount> adminAccounts;
  final Future<void> Function({
    required String name,
    required String description,
    required String imageUrl,
  })?
  onAddCategory;
  final Future<void> Function(String categoryId, bool isActive)?
  onToggleCategory;
  final Future<Category?> Function(String categoryId)? onFetchCategory;
  final Future<void> Function({
    required String categoryId,
    required String name,
    required String description,
    required String imageUrl,
  })?
  onUpdateCategory;
  final Future<void> Function(String categoryId)? onDeleteCategory;
  final Future<void> Function({required String label, String? iconUrl})?
  onAddPaymentOption;
  final Future<PaymentOption?> Function(String optionId)? onFetchPaymentOption;
  final Future<void> Function({
    required String optionId,
    required String label,
    String? iconUrl,
  })?
  onUpdatePaymentOption;
  final Future<void> Function(String optionId)? onDeletePaymentOption;
  final Future<void> Function(String optionId, bool isEnabled)?
  onTogglePaymentOption;
  final Future<void> Function(Product product, double newPrice)?
  onUpdateProductPrice;
  final Future<void> Function(String productId)? onDeleteProduct;
  final Future<void> Function({
    required String name,
    required String email,
    required String password,
  })?
  onCreateAdminAccount;
  final Future<AdminAccount?> Function(String userId)? onFetchAdminAccount;
  final Future<void> Function({
    required String userId,
    required String name,
    required String email,
  })?
  onUpdateAdminAccount;
  final Future<void> Function({required String userId, required bool approved})?
  onApproveAdmin;
  final Future<void> Function(String userId)? onRemoveAdmin;
  final Future<Branch?> Function(String branchId)? onFetchBranch;
  final Future<void> Function({
    required String branchId,
    required String name,
    required String location,
    required String phoneNumber,
    required bool isActive,
  })?
  onUpdateBranch;
  final Future<void> Function(String branchId)? onDeleteBranch;
  final VoidCallback? onOpenOrdersPage;
  final VoidCallback? onOpenInventoryPage;
  final VoidCallback? onOpenBranchesPage;
  final VoidCallback? onOpenCategoriesPage;
  final VoidCallback? onOpenAdminRequestsPage;
  final VoidCallback? onOpenPaymentOptionsPage;

  @override
  Widget build(BuildContext context) {
    // Pending payment count powers the alert bubbles across the dashboard.
    final pendingPayments = orders
        .where((order) => order.payment.status == PaymentStatus.pending)
        .length;

    return Scaffold(
      appBar: AppBar(
        title: Text(dashboardTitle),
        actions: [
          IconButton(
            tooltip: 'Add product',
            onPressed: onAddProduct,
            icon: const Icon(Icons.add_box_outlined),
          ),
          _DashboardActionIcon(
            icon: Icons.receipt_long_outlined,
            tooltip: 'Open orders (pending payments: $pendingPayments)',
            badgeCount: pendingPayments,
            onPressed: onOpenOrdersPage,
          ),
          IconButton(
            tooltip: 'Open inventory',
            onPressed: onOpenInventoryPage,
            icon: const Icon(Icons.inventory_2_outlined),
          ),
          IconButton(
            tooltip: 'Log out',
            onPressed: () => onLogout(),
            icon: const Icon(Icons.logout_rounded),
          ),
          const SizedBox(width: 8),
        ],
      ),
      // Keep shell lightweight by delegating complex content rendering.
      body: _AdminDashboardBody(
        dashboardTitle: dashboardTitle,
        roleSections: roleSections,
        showBranchesSection: showBranchesSection,
        branches: branches,
        orders: orders,
        products: products,
        adminCategories: adminCategories,
        adminPaymentOptions: adminPaymentOptions,
        adminAccounts: adminAccounts,
        onAddProduct: onAddProduct,
        onOpenOrdersPage: onOpenOrdersPage,
        onOpenInventoryPage: onOpenInventoryPage,
        onOpenBranchesPage: onOpenBranchesPage,
        onOpenCategoriesPage: onOpenCategoriesPage,
        onOpenAdminRequestsPage: onOpenAdminRequestsPage,
        onOpenPaymentOptionsPage: onOpenPaymentOptionsPage,
        onCreateAdminAccount: onCreateAdminAccount,
        onUpdateBranch: onUpdateBranch,
        onFetchBranch: onFetchBranch,
        onDeleteBranch: onDeleteBranch,
        onAddCategory: onAddCategory,
        onToggleCategory: onToggleCategory,
        onFetchCategory: onFetchCategory,
        onUpdateCategory: onUpdateCategory,
        onDeleteCategory: onDeleteCategory,
        onAddPaymentOption: onAddPaymentOption,
        onTogglePaymentOption: onTogglePaymentOption,
        onFetchPaymentOption: onFetchPaymentOption,
        onUpdatePaymentOption: onUpdatePaymentOption,
        onDeletePaymentOption: onDeletePaymentOption,
      ),
    );
  }

  // CRUD dialogs moved to dedicated admin pages for better maintainability.
}

// The hero banner gives admins a fast summary before they scroll into details.
class _HeroCard extends StatelessWidget {
  const _HeroCard({
    required this.dashboardTitle,
    required this.branchCount,
    required this.orderCount,
    required this.productCount,
    required this.categoryCount,
    required this.paymentCount,
    required this.pendingAdminCount,
    required this.activeAdminCount,
    required this.sectionTags,
  });

  final String dashboardTitle;
  final int branchCount;
  final int orderCount;
  final int productCount;
  final int categoryCount;
  final int paymentCount;
  final int pendingAdminCount;
  final int activeAdminCount;
  final List<String> sectionTags;

  @override
  Widget build(BuildContext context) {
    // Orders card badge uses same pending-payment source for consistency.
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFC8400), Color(0xFFFF9A2E)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1AFF8A00),
            blurRadius: 18,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Operations overview',
                      style: TextStyle(color: Color(0xFFFFF2E7), fontSize: 12),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      dashboardTitle,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        height: 1.05,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Manage branches, requests, categories, payments, and products from one panel.',
                      style: TextStyle(
                        color: Color(0xFFFFF2E7),
                        fontSize: 13,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  'Live control room',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              _HeroMetric(label: 'Branches', value: '$branchCount'),
              _HeroMetric(label: 'Orders', value: '$orderCount'),
              _HeroMetric(label: 'Products', value: '$productCount'),
              _HeroMetric(label: 'Categories', value: '$categoryCount'),
              _HeroMetric(label: 'Payments', value: '$paymentCount'),
              _HeroMetric(label: 'Pending admins', value: '$pendingAdminCount'),
              _HeroMetric(label: 'Active admins', value: '$activeAdminCount'),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: sectionTags
                .map(
                  (tag) => Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 11,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      tag,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ],
      ),
    );
  }
}

class _HeroMetric extends StatelessWidget {
  const _HeroMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(color: Color(0xFFFFF2E7), fontSize: 12),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

// Analytics widgets turn raw data into quick visual summaries for busy admins.
class _AnalyticsBoard extends StatelessWidget {
  const _AnalyticsBoard({
    required this.analytics,
    required this.branchCount,
    required this.productCount,
    required this.categoryCount,
    required this.paymentCount,
    required this.pendingAdminCount,
    required this.activeAdminCount,
  });

  final _AdminAnalytics analytics;
  final int branchCount;
  final int productCount;
  final int categoryCount;
  final int paymentCount;
  final int pendingAdminCount;
  final int activeAdminCount;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 900;

        final revenueCard = _DataCard(
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
                child: _MiniLineChart(points: analytics.revenueTrend),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _TinyStat(
                      label: 'Total sales',
                      value: formatPrice(analytics.totalRevenue),
                    ),
                  ),
                  Expanded(
                    child: _TinyStat(
                      label: 'Avg order',
                      value: formatPrice(analytics.averageOrderValue),
                    ),
                  ),
                  Expanded(
                    child: _TinyStat(
                      label: 'Verified',
                      value: '${analytics.verifiedPaymentCount}',
                    ),
                  ),
                ],
              ),
            ],
          ),
        );

        final categoryCard = _DataCard(
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
                    label: Text(
                      '${analytics.topCategorySegments.length} shown',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 132,
                child: Center(
                  child: _MiniDonutChart(
                    segments: analytics.topCategorySegments,
                    centerTitle: '${analytics.topCategoryTotal}',
                    centerSubtitle: 'items',
                  ),
                ),
              ),
              const SizedBox(height: 10),
              for (final segment in analytics.topCategorySegments)
                _BreakdownRow(
                  label: segment.label,
                  valueText: '${segment.count}',
                  percentText: _percentLabel(segment.share),
                  color: segment.color,
                ),
            ],
          ),
        );

        final trafficCard = _DataCard(
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
                const _EmptyHint(text: 'No traffic data yet.')
              else
                for (final segment in analytics.trafficSegments)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                segment.label,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Text(
                              _percentLabel(segment.share),
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
                            valueColor: AlwaysStoppedAnimation<Color>(
                              segment.color,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
            ],
          ),
        );

        final statsCard = _DataCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Quick statistics',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 12),
              _MiniMetric(label: 'Branches', value: '$branchCount'),
              _MiniMetric(label: 'Products', value: '$productCount'),
              _MiniMetric(label: 'Categories', value: '$categoryCount'),
              _MiniMetric(label: 'Payment options', value: '$paymentCount'),
              _MiniMetric(label: 'Pending admins', value: '$pendingAdminCount'),
              _MiniMetric(label: 'Active admins', value: '$activeAdminCount'),
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

class _DataCard extends StatelessWidget {
  const _DataCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE7ECF3)),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0C1F2937),
            blurRadius: 18,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: child,
    );
  }
}

class _EmptyHint extends StatelessWidget {
  const _EmptyHint({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Text(text, style: const TextStyle(color: Color(0xFF7B8091))),
    );
  }
}

class _MiniMetric extends StatelessWidget {
  const _MiniMetric({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: Color(0xFF6B7280),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Text(value, style: Theme.of(context).textTheme.titleSmall),
        ],
      ),
    );
  }
}

class _TinyStat extends StatelessWidget {
  const _TinyStat({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Color(0xFF7B8091), fontSize: 12),
        ),
        const SizedBox(height: 4),
        Text(value, style: Theme.of(context).textTheme.titleSmall),
      ],
    );
  }
}

class _BreakdownRow extends StatelessWidget {
  const _BreakdownRow({
    required this.label,
    required this.valueText,
    required this.percentText,
    required this.color,
  });

  final String label;
  final String valueText;
  final String percentText;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(label, overflow: TextOverflow.ellipsis)),
          Text(valueText, style: const TextStyle(fontWeight: FontWeight.w700)),
          const SizedBox(width: 8),
          Text(percentText, style: const TextStyle(color: Color(0xFF7B8091))),
        ],
      ),
    );
  }
}

class _SideActionButton extends StatelessWidget {
  const _SideActionButton({
    required this.icon,
    required this.label,
    this.onPressed,
  });

  final IconData icon;
  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: FilledButton.tonalIcon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label),
      ),
    );
  }
}

class _MiniLineChart extends StatelessWidget {
  const _MiniLineChart({required this.points});

  final List<double> points;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _LineChartPainter(
        points: points,
        lineColor: const Color(0xFFFF8A00),
        fillColor: const Color(0x33FF8A00),
      ),
      child: const SizedBox.expand(),
    );
  }
}

class _MiniDonutChart extends StatelessWidget {
  const _MiniDonutChart({
    required this.segments,
    required this.centerTitle,
    required this.centerSubtitle,
  });

  final List<_ChartSegment> segments;
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
            painter: _DonutChartPainter(segments: segments),
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

class _ChartSegment {
  const _ChartSegment({
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

class _AdminAnalytics {
  const _AdminAnalytics({
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
  final List<_ChartSegment> statusSegments;
  final List<_ChartSegment> topCategorySegments;
  final int topCategoryTotal;
  final List<_ChartSegment> trafficSegments;

  factory _AdminAnalytics.fromData({
    required List<Order> orders,
    required List<Product> products,
    required List<Branch> branches,
    required List<Category> categories,
  }) {
    final totalRevenue = orders.fold<double>(
      0,
      (sum, order) => sum + order.total,
    );
    final averageOrderValue = orders.isEmpty ? 0 : totalRevenue / orders.length;
    final verifiedPaymentCount = orders
        .where((order) => order.payment.status == PaymentStatus.verified)
        .length;

    final statusCounts = <OrderStatus, int>{
      for (final status in OrderStatus.values)
        status: orders.where((order) => order.status == status).length,
    };
    final statusSegments = [
      _ChartSegment(
        label: 'Pending',
        count: statusCounts[OrderStatus.pending] ?? 0,
        color: const Color(0xFFFFC26B),
        share: 0,
      ),
      _ChartSegment(
        label: 'Confirmed',
        count: statusCounts[OrderStatus.confirmed] ?? 0,
        color: const Color(0xFFFFA62B),
        share: 0,
      ),
      _ChartSegment(
        label: 'Shipped',
        count: statusCounts[OrderStatus.shipped] ?? 0,
        color: const Color(0xFFEE7B15),
        share: 0,
      ),
      _ChartSegment(
        label: 'Delivered',
        count: statusCounts[OrderStatus.delivered] ?? 0,
        color: const Color(0xFF5E56E7),
        share: 0,
      ),
    ].where((segment) => segment.count > 0).toList();

    final categoryCounts = <String, int>{};
    for (final product in products) {
      categoryCounts[product.categoryId] =
          (categoryCounts[product.categoryId] ?? 0) + 1;
    }
    final categoryEntries = categoryCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topCategoryTotal = categoryEntries.fold<int>(
      0,
      (sum, entry) => sum + entry.value,
    );
    final topCategorySegments = categoryEntries.take(4).map((entry) {
      final share = topCategoryTotal == 0
          ? 0.0
          : entry.value / topCategoryTotal;
      return _ChartSegment(
        label: _resolveCategoryLabel(entry.key, categories),
        count: entry.value,
        color: const Color(0xFFFF8A00),
        share: share,
      );
    }).toList();

    final branchOrderCounts = <String, int>{};
    for (final branch in branches) {
      branchOrderCounts[branch.id] = 0;
    }
    for (final order in orders) {
      branchOrderCounts[order.branchId] =
          (branchOrderCounts[order.branchId] ?? 0) + 1;
    }
    final trafficEntries = branchOrderCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final trafficTotal = trafficEntries.fold<int>(
      0,
      (sum, entry) => sum + entry.value,
    );
    final trafficSegments = trafficEntries
        .where((entry) => entry.value > 0)
        .take(4)
        .map((entry) {
          return _ChartSegment(
            label: _branchNameForId(entry.key, branches),
            count: entry.value,
            color: const Color(0xFF5E56E7),
            share: trafficTotal == 0 ? 0.0 : entry.value / trafficTotal,
          );
        })
        .toList();

    final today = DateTime.now();
    final revenueTrend = List<double>.generate(7, (index) {
      final targetDay = DateTime(
        today.year,
        today.month,
        today.day,
      ).subtract(Duration(days: 6 - index));
      return orders
          .where((order) {
            final orderDay = DateTime(
              order.createdAt.year,
              order.createdAt.month,
              order.createdAt.day,
            );
            return orderDay == targetDay;
          })
          .fold<double>(0, (sum, order) => sum + order.total);
    });

    return _AdminAnalytics(
      totalRevenue: totalRevenue,
      averageOrderValue: averageOrderValue.toDouble(),
      totalOrders: orders.length,
      verifiedPaymentCount: verifiedPaymentCount,
      revenueTrend: revenueTrend,
      statusSegments: statusSegments.isEmpty
          ? const [
              _ChartSegment(
                label: 'No data',
                count: 1,
                color: Color(0xFFE5E7EB),
                share: 1,
              ),
            ]
          : statusSegments,
      topCategorySegments: topCategorySegments.isEmpty
          ? const [
              _ChartSegment(
                label: 'No products',
                count: 1,
                color: Color(0xFFE5E7EB),
                share: 1,
              ),
            ]
          : topCategorySegments,
      topCategoryTotal: topCategoryTotal,
      trafficSegments: trafficSegments,
    );
  }
}

String _percentLabel(double share) {
  return '${(share * 100).toStringAsFixed(0)}%';
}

String _resolveCategoryLabel(String categoryId, List<Category> categories) {
  for (final category in categories) {
    if (category.id == categoryId) {
      return category.name;
    }
  }
  return categoryId;
}

String _branchNameForId(String branchId, List<Branch> branches) {
  for (final branch in branches) {
    if (branch.id == branchId) {
      return branch.name;
    }
  }
  return branchId;
}

class _LineChartPainter extends CustomPainter {
  const _LineChartPainter({
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
  bool shouldRepaint(covariant _LineChartPainter oldDelegate) {
    return oldDelegate.points != points ||
        oldDelegate.lineColor != lineColor ||
        oldDelegate.fillColor != fillColor;
  }
}

class _DonutChartPainter extends CustomPainter {
  const _DonutChartPainter({required this.segments});

  final List<_ChartSegment> segments;

  @override
  void paint(Canvas canvas, Size size) {
    final total = segments.fold<int>(0, (sum, segment) => sum + segment.count);
    final rect = Rect.fromCircle(
      center: Offset(size.width / 2, size.height / 2),
      radius: size.shortestSide / 2 - 10,
    );
    final strokeWidth = 18.0;

    final basePaint = Paint()
      ..color = const Color(0xFFE9ECF3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawArc(rect, 0, 6.283185307179586, false, basePaint);

    if (total == 0) {
      return;
    }

    var startAngle = -1.5707963267948966;
    for (final segment in segments) {
      final sweep = (segment.count / total) * 6.283185307179586;
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
  bool shouldRepaint(covariant _DonutChartPainter oldDelegate) {
    return oldDelegate.segments != segments;
  }
}

class _DashboardActionIcon extends StatelessWidget {
  const _DashboardActionIcon({
    required this.icon,
    required this.tooltip,
    required this.badgeCount,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final int badgeCount;
  final VoidCallback? onPressed;

  String get _badgeText {
    // Keep badge compact for very large counts.
    if (badgeCount > 99) {
      return '99+';
    }
    return '$badgeCount';
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          Icon(icon),
          if (badgeCount > 0)
            Positioned(
              right: -10,
              top: -8,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                decoration: BoxDecoration(
                  color: const Color(0xFFDC2626),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  _badgeText,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    height: 1.1,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _AdminDashboardBody extends StatelessWidget {
  const _AdminDashboardBody({
    required this.dashboardTitle,
    required this.roleSections,
    required this.showBranchesSection,
    required this.branches,
    required this.orders,
    required this.products,
    required this.adminCategories,
    required this.adminPaymentOptions,
    required this.adminAccounts,
    required this.onAddProduct,
    required this.onOpenOrdersPage,
    required this.onOpenInventoryPage,
    required this.onOpenBranchesPage,
    required this.onOpenCategoriesPage,
    required this.onOpenAdminRequestsPage,
    required this.onOpenPaymentOptionsPage,
    required this.onCreateAdminAccount,
    required this.onUpdateBranch,
    required this.onFetchBranch,
    required this.onDeleteBranch,
    required this.onAddCategory,
    required this.onToggleCategory,
    required this.onFetchCategory,
    required this.onUpdateCategory,
    required this.onDeleteCategory,
    required this.onAddPaymentOption,
    required this.onTogglePaymentOption,
    required this.onFetchPaymentOption,
    required this.onUpdatePaymentOption,
    required this.onDeletePaymentOption,
  });

  final String dashboardTitle;
  final List<String> roleSections;
  final bool showBranchesSection;
  final List<Branch> branches;
  final List<Order> orders;
  final List<Product> products;
  final List<Category> adminCategories;
  final List<PaymentOption> adminPaymentOptions;
  final List<AdminAccount> adminAccounts;
  final VoidCallback onAddProduct;
  final VoidCallback? onOpenOrdersPage;
  final VoidCallback? onOpenInventoryPage;
  final VoidCallback? onOpenBranchesPage;
  final VoidCallback? onOpenCategoriesPage;
  final VoidCallback? onOpenAdminRequestsPage;
  final VoidCallback? onOpenPaymentOptionsPage;
  final Future<void> Function({
    required String name,
    required String email,
    required String password,
  })?
  onCreateAdminAccount;
  final Future<void> Function({
    required String branchId,
    required String name,
    required String location,
    required String phoneNumber,
    required bool isActive,
  })?
  onUpdateBranch;
  final Future<Branch?> Function(String branchId)? onFetchBranch;
  final Future<void> Function(String branchId)? onDeleteBranch;
  final Future<void> Function({
    required String name,
    required String description,
    required String imageUrl,
  })?
  onAddCategory;
  final Future<void> Function(String categoryId, bool isActive)?
  onToggleCategory;
  final Future<Category?> Function(String categoryId)? onFetchCategory;
  final Future<void> Function({
    required String categoryId,
    required String name,
    required String description,
    required String imageUrl,
  })?
  onUpdateCategory;
  final Future<void> Function(String categoryId)? onDeleteCategory;
  final Future<void> Function({required String label, String? iconUrl})?
  onAddPaymentOption;
  final Future<void> Function(String optionId, bool isEnabled)?
  onTogglePaymentOption;
  final Future<PaymentOption?> Function(String optionId)? onFetchPaymentOption;
  final Future<void> Function({
    required String optionId,
    required String label,
    String? iconUrl,
  })?
  onUpdatePaymentOption;
  final Future<void> Function(String optionId)? onDeletePaymentOption;

  @override
  Widget build(BuildContext context) {
    final pendingRequests = adminAccounts
        .where((admin) => admin.role == AppUserRole.admin && !admin.approved)
        .toList();
    final activeAdmins = adminAccounts
        .where((admin) => admin.role == AppUserRole.admin && admin.approved)
        .toList();
    final superAdmins = adminAccounts
        .where((admin) => admin.role == AppUserRole.superAdmin)
        .toList();
    final analytics = _AdminAnalytics.fromData(
      orders: orders,
      products: products,
      branches: branches,
      categories: adminCategories,
    );

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFF3EBDD), Color(0xFFF8F6F1)],
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Cap width for readability on large displays.
          final maxWidth = constraints.maxWidth > 1280
              ? 1280.0
              : constraints.maxWidth;
          // Switch between side-by-side and stacked layouts.
          final isWide = constraints.maxWidth >= 1000;

          return Center(
            child: SizedBox(
              width: maxWidth,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 20),
                children: [
                  _HeroCard(
                    dashboardTitle: dashboardTitle,
                    branchCount: branches.length,
                    orderCount: orders.length,
                    productCount: products.length,
                    categoryCount: adminCategories.length,
                    paymentCount: adminPaymentOptions.length,
                    pendingAdminCount: pendingRequests.length,
                    activeAdminCount: activeAdmins.length,
                    sectionTags: roleSections,
                  ),
                  const SizedBox(height: 14),
                  _AnalyticsBoard(
                    analytics: analytics,
                    branchCount: branches.length,
                    productCount: products.length,
                    categoryCount: adminCategories.length,
                    paymentCount: adminPaymentOptions.length,
                    pendingAdminCount: pendingRequests.length,
                    activeAdminCount: activeAdmins.length,
                  ),
                  const SizedBox(height: 14),
                  if (isWide)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _AdminQuickRail(
                          onAddProduct: onAddProduct,
                          onOpenInventoryPage: onOpenInventoryPage,
                          onOpenOrdersPage: onOpenOrdersPage,
                          onOpenAdminRequestsPage: onOpenAdminRequestsPage,
                          branchCount: branches.length,
                          pendingAdminCount: pendingRequests.length,
                          orderCount: orders.length,
                          productCount: products.length,
                          sections: roleSections,
                          canManageAdmins: onCreateAdminAccount != null,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: _AdminSectionsColumn(
                            showBranchesSection: showBranchesSection,
                            branches: branches,
                            orders: orders,
                            products: products,
                            adminCategories: adminCategories,
                            adminPaymentOptions: adminPaymentOptions,
                            activeAdmins: activeAdmins,
                            superAdmins: superAdmins,
                            pendingRequests: pendingRequests,
                            onOpenBranchesPage: onOpenBranchesPage,
                            onOpenCategoriesPage: onOpenCategoriesPage,
                            onOpenAdminRequestsPage: onOpenAdminRequestsPage,
                            onOpenPaymentOptionsPage: onOpenPaymentOptionsPage,
                            onOpenOrdersPage: onOpenOrdersPage,
                            onOpenInventoryPage: onOpenInventoryPage,
                          ),
                        ),
                      ],
                    )
                  else
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _AdminQuickRail(
                          onAddProduct: onAddProduct,
                          onOpenInventoryPage: onOpenInventoryPage,
                          onOpenOrdersPage: onOpenOrdersPage,
                          onOpenAdminRequestsPage: onOpenAdminRequestsPage,
                          branchCount: branches.length,
                          pendingAdminCount: pendingRequests.length,
                          orderCount: orders.length,
                          productCount: products.length,
                          sections: roleSections,
                          canManageAdmins: onCreateAdminAccount != null,
                        ),
                        const SizedBox(height: 14),
                        _AdminSectionsColumn(
                          showBranchesSection: showBranchesSection,
                          branches: branches,
                          orders: orders,
                          products: products,
                          adminCategories: adminCategories,
                          adminPaymentOptions: adminPaymentOptions,
                          activeAdmins: activeAdmins,
                          superAdmins: superAdmins,
                          pendingRequests: pendingRequests,
                          onOpenBranchesPage: onOpenBranchesPage,
                          onOpenCategoriesPage: onOpenCategoriesPage,
                          onOpenAdminRequestsPage: onOpenAdminRequestsPage,
                          onOpenPaymentOptionsPage: onOpenPaymentOptionsPage,
                          onOpenOrdersPage: onOpenOrdersPage,
                          onOpenInventoryPage: onOpenInventoryPage,
                        ),
                      ],
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _AdminQuickRail extends StatelessWidget {
  const _AdminQuickRail({
    required this.onAddProduct,
    required this.onOpenInventoryPage,
    required this.onOpenOrdersPage,
    required this.onOpenAdminRequestsPage,
    required this.branchCount,
    required this.pendingAdminCount,
    required this.orderCount,
    required this.productCount,
    required this.sections,
    required this.canManageAdmins,
  });

  final VoidCallback onAddProduct;
  final VoidCallback? onOpenInventoryPage;
  final VoidCallback? onOpenOrdersPage;
  final VoidCallback? onOpenAdminRequestsPage;
  final int branchCount;
  final int pendingAdminCount;
  final int orderCount;
  final int productCount;
  final List<String> sections;
  final bool canManageAdmins;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 300,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _DataCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Quick actions',
                  style: TextStyle(color: Color(0xFF7B8091), fontSize: 12),
                ),
                const SizedBox(height: 10),
                _SideActionButton(
                  icon: Icons.add_box_outlined,
                  label: 'Add product',
                  onPressed: onAddProduct,
                ),
                const SizedBox(height: 10),
                _SideActionButton(
                  icon: Icons.receipt_long_outlined,
                  label: 'Open orders',
                  onPressed: onOpenOrdersPage,
                ),
                const SizedBox(height: 10),
                _SideActionButton(
                  icon: Icons.inventory_2_outlined,
                  label: 'Open inventory',
                  onPressed: onOpenInventoryPage,
                ),
                const SizedBox(height: 10),
                _SideActionButton(
                  icon: Icons.manage_accounts_outlined,
                  label: 'Open admin requests',
                  onPressed: onOpenAdminRequestsPage,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _DataCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'At a glance',
                  style: TextStyle(color: Color(0xFF7B8091), fontSize: 12),
                ),
                const SizedBox(height: 12),
                _MiniMetric(label: 'Branches', value: '$branchCount'),
                _MiniMetric(
                  label: 'Pending admins',
                  value: '$pendingAdminCount',
                ),
                _MiniMetric(label: 'Orders', value: '$orderCount'),
                _MiniMetric(label: 'Products', value: '$productCount'),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _DataCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Sections',
                  style: TextStyle(color: Color(0xFF7B8091), fontSize: 12),
                ),
                const SizedBox(height: 10),
                for (final section in sections)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8F9FE),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        section,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (canManageAdmins) ...[
            const SizedBox(height: 12),
            _DataCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Admin access',
                    style: TextStyle(color: Color(0xFF7B8091), fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$pendingAdminCount pending',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text('$pendingAdminCount request(s) waiting for review'),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _AdminSectionsColumn extends StatelessWidget {
  const _AdminSectionsColumn({
    required this.showBranchesSection,
    required this.branches,
    required this.orders,
    required this.products,
    required this.adminCategories,
    required this.adminPaymentOptions,
    required this.activeAdmins,
    required this.superAdmins,
    required this.pendingRequests,
    required this.onOpenBranchesPage,
    required this.onOpenCategoriesPage,
    required this.onOpenAdminRequestsPage,
    required this.onOpenPaymentOptionsPage,
    required this.onOpenOrdersPage,
    required this.onOpenInventoryPage,
  });

  final bool showBranchesSection;
  final List<Branch> branches;
  final List<Order> orders;
  final List<Product> products;
  final List<Category> adminCategories;
  final List<PaymentOption> adminPaymentOptions;
  final List<AdminAccount> activeAdmins;
  final List<AdminAccount> superAdmins;
  final List<AdminAccount> pendingRequests;
  final VoidCallback? onOpenBranchesPage;
  final VoidCallback? onOpenCategoriesPage;
  final VoidCallback? onOpenAdminRequestsPage;
  final VoidCallback? onOpenPaymentOptionsPage;
  final VoidCallback? onOpenOrdersPage;
  final VoidCallback? onOpenInventoryPage;

  @override
  Widget build(BuildContext context) {
    final pendingPayments = orders
        .where((order) => order.payment.status == PaymentStatus.pending)
        .length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showBranchesSection) ...[
          _DashboardSectionCard(
            title: 'Branches',
            onOpenPage: onOpenBranchesPage,
            summary: branches.isEmpty
                ? 'No branches found.'
                : '${branches.length} branch(s) available',
            actionLabel: 'Open Branches Page',
            actionIcon: Icons.storefront_outlined,
          ),
          const SizedBox(height: 14),
        ],
        _DashboardSectionCard(
          title: 'Admin Requests',
          onOpenPage: onOpenAdminRequestsPage,
          summary: pendingRequests.isEmpty
              ? 'No pending admin requests.'
              : '${pendingRequests.length} pending admin request(s) need review.',
          actionLabel: 'Open Admin Requests',
          actionIcon: Icons.manage_accounts_outlined,
        ),
        const SizedBox(height: 14),
        _DashboardSectionCard(
          title: 'Categories',
          onOpenPage: onOpenCategoriesPage,
          summary: adminCategories.isEmpty
              ? 'No categories found.'
              : '${adminCategories.length} category(s) available',
          actionLabel: 'Open Categories Page',
          actionIcon: Icons.category_outlined,
        ),
        const SizedBox(height: 14),
        _DashboardSectionCard(
          title: 'Payment Options',
          onOpenPage: onOpenPaymentOptionsPage,
          summary: adminPaymentOptions.isEmpty
              ? 'No payment options found.'
              : '${adminPaymentOptions.where((item) => item.isEnabled).length} enabled payment option(s).',
          actionLabel: 'Open Payment Options',
          actionIcon: Icons.payments_outlined,
        ),
        const SizedBox(height: 14),
        _DashboardSectionCard(
          title: 'Orders',
          onOpenPage: onOpenOrdersPage,
          summary:
              '${orders.where((order) => order.status == OrderStatus.pending).length} pending order(s), '
              '$pendingPayments pending payment(s) for admin approval.',
          actionLabel: 'Open Orders Page',
          actionIcon: Icons.receipt_long_outlined,
          entryBadgeCount: pendingPayments,
        ),
        const SizedBox(height: 14),
        _DashboardSectionCard(
          title: 'Inventory',
          onOpenPage: onOpenInventoryPage,
          summary: products.isEmpty
              ? 'No products loaded yet.'
              : '${products.length} product(s) available.',
          actionLabel: 'Open Inventory Page',
          actionIcon: Icons.inventory_2_outlined,
        ),
        if (activeAdmins.isNotEmpty || superAdmins.isNotEmpty) ...[
          const SizedBox(height: 14),
          _DashboardSectionCard(
            title: 'Admin Accounts',
            onOpenPage: onOpenAdminRequestsPage,

            summary:
                '${activeAdmins.length + superAdmins.length} active admin account(s).',
            actionLabel: 'Open Admin Requests Page',
            actionIcon: Icons.manage_accounts_outlined,
          ),
        ],
      ],
    );
  }
}

class _DashboardSectionCard extends StatelessWidget {
  const _DashboardSectionCard({
    required this.title,
    required this.summary,
    this.onOpenPage,
    this.actionLabel,
    this.actionIcon,
    this.entryBadgeCount = 0,
  });

  final String title;
  final String summary;
  final VoidCallback? onOpenPage;
  final String? actionLabel;
  final IconData? actionIcon;
  final int entryBadgeCount;

  String get _badgeText {
    // Keep badge compact for very large counts.
    if (entryBadgeCount > 99) {
      return '99+';
    }
    return '$entryBadgeCount';
  }

  Widget _buildIconWithBadge(IconData icon) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(icon),
        if (entryBadgeCount > 0)
          Positioned(
            right: -10,
            top: -8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
              constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
              decoration: BoxDecoration(
                color: const Color(0xFFDC2626),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Text(
                _badgeText,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  height: 1.1,
                ),
              ),
            ),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return _DataCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Text(summary, style: const TextStyle(color: Color(0xFF6B7280))),
          if (onOpenPage != null && actionLabel != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                FilledButton.icon(
                  onPressed: onOpenPage,
                  icon: _buildIconWithBadge(
                    actionIcon ?? Icons.open_in_new_rounded,
                  ),
                  label: Text(actionLabel!),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
