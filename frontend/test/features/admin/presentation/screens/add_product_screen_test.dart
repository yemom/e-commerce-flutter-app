/// Test coverage for add_product_screen_test behaviors.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:e_commerce_app_with_django/features/admin/presentation/screens/add_product_screen.dart';
import 'package:e_commerce_app_with_django/features/products/domain/models/product.dart';

import '../../../../support/pump_app.dart';
import '../../../../support/test_data.dart';

void main() {
  group('AddProductScreen', () {
    testWidgets('shows camera and gallery options when choosing an image', (tester) async {
      await pumpTestApp(
        tester,
        child: AddProductScreen(
          categories: testCategories,
          branches: testBranches,
          onUploadImage: ({required bytes, required fileName}) async => 'https://example.com/$fileName',
          onSubmit: (_) async {},
        ),
      );

      await tester.scrollUntilVisible(
        find.byKey(const Key('add-product.pick-image-button')),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      expect(find.byKey(const Key('add-product.pick-image-button')), findsOneWidget);
      expect(find.text('Select from device'), findsOneWidget);
    });

    testWidgets('validates required fields before submission', (tester) async {
      Product? submittedProduct;

      await pumpTestApp(
        tester,
        child: AddProductScreen(
          categories: testCategories,
          branches: testBranches,
          onUploadImage: ({required bytes, required fileName}) async => 'https://example.com/$fileName',
          onSubmit: (product) async {
            submittedProduct = product;
          },
        ),
      );

      await tester.scrollUntilVisible(
        find.byKey(const Key('add-product.submit-button')),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('add-product.submit-button')));
      await tester.pumpAndSettle();

      expect(find.text('Please enter a product name.'), findsOneWidget);
      expect(find.text('Please enter a product price.'), findsOneWidget);
      expect(find.text('Please select at least one branch.'), findsOneWidget);
      expect(submittedProduct, isNull);
    });

    testWidgets('submits a product with selected category and branches', (
      tester,
    ) async {
      Product? submittedProduct;

      await pumpTestApp(
        tester,
        child: AddProductScreen(
          categories: testCategories,
          branches: testBranches,
          onUploadImage: ({required bytes, required fileName}) async => 'https://example.com/$fileName',
          onSubmit: (product) async {
            submittedProduct = product;
          },
        ),
      );

      await tester.enterText(
        find.byKey(const Key('add-product.name-field')),
        'Organic Honey',
      );
      await tester.enterText(
        find.byKey(const Key('add-product.description-field')),
        'Raw forest honey',
      );
      await tester.enterText(
        find.byKey(const Key('add-product.price-field')),
        '410',
      );

      await tester.scrollUntilVisible(
        find.byKey(const Key('add-product.category-field')),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('add-product.category-field')));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Groceries').last);
      await tester.pumpAndSettle();

      await tester.scrollUntilVisible(
        find.byKey(const Key('add-product.branch.branch-addis-bole')),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('add-product.branch.branch-addis-bole')));
      await tester.pump();
      await tester.scrollUntilVisible(
        find.byKey(const Key('add-product.branch.branch-hawassa-tabor')),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('add-product.branch.branch-hawassa-tabor')));
      await tester.pump();

      await tester.scrollUntilVisible(
        find.byKey(const Key('add-product.submit-button')),
        300,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('add-product.submit-button')));
      await tester.pumpAndSettle();

      expect(submittedProduct?.name, 'Organic Honey');
      expect(submittedProduct?.categoryId, 'cat-groceries');
      expect(submittedProduct?.branchIds, containsAll(['branch-addis-bole', 'branch-hawassa-tabor']));
      expect(submittedProduct?.price, 410);
    });
  });
}
