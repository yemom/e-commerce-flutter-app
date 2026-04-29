/// Test coverage for product_detail_screen behaviors.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:e_commerce_app_with_django/features/products/presentation/screens/product_detail_screen.dart';

import '../../../../support/pump_app.dart';
import '../../../../support/test_data.dart';

void main() {
  group('ProductDetailScreen', () {
    testWidgets('fetches the latest product and scrolls through multiple images', (tester) async {
      var fetchCount = 0;
      final serverProduct = buildProduct(
        id: 'prod-coffee-1',
        imageUrls: const [
          'https://example.com/products/coffee-1.png',
          'https://example.com/products/coffee-2.png',
        ],
        imageUrl: 'https://example.com/products/coffee-1.png',
      );

      await pumpTestApp(
        tester,
        child: ProductDetailScreen(
          product: buildProduct(
            id: 'prod-coffee-1',
            imageUrls: const ['https://example.com/products/coffee-1.png'],
            imageUrl: 'https://example.com/products/coffee-1.png',
          ),
          onAddToCart: (_) {},
          onFetchProduct: (productId) async {
            fetchCount++;
            expect(productId, 'prod-coffee-1');
            return serverProduct;
          },
        ),
      );

      await tester.pumpAndSettle();

      expect(fetchCount, 1);
      expect(find.text('Arabica Coffee'), findsOneWidget);
      expect(find.byWidgetPredicate((widget) => widget is Scrollable && widget.axisDirection == AxisDirection.right), findsOneWidget);

      final horizontalScrollable = find.byWidgetPredicate((widget) => widget is Scrollable && widget.axisDirection == AxisDirection.right);
      await tester.drag(horizontalScrollable, const Offset(-500, 0));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('product-gallery.image.1')), findsOneWidget);
    });
  });
}
