/// Describes the data operations available for payments and payment options.
library;
import 'package:e_commerce_app_with_django/features/payment/domain/models/payment.dart';

abstract class PaymentRepository {
  Future<List<PaymentOption>> getPaymentOptions();

  Future<PaymentOption> addPaymentOption(PaymentOption option);

  Future<PaymentOption> setPaymentMethodEnabled({
    required String optionId,
    required bool isEnabled,
  });

  Future<Payment> verifyPayment({
    required String paymentId,
    required String transactionReference,
  });
}