/// Test coverage for checkout_screen_test behaviors.
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:e_commerce_app_with_django/features/checkout/presentation/screens/checkout_screen.dart';
import 'package:e_commerce_app_with_django/features/payment/domain/models/payment.dart';

import '../../../../support/pump_app.dart';
import '../../../../support/test_data.dart';

void main() {
  group('CheckoutScreen', () {
    testWidgets('renders supported payment methods and order summary', (
      tester,
    ) async {
      PaymentMethod? selectedMethod;

      await pumpTestApp(
        tester,
        child: CheckoutScreen(
          orderPreview: buildOrder(),
          deliveryAddress: 'Addis Ababa, Ethiopia',
          paymentOptions: testPaymentOptions,
          selectedMethod: PaymentMethod.telebirr,
          onPaymentMethodSelected: (method) => selectedMethod = method,
          onConfirmOrder: () {},
        ),
      );

      expect(find.text('Telebirr'), findsOneWidget);
      expect(find.text('CBE'), findsOneWidget);
      expect(find.text('Cash on delivery'), findsOneWidget);
      expect(find.text('ETB 490.00'), findsOneWidget);

      await tester.scrollUntilVisible(
        find.byKey(const Key('checkout.payment.cbe')),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.byKey(const Key('checkout.payment.cbe')));
      await tester.pump();

      expect(selectedMethod, PaymentMethod.cbe);
    });

    testWidgets('confirms the order with the current payment selection', (
      tester,
    ) async {
      var confirmed = false;

      await pumpTestApp(
        tester,
        child: CheckoutScreen(
          orderPreview: buildOrder(),
          deliveryAddress: 'Addis Ababa, Ethiopia',
          paymentOptions: testPaymentOptions,
          selectedMethod: PaymentMethod.cashOnDelivery,
          onPaymentMethodSelected: (_) {},
          onConfirmOrder: () => confirmed = true,
        ),
      );

      await tester.scrollUntilVisible(
        find.byKey(const Key('checkout.confirm-order')),
        250,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.tap(find.byKey(const Key('checkout.confirm-order')));
      await tester.pump();

      expect(confirmed, isTrue);
    });
  });
}
