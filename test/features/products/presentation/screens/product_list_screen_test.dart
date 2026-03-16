/// Test coverage for product_list_screen_test behaviors.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:e_commerce_app_with_django/features/products/presentation/screens/product_list_screen.dart';

import '../../../../support/pump_app.dart';
import '../../../../support/test_data.dart';

void main() {
  group('ProductListScreen', () {
    testWidgets('renders products, branch filter, and category filter', (
      tester,
    ) async {
      String? selectedBranchId;
      String? selectedCategoryId;
      String? searchQuery;

      await pumpTestApp(
        tester,
        child: ProductListScreen(
          products: testProducts,
          branches: testBranches,
          categories: testCategories,
          selectedBranchId: testBranches.first.id,
          selectedCategoryId: null,
          searchQuery: '',
          onSearchChanged: (value) => searchQuery = value,
          onBranchChanged: (value) => selectedBranchId = value,
          onCategoryChanged: (value) => selectedCategoryId = value,
          onSeeAll: () {},
          onLogout: () async {},
        ),
      );

      expect(find.text('Arabica Coffee'), findsOneWidget);
      expect(find.text('Black Tea'), findsOneWidget);
      expect(find.byKey(const Key('product-list.search-field')), findsNothing);
      await tester.tap(find.byKey(const Key('product-list.search-toggle')));
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('product-list.search-field')), findsOneWidget);
      expect(find.byKey(const Key('product-list.branch-filter')), findsOneWidget);
      expect(find.byKey(const Key('product-list.category.cat-beverages')), findsOneWidget);

      await tester.enterText(
        find.byKey(const Key('product-list.search-field')),
        'tea',
      );

      expect(searchQuery, 'tea');

      await tester.tap(find.byKey(const Key('product-list.category.cat-groceries')));
      await tester.pump();

      expect(selectedCategoryId, 'cat-groceries');

      await tester.tap(find.byKey(const Key('product-list.branch-filter')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Bahir Dar Piazza').last);
      await tester.pumpAndSettle();

      expect(selectedBranchId, 'branch-bahir-dar-piazza');
    });

    testWidgets('calls see all callback', (tester) async {
      var seeAllPressed = false;

      await pumpTestApp(
        tester,
        child: ProductListScreen(
          products: testProducts,
          branches: testBranches,
          categories: testCategories,
          selectedBranchId: testBranches.first.id,
          selectedCategoryId: null,
          searchQuery: '',
          onSearchChanged: (_) {},
          onBranchChanged: (_) {},
          onCategoryChanged: (_) {},
          onSeeAll: () => seeAllPressed = true,
          onLogout: () async {},
        ),
      );

      await tester.scrollUntilVisible(find.text('See All'), 250, scrollable: find.byType(Scrollable).last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('See All'));
      await tester.pump();

      expect(seeAllPressed, isTrue);
    });
  });
}
