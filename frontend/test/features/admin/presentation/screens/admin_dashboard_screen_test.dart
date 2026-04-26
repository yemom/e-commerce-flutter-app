/// Test coverage for admin_dashboard_screen_test behaviors.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:e_commerce_app_with_django/features/admin/presentation/screens/admin_dashboard_screen.dart';

import '../../../../support/pump_app.dart';
import '../../../../support/test_data.dart';

void main() {
  group('AdminDashboardScreen', () {
    testWidgets('shows categories management section', (tester) async {
      await pumpTestApp(
        tester,
        child: AdminDashboardScreen(
          branches: testBranches,
          orders: testOrders,
          onAddProduct: () {},
          onLogout: () async {},
          onVerifyPayment: (_) {},
          onMarkOrderShipped: (_) {},
          onMarkOrderDelivered: (_) {},
          adminCategories: testCategories,
          onAddCategory: ({required name, required description, required imageUrl}) async {},
        ),
      );

      expect(find.text('Categories'), findsWidgets);
      expect(find.text('Admin dashboard'), findsWidgets);
    });

    testWidgets('shows branch coverage, orders, and admin actions', (
      tester,
    ) async {
      await pumpTestApp(
        tester,
        child: AdminDashboardScreen(
          branches: testBranches,
          orders: testOrders,
          onAddProduct: () {},
          onLogout: () async {},
          onVerifyPayment: (_) {},
          onMarkOrderShipped: (_) {},
          onMarkOrderDelivered: (_) {},
        ),
      );

      expect(find.text('Addis Bole'), findsOneWidget);
      expect(find.byTooltip('Add product'), findsOneWidget);

      final ordersSection = find.text('Orders').last;
      await tester.scrollUntilVisible(ordersSection, 260, scrollable: find.byType(Scrollable).first);
      expect(find.text('Orders'), findsWidgets);
    });
  });
}
