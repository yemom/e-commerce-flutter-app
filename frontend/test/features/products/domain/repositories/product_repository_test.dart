/// Test coverage for product_repository_test behaviors.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../support/mocks.dart';
import '../../../../support/test_data.dart';

void main() {
  late MockProductRepository repository;

  setUpAll(registerTestFallbackValues);

  setUp(() {
    repository = MockProductRepository();
  });

  group('ProductRepository contract', () {
    test('fetches products by branch, category, and search query', () async {
      when(
        () => repository.getProducts(
          branchId: 'branch-addis-bole',
          categoryId: 'cat-beverages',
          query: 'coffee',
        ),
      ).thenAnswer((_) async => [testProducts.first]);

      final result = await repository.getProducts(
        branchId: 'branch-addis-bole',
        categoryId: 'cat-beverages',
        query: 'coffee',
      );

      expect(result, [testProducts.first]);
      verify(
        () => repository.getProducts(
          branchId: 'branch-addis-bole',
          categoryId: 'cat-beverages',
          query: 'coffee',
        ),
      ).called(1);
    });

    test('creates and updates products for the admin flow', () async {
      final draft = buildProduct(id: 'prod-new-1', name: 'Organic Honey');
      final updated = draft.copyWith(price: 410);

      when(() => repository.addProduct(draft)).thenAnswer((_) async => draft);
      when(() => repository.updateProduct(updated)).thenAnswer((_) async => updated);

      expect(await repository.addProduct(draft), draft);
      expect(await repository.updateProduct(updated), updated);
    });

    test('deletes and assigns products to branches with inventory', () async {
      when(() => repository.deleteProduct('prod-coffee-1')).thenAnswer((_) async {});
      when(
        () => repository.assignProductToBranch(
          productId: 'prod-coffee-1',
          branchId: 'branch-hawassa-tabor',
          quantity: 15,
        ),
      ).thenAnswer((_) async {});

      await repository.deleteProduct('prod-coffee-1');
      await repository.assignProductToBranch(
        productId: 'prod-coffee-1',
        branchId: 'branch-hawassa-tabor',
        quantity: 15,
      );

      verify(() => repository.deleteProduct('prod-coffee-1')).called(1);
      verify(
        () => repository.assignProductToBranch(
          productId: 'prod-coffee-1',
          branchId: 'branch-hawassa-tabor',
          quantity: 15,
        ),
      ).called(1);
    });
  });
}
