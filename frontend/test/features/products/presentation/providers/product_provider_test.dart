/// Test coverage for product_provider_test behaviors.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:e_commerce_app_with_django/features/products/domain/models/product.dart';
import 'package:e_commerce_app_with_django/features/products/presentation/providers/product_provider.dart';

import '../../../../support/mocks.dart';
import '../../../../support/test_data.dart';

void main() {
  late MockProductRepository repository;
  late ProviderContainer container;

  setUpAll(registerTestFallbackValues);

  setUp(() {
    repository = MockProductRepository();
    container = ProviderContainer(
      overrides: [
        productRepositoryProvider.overrideWithValue(repository),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  group('productProvider', () {
    test('loads the catalog for a selected branch', () async {
      when(
        () => repository.getProducts(
          branchId: 'branch-addis-bole',
          categoryId: null,
          query: null,
        ),
      ).thenAnswer((_) async => testProducts.take(2).toList());

      await container.read(productProvider.notifier).loadProducts(
            branchId: 'branch-addis-bole',
          );

      final state = container.read(productProvider);

      expect(state.selectedBranchId, 'branch-addis-bole');
      expect(state.products, hasLength(2));
      expect(state.products.first.name, 'Arabica Coffee');
    });

    test('filters products by category within the active branch', () async {
      when(
        () => repository.getProducts(
          branchId: 'branch-addis-bole',
          categoryId: null,
          query: null,
        ),
      ).thenAnswer((_) async => testProducts.take(2).toList());
      when(
        () => repository.getProducts(
          branchId: 'branch-addis-bole',
          categoryId: 'cat-beverages',
          query: null,
        ),
      ).thenAnswer((_) async => [testProducts.first, testProducts[1]]);

      await container.read(productProvider.notifier).loadProducts(
            branchId: 'branch-addis-bole',
          );
      await container.read(productProvider.notifier).filterByCategory('cat-beverages');

      final state = container.read(productProvider);

      expect(state.selectedCategoryId, 'cat-beverages');
      expect(state.products, everyElement(predicate<Product>((product) => product.categoryId == 'cat-beverages')));
    });

    test('searches products using the active branch and category filters', () async {
      when(
        () => repository.getProducts(
          branchId: 'branch-addis-bole',
          categoryId: null,
          query: null,
        ),
      ).thenAnswer((_) async => testProducts.take(2).toList());
      when(
        () => repository.getProducts(
          branchId: 'branch-addis-bole',
          categoryId: null,
          query: 'tea',
        ),
      ).thenAnswer((_) async => [testProducts[1]]);

      await container.read(productProvider.notifier).loadProducts(
            branchId: 'branch-addis-bole',
          );
      await container.read(productProvider.notifier).searchProducts('tea');

      final state = container.read(productProvider);

      expect(state.searchQuery, 'tea');
      expect(state.products.single.name, 'Black Tea');
    });
  });
}
