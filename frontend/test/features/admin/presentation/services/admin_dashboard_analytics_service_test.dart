/// Verifies the dashboard analytics service turns raw data into stable summaries.
library;

import 'package:flutter_test/flutter_test.dart';

import 'package:e_commerce_app_with_django/features/admin/presentation/widgets/dashboard/dashboard.dart';
import 'package:e_commerce_app_with_django/features/auth/domain/models/user_role.dart';
import 'package:e_commerce_app_with_django/features/orders/domain/models/order.dart';
import 'package:e_commerce_app_with_django/features/payment/domain/models/payment.dart';

import '../../../../support/test_data.dart';

void main() {
  test('builds analytics summaries from dashboard data', () {
    final orders = [
      buildOrder(
        id: 'order-1',
        branchId: testBranches[0].id,
        status: OrderStatus.pending,
        payment: buildPayment(
          id: 'pay-1',
          orderId: 'order-1',
          status: PaymentStatus.verified,
          method: PaymentMethod.telebirr,
          amount: 490,
        ),
      ),
      buildOrder(
        id: 'order-2',
        branchId: testBranches[1].id,
        status: OrderStatus.shipped,
        payment: buildPayment(
          id: 'pay-2',
          orderId: 'order-2',
          status: PaymentStatus.pending,
          method: PaymentMethod.cbe,
          amount: 490,
        ),
      ),
      buildOrder(
        id: 'order-3',
        branchId: testBranches[0].id,
        status: OrderStatus.delivered,
        payment: buildPayment(
          id: 'pay-3',
          orderId: 'order-3',
          status: PaymentStatus.verified,
          method: PaymentMethod.telebirr,
          amount: 490,
        ),
      ),
    ];

    final analytics = const AdminDashboardAnalyticsService().build(
      orders: orders,
      products: [
        buildProduct(id: 'prod-1', categoryId: testCategories[0].id),
        buildProduct(id: 'prod-2', categoryId: testCategories[0].id),
        buildProduct(id: 'prod-3', categoryId: testCategories[1].id),
      ],
      branches: testBranches.take(2).toList(growable: false),
      categories: testCategories,
    );

    expect(analytics.totalOrders, 3);
    expect(analytics.verifiedPaymentCount, 2);
    expect(analytics.topCategoryTotal, 3);
    expect(analytics.topCategorySegments, isNotEmpty);
    expect(analytics.trafficSegments, isNotEmpty);
    expect(analytics.revenueTrend.length, 7);
    expect(analytics.statusSegments, isNotEmpty);
  });

  test('exposes admin-role labels through the shared model surface', () {
    expect(AppUserRole.admin.name, equals('admin'));
  });
}
