/// Verifies the small dashboard widgets that are easy to regress during refactors.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:e_commerce_app_with_django/features/admin/presentation/widgets/dashboard/dashboard.dart';

import '../../../../../support/pump_app.dart';
import '../../../../../support/test_data.dart';

Widget _dashboardTestSurface() {
  return Scaffold(
    body: AdminDashboardBody(
      dashboardTitle: 'Admin dashboard',
      roleSections: const ['Products', 'Orders'],
      showBranchesSection: true,
      branches: testBranches,
      orders: testOrders,
      products: testProducts,
      adminCategories: testCategories,
      adminPaymentOptions: testPaymentOptions,
      adminAccounts: const [],
      onAddProduct: () {},
      onOpenOrdersPage: () {},
      onOpenInventoryPage: () {},
      onOpenBranchesPage: () {},
      onOpenCategoriesPage: () {},
      onOpenAdminRequestsPage: () {},
      onOpenPaymentOptionsPage: () {},
      canManageAdmins: false,
    ),
  );
}

void main() {
  test('formats large badge counts compactly', () {
    expect(formatDashboardBadgeCount(3), '3');
    expect(formatDashboardBadgeCount(120), '99+');
  });

  testWidgets('uses the split layout on wide screens', (tester) async {
    tester.view.physicalSize = const Size(1400, 3200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await pumpTestApp(
      tester,
      child: _dashboardTestSurface(),
    );

    // The responsive section is lower in the list; force it into the built viewport.
    await tester.drag(find.byType(ListView).first, const Offset(0, -1200));
    await tester.pumpAndSettle();

    expect(
      find.byType(AdminDashboardWideBodyLayout),
      findsOneWidget,
    );
    expect(
      find.byType(AdminDashboardStackedBodyLayout),
      findsNothing,
    );
  });

  testWidgets('uses the stacked layout on narrow screens', (tester) async {
    tester.view.physicalSize = const Size(700, 3200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await pumpTestApp(
      tester,
      child: _dashboardTestSurface(),
    );

    // The responsive section is lower in the list; force it into the built viewport.
    await tester.drag(find.byType(ListView).first, const Offset(0, -1200));
    await tester.pumpAndSettle();

    expect(
      find.byType(AdminDashboardStackedBodyLayout),
      findsOneWidget,
    );
    expect(
      find.byType(AdminDashboardWideBodyLayout),
      findsNothing,
    );
  });
}
