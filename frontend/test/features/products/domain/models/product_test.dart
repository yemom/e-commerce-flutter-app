/// Test coverage for product_test behaviors.
library;

import 'package:flutter_test/flutter_test.dart';

import 'package:e_commerce_app_with_django/features/products/domain/models/product.dart';

import '../../../../support/test_data.dart';

void main() {
  group('Product', () {
    test('stores product details, category, and branch inventory', () {
      final product = buildProduct(
        branchIds: testBranches.map((branch) => branch.id).toList(),
        stockByBranch: {
          for (final branch in testBranches) branch.id: 10,
        },
      );

      expect(product.id, 'prod-coffee-1');
      expect(product.name, 'Arabica Coffee');
      expect(product.categoryId, 'cat-beverages');
      expect(product.branchIds, hasLength(5));
      expect(product.stockByBranch, containsPair('branch-addis-bole', 10));
      expect(product.isAvailable, isTrue);
    });

    test('supports value equality', () {
      final first = buildProduct();
      final second = buildProduct();

      expect(first, equals(second));
    });

    test('copyWith updates selected fields while preserving others', () {
      final original = buildProduct();

      final updated = original.copyWith(
        price: 245,
        branchIds: const ['branch-addis-bole', 'branch-hawassa-tabor'],
        stockByBranch: const {
          'branch-addis-bole': 7,
          'branch-hawassa-tabor': 11,
        },
      );

      expect(updated.price, 245);
      expect(updated.branchIds, contains('branch-hawassa-tabor'));
      expect(updated.stockByBranch['branch-hawassa-tabor'], 11);
      expect(updated.name, original.name);
      expect(updated.categoryId, original.categoryId);
    });

    test('serializes and deserializes without losing branch availability', () {
      final product = buildProduct(
        branchIds: const [
          'branch-addis-bole',
          'branch-adama-central',
          'branch-bahir-dar-piazza',
        ],
        stockByBranch: const {
          'branch-addis-bole': 3,
          'branch-adama-central': 4,
          'branch-bahir-dar-piazza': 6,
        },
      );

      final json = product.toJson();
      final recreated = Product.fromJson(json);

      expect(recreated, equals(product));
      expect(recreated.branchIds, hasLength(3));
      expect(recreated.stockByBranch['branch-adama-central'], 4);
    });

    test('preserves imageUrls during json round trip', () {
      final product = buildProduct(
        imageUrls: const [
          'https://example.com/products/coffee-1.png',
          'https://example.com/products/coffee-2.png',
        ],
      );

      final recreated = Product.fromJson(product.toJson());

      expect(recreated.imageUrls, hasLength(2));
      expect(recreated.imageUrls, equals(product.imageUrls));
    });
  });
}
