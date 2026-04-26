/// Test coverage for payment_test behaviors.
library;

import 'package:flutter_test/flutter_test.dart';

import 'package:e_commerce_app_with_django/features/payment/domain/models/payment.dart';

import '../../../../support/test_data.dart';

void main() {
  group('Payment', () {
    test('supports Telebirr, CBE, and cash on delivery methods', () {
      expect(PaymentMethod.values, contains(PaymentMethod.telebirr));
      expect(PaymentMethod.values, contains(PaymentMethod.cbe));
      expect(PaymentMethod.values, contains(PaymentMethod.cashOnDelivery));
    });

    test('stores transaction metadata and verification state', () {
      final payment = buildPayment();

      expect(payment.orderId, 'order-1');
      expect(payment.method, PaymentMethod.telebirr);
      expect(payment.status, PaymentStatus.pending);
      expect(payment.transactionReference, 'TX-123456');
      expect(payment.verifiedAt, isNull);
    });

    test('copyWith can mark a payment as verified', () {
      final payment = buildPayment();

      final verified = payment.copyWith(
        status: PaymentStatus.verified,
        verifiedAt: fixedDate,
      );

      expect(verified.status, PaymentStatus.verified);
      expect(verified.verifiedAt, fixedDate);
      expect(verified.method, payment.method);
    });

    test('payment option serialization preserves enabled status', () {
      final option = buildPaymentOption(
        method: PaymentMethod.cbe,
        label: 'CBE',
      );

      final recreated = PaymentOption.fromJson(option.toJson());

      expect(recreated, equals(option));
      expect(recreated.isEnabled, isTrue);
    });

    test('payment serializes and deserializes consistently', () {
      final payment = buildPayment(
        status: PaymentStatus.verified,
        verifiedAt: fixedDate,
      );

      final recreated = Payment.fromJson(payment.toJson());

      expect(recreated, equals(payment));
    });
  });
}
