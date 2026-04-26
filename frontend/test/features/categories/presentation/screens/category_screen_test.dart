/// Test coverage for category_screen_test behaviors.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:e_commerce_app_with_django/features/categories/presentation/screens/category_screen.dart';

import '../../../../support/pump_app.dart';
import '../../../../support/test_data.dart';

void main() {
  group('CategoryScreen', () {
    testWidgets('renders all categories and highlights the selected one', (
      tester,
    ) async {
      String? selectedCategoryId;

      await pumpTestApp(
        tester,
        child: CategoryScreen(
          categories: testCategories,
          selectedCategoryId: 'cat-beverages',
          onCategorySelected: (categoryId) => selectedCategoryId = categoryId,
        ),
      );

      expect(find.text('Beverages'), findsOneWidget);
      expect(find.text('Groceries'), findsOneWidget);
      expect(find.byKey(const Key('category.item.cat-beverages')), findsOneWidget);

      await tester.tap(find.byKey(const Key('category.item.cat-groceries')));
      await tester.pump();

      expect(selectedCategoryId, 'cat-groceries');
    });
  });
}
