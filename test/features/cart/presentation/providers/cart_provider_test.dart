/// Test coverage for cart_provider_test behaviors.
library;

import 'package:flutter_test/flutter_test.dart';

import 'package:e_commerce_app_with_django/features/cart/presentation/providers/cart_provider.dart';

import '../../../../support/test_data.dart';

void main() {
  group('cartProvider', () {
    test('adds products and merges quantities for duplicate items', () {
      final container = createCartTestContainer();
      addTearDown(container.dispose);

      final notifier = container.read(cartProvider.notifier);

      notifier.addProduct(testProducts.first);
      notifier.addProduct(testProducts.first);

      final state = container.read(cartProvider);

      expect(state.items, hasLength(1));
      expect(state.items.first.product.id, 'prod-coffee-1');
      expect(state.items.first.quantity, 2);
      expect(state.totalItems, 2);
      expect(state.totalPrice, 440);
    });

    test('updates quantities and recalculates totals', () {
      final container = createCartTestContainer();
      addTearDown(container.dispose);

      final notifier = container.read(cartProvider.notifier);

      notifier.addProduct(testProducts.first);
      notifier.updateQuantity(productId: 'prod-coffee-1', quantity: 3);

      final state = container.read(cartProvider);

      expect(state.items.single.quantity, 3);
      expect(state.totalItems, 3);
      expect(state.totalPrice, 660);
    });

    test('removes products from the cart', () {
      final container = createCartTestContainer();
      addTearDown(container.dispose);

      final notifier = container.read(cartProvider.notifier);

      notifier.addProduct(testProducts.first);
      notifier.addProduct(testProducts[1]);
      notifier.removeProduct('prod-coffee-1');

      final state = container.read(cartProvider);

      expect(state.items, hasLength(1));
      expect(state.items.single.product.id, 'prod-tea-1');
      expect(state.totalPrice, 110);
    });
  });
}
