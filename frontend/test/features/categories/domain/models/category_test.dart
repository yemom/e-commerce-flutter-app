/// Test coverage for category_test behaviors.
library;

import 'package:flutter_test/flutter_test.dart';

import 'package:e_commerce_app_with_django/features/categories/domain/models/category.dart';

import '../../../../support/test_data.dart';

void main() {
  group('Category', () {
    test('stores descriptive content for storefront and admin use', () {
      final category = buildCategory();

      expect(category.id, 'cat-beverages');
      expect(category.name, 'Beverages');
      expect(category.description, 'Hot and cold drinks');
      expect(category.imageUrl, contains('beverages'));
      expect(category.isActive, isTrue);
    });

    test('supports value equality', () {
      expect(buildCategory(), equals(buildCategory()));
    });

    test('copyWith can disable a category without changing identity', () {
      final category = buildCategory();

      final updated = category.copyWith(isActive: false);

      expect(updated.id, category.id);
      expect(updated.isActive, isFalse);
      expect(updated.name, category.name);
    });

    test('round-trips through json serialization', () {
      final category = buildCategory();

      final recreated = Category.fromJson(category.toJson());

      expect(recreated, equals(category));
    });
  });
}
