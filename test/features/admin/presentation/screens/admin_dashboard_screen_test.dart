/// Test coverage for admin_dashboard_screen_test behaviors.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:e_commerce_app_with_django/features/admin/presentation/screens/admin_dashboard_screen.dart';

import '../../../../support/pump_app.dart';
import '../../../../support/test_data.dart';

void main() {
  group('AdminDashboardScreen', () {
    testWidgets('shows category image chooser in add category dialog', (tester) async {
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

      await tester.scrollUntilVisible(
        find.text('Add Category'),
        260,
        scrollable: find.descendant(
          of: find.byKey(const Key('admin.dashboard-scroll')),
          matching: find.byType(Scrollable),
        ).first,
      );
      await tester.tap(find.text('Add Category'));
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('admin.category.pick-image-button')), findsOneWidget);
      expect(find.text('Choose image (camera or gallery)'), findsOneWidget);
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
      expect(
        find.byKey(const Key('admin.branch-card.branch-addis-bole')),
        findsOneWidget,
      );
      expect(find.byKey(const Key('admin.add-product-button')), findsOneWidget);

      final ordersSection = find.text('Orders').last;
      await tester.scrollUntilVisible(
        ordersSection,
        260,
        scrollable: find.descendant(
          of: find.byKey(const Key('admin.dashboard-scroll')),
          matching: find.byType(Scrollable),
        ).first,
      );
      expect(find.text('Orders'), findsWidgets);
    });
  });
}
