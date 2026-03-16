/// Test coverage for payment_provider_test behaviors.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:e_commerce_app_with_django/features/payment/domain/models/payment.dart';
import 'package:e_commerce_app_with_django/features/payment/presentation/providers/payment_provider.dart';

import '../../../../support/mocks.dart';
import '../../../../support/test_data.dart';

void main() {
  late MockPaymentRepository repository;
  late ProviderContainer container;

  setUpAll(registerTestFallbackValues);

  setUp(() {
    repository = MockPaymentRepository();
    container = ProviderContainer(
      overrides: [
        paymentRepositoryProvider.overrideWithValue(repository),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  group('paymentProvider', () {
    test('loads available payment methods for checkout', () async {
      when(() => repository.getPaymentOptions()).thenAnswer((_) async => testPaymentOptions);

      await container.read(paymentProvider.notifier).loadPaymentOptions();

      final state = container.read(paymentProvider);

      expect(state.options, hasLength(3));
      expect(state.options.map((option) => option.method), containsAll(PaymentMethod.values));
    });

    test('updates the selected payment method', () async {
      when(() => repository.getPaymentOptions()).thenAnswer((_) async => testPaymentOptions);

      await container.read(paymentProvider.notifier).loadPaymentOptions();
      container.read(paymentProvider.notifier).selectMethod(PaymentMethod.cbe);

      final state = container.read(paymentProvider);

      expect(state.selectedMethod, PaymentMethod.cbe);
    });

    test('verifies the payment and stores the latest transaction', () async {
      final verifiedPayment = buildPayment(
        status: PaymentStatus.verified,
        verifiedAt: fixedDate,
      );

      when(() => repository.getPaymentOptions()).thenAnswer((_) async => testPaymentOptions);
      when(
        () => repository.verifyPayment(
          paymentId: 'pay-1',
          transactionReference: 'TX-123456',
        ),
      ).thenAnswer((_) async => verifiedPayment);

      await container.read(paymentProvider.notifier).loadPaymentOptions();
      await container.read(paymentProvider.notifier).verifyPayment(
            paymentId: 'pay-1',
            transactionReference: 'TX-123456',
          );

      final state = container.read(paymentProvider);

      expect(state.activePayment?.status, PaymentStatus.verified);
      expect(state.activePayment?.verifiedAt, fixedDate);
    });
  });
}
