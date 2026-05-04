/// Test coverage for cart_screen_test behaviors.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:e_commerce_app_with_django/features/cart/presentation/providers/cart_provider.dart';
import 'package:e_commerce_app_with_django/features/cart/presentation/screens/cart_screen.dart';

import '../../../../support/pump_app.dart';
import '../../../../support/test_data.dart';

void main() {
  group('CartScreen', () {
    testWidgets('renders cart items and total price', (tester) async {
      final state = CartState(
        items: [
          CartItem(product: testProducts.first, quantity: 2),
          CartItem(product: testProducts[1], quantity: 1),
        ],
        totalItems: 3,
        totalPrice: 550,
      );

      await pumpTestApp(
        tester,
        child: CartScreen(
          state: state,
          onQuantityChanged: ({required productId, required quantity}) {},
          onRemoveProduct: (_) {},
          onCheckout: () {},
        ),
      );

      await tester.pumpAndSettle();
      await tester.scrollUntilVisible(
        find.text('Black Tea'),
        200,
        scrollable: find.byType(Scrollable).first,
      );

      expect(find.text('Arabica Coffee'), findsOneWidget);
      expect(find.text('Black Tea'), findsOneWidget);
      expect(find.text('ETB 550.00'), findsOneWidget);
      expect(find.byKey(const Key('cart.checkout-button')), findsOneWidget);
    });

    testWidgets('forwards quantity and removal interactions', (tester) async {
      String? removedProductId;
      String? updatedProductId;
      int? updatedQuantity;

      final state = CartState(
        items: [CartItem(product: testProducts.first, quantity: 1)],
        totalItems: 1,
        totalPrice: 220,
      );

      await pumpTestApp(
        tester,
        child: CartScreen(
          state: state,
          onQuantityChanged: ({required productId, required quantity}) {
            updatedProductId = productId;
            updatedQuantity = quantity;
          },
          onRemoveProduct: (productId) => removedProductId = productId,
          onCheckout: () {},
        ),
      );

      await tester.pumpAndSettle();
      await tester.ensureVisible(find.byKey(const Key('cart.increment.prod-coffee-1')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const Key('cart.increment.prod-coffee-1')));
      await tester.pumpAndSettle();

      expect(updatedProductId, 'prod-coffee-1');
      expect(updatedQuantity, 2);

      await tester.tap(find.byKey(const Key('cart.remove.prod-coffee-1')));
      await tester.pumpAndSettle();

      expect(removedProductId, 'prod-coffee-1');
    });
  });
}
