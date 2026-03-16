/// Test coverage for category_repository_test behaviors.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../support/mocks.dart';
import '../../../../support/test_data.dart';

void main() {
  late MockCategoryRepository repository;

  setUpAll(registerTestFallbackValues);

  setUp(() {
    repository = MockCategoryRepository();
  });

  group('CategoryRepository contract', () {
    test('loads categories for storefront browsing', () async {
      when(() => repository.getCategories()).thenAnswer((_) async => testCategories);

      final result = await repository.getCategories();

      expect(result, testCategories);
      verify(() => repository.getCategories()).called(1);
    });

    test('creates and updates categories for admin management', () async {
      final category = buildCategory(id: 'cat-bakery', name: 'Bakery');
      final updated = category.copyWith(description: 'Fresh bread and pastries');

      when(() => repository.createCategory(category)).thenAnswer((_) async => category);
      when(() => repository.updateCategory(updated)).thenAnswer((_) async => updated);

      expect(await repository.createCategory(category), category);
      expect(await repository.updateCategory(updated), updated);
    });

    test('deletes categories that are no longer active', () async {
      when(() => repository.deleteCategory('cat-household')).thenAnswer((_) async {});

      await repository.deleteCategory('cat-household');

      verify(() => repository.deleteCategory('cat-household')).called(1);
    });
  });
}
