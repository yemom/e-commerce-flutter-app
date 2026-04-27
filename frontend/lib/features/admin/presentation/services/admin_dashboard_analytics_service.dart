import 'package:flutter/material.dart';

import 'package:e_commerce_app_with_django/features/admin/presentation/models/admin_chart_segment.dart';
import 'package:e_commerce_app_with_django/features/admin/presentation/models/admin_dashboard_analytics.dart';
import 'package:e_commerce_app_with_django/features/branches/domain/models/branch.dart';
import 'package:e_commerce_app_with_django/features/categories/domain/models/category.dart';
import 'package:e_commerce_app_with_django/features/orders/domain/models/order.dart';
import 'package:e_commerce_app_with_django/features/payment/domain/models/payment.dart';
import 'package:e_commerce_app_with_django/features/products/domain/models/product.dart';

class AdminDashboardAnalyticsService {
  const AdminDashboardAnalyticsService();

  AdminDashboardAnalytics build({
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

    final statusSegments = _buildStatusSegments(orders);
    final topCategorySegments = _buildTopCategorySegments(products, categories);
    final topCategoryTotal = topCategorySegments.fold<int>(
      0,
      (sum, segment) => sum + segment.count,
    );
    final trafficSegments = _buildTrafficSegments(orders, branches);

    return AdminDashboardAnalytics(
      totalRevenue: totalRevenue,
      averageOrderValue: averageOrderValue.toDouble(),
      totalOrders: orders.length,
      verifiedPaymentCount: verifiedPaymentCount,
      revenueTrend: _buildRevenueTrend(orders),
      statusSegments: statusSegments.isEmpty
          ? const [
              AdminChartSegment(
                label: 'No data',
                count: 1,
                color: Color(0xFFE5E7EB),
                share: 1,
              ),
            ]
          : statusSegments,
      topCategorySegments: topCategorySegments.isEmpty
          ? const [
              AdminChartSegment(
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

  List<AdminChartSegment> _buildStatusSegments(List<Order> orders) {
    final statusCounts = <OrderStatus, int>{
      for (final status in OrderStatus.values)
        status: orders.where((order) => order.status == status).length,
    };

    return [
      AdminChartSegment(
        label: 'Pending',
        count: statusCounts[OrderStatus.pending] ?? 0,
        color: const Color(0xFFFFC26B),
        share: 0,
      ),
      AdminChartSegment(
        label: 'Confirmed',
        count: statusCounts[OrderStatus.confirmed] ?? 0,
        color: const Color(0xFFFFA62B),
        share: 0,
      ),
      AdminChartSegment(
        label: 'Shipped',
        count: statusCounts[OrderStatus.shipped] ?? 0,
        color: const Color(0xFFEE7B15),
        share: 0,
      ),
      AdminChartSegment(
        label: 'Delivered',
        count: statusCounts[OrderStatus.delivered] ?? 0,
        color: const Color(0xFF5E56E7),
        share: 0,
      ),
    ].where((segment) => segment.count > 0).toList();
  }

  List<AdminChartSegment> _buildTopCategorySegments(
    List<Product> products,
    List<Category> categories,
  ) {
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

    return categoryEntries.take(4).map((entry) {
      final share = topCategoryTotal == 0 ? 0.0 : entry.value / topCategoryTotal;
      return AdminChartSegment(
        label: _resolveCategoryLabel(entry.key, categories),
        count: entry.value,
        color: const Color(0xFFFF8A00),
        share: share,
      );
    }).toList();
  }

  List<AdminChartSegment> _buildTrafficSegments(
    List<Order> orders,
    List<Branch> branches,
  ) {
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

    return trafficEntries
        .where((entry) => entry.value > 0)
        .take(4)
        .map(
          (entry) => AdminChartSegment(
            label: _resolveBranchLabel(entry.key, branches),
            count: entry.value,
            color: const Color(0xFF5E56E7),
            share: trafficTotal == 0 ? 0.0 : entry.value / trafficTotal,
          ),
        )
        .toList();
  }

  List<double> _buildRevenueTrend(List<Order> orders) {
    final today = DateTime.now();
    return List<double>.generate(7, (index) {
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
  }

  String _resolveCategoryLabel(String categoryId, List<Category> categories) {
    for (final category in categories) {
      if (category.id == categoryId) {
        return category.name;
      }
    }
    return categoryId;
  }

  String _resolveBranchLabel(String branchId, List<Branch> branches) {
    for (final branch in branches) {
      if (branch.id == branchId) {
        return branch.name;
      }
    }
    return branchId;
  }
}
