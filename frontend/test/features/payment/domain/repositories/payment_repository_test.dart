/// Test coverage for payment_repository_test behaviors.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:e_commerce_app_with_django/features/payment/domain/models/payment.dart';

import '../../../../support/mocks.dart';
import '../../../../support/test_data.dart';

void main() {
  late MockPaymentRepository repository;

  setUpAll(registerTestFallbackValues);

  setUp(() {
    repository = MockPaymentRepository();
  });

  group('PaymentRepository contract', () {
    test('loads supported payment options for checkout', () async {
      when(() => repository.getPaymentOptions()).thenAnswer((_) async => testPaymentOptions);

      final result = await repository.getPaymentOptions();

      expect(result, hasLength(3));
      expect(result.map((option) => option.method.name), containsAll(['telebirr', 'cbe', 'cashOnDelivery']));
    });

    test('saves and toggles payment methods for admin control', () async {
      final option = buildPaymentOption(
        id: 'payment-bank-transfer',
        label: 'Bank Transfer',
      );

      when(() => repository.addPaymentOption(option)).thenAnswer((_) async => option);
      when(
        () => repository.setPaymentMethodEnabled(
          optionId: 'payment-cbe',
          isEnabled: false,
        ),
      ).thenAnswer(
        (_) async => buildPaymentOption(
          id: 'payment-cbe',
          method: testPaymentOptions[1].method,
          label: 'CBE',
          isEnabled: false,
        ),
      );

      expect(await repository.addPaymentOption(option), option);

      final updated = await repository.setPaymentMethodEnabled(
        optionId: 'payment-cbe',
        isEnabled: false,
      );

      expect(updated.isEnabled, isFalse);
    });

    test('verifies payment status updates from the gateway', () async {
      final verifiedPayment = buildPayment(
        status: PaymentStatus.verified,
        verifiedAt: fixedDate,
      );

      when(
        () => repository.verifyPayment(
          paymentId: 'pay-1',
          transactionReference: 'TX-123456',
        ),
      ).thenAnswer((_) async => verifiedPayment);

      final result = await repository.verifyPayment(
        paymentId: 'pay-1',
        transactionReference: 'TX-123456',
      );

      expect(result.status, PaymentStatus.verified);
      expect(result.verifiedAt, fixedDate);
    });
  });
}
