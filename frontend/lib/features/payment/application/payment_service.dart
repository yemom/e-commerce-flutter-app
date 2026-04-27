library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:e_commerce_app_with_django/app/services/app_navigation_service.dart';
import 'package:e_commerce_app_with_django/features/payment/application/payment_gateway_adapter.dart';
import 'package:e_commerce_app_with_django/features/payment/domain/models/payment.dart';

final paymentServiceProvider = Provider<PaymentService>(
  (ref) => PaymentService(
    ref.watch(unifiedPaymentGatewayProvider),
    ref.watch(appNavigationServiceProvider),
  ),
);

class PaymentService {
  const PaymentService(this._gateway, this._navigation);

  final UnifiedPaymentGateway _gateway;
  final AppNavigationService _navigation;

  Future<PaymentGatewayResult?> processPayment({
    required String orderId,
    required String customerId,
    String? customerEmail,
    required PaymentMethod method,
    required double amount,
  }) async {
    final gatewayResult = await _gateway.charge(
      PaymentGatewayRequest(
        orderId: orderId,
        customerId: customerId,
        customerEmail: _normalizeEmail(customerEmail),
        method: method,
        amount: amount,
      ),
    );

    var finalResult = gatewayResult;
    if (_hasExternalCheckout(gatewayResult)) {
      final returned = await _startRedirectAndWaitForReturn(
        methodLabel: method.label,
        checkoutUrl: gatewayResult.checkoutUrl!,
      );
      if (!returned) {
        return null;
      }
    }

    if (method.id == PaymentMethod.cashOnDelivery.id) {
      return finalResult;
    }

    finalResult = await _navigation.runWithBlockingDialog(
      message: 'Checking your payment status...',
      task: () => _gateway.verifyWithPolling(
        PaymentGatewayVerificationRequest(
          orderId: orderId,
          customerId: customerId,
          method: method,
          transactionReference: gatewayResult.transactionReference,
        ),
      ),
    );

    if (finalResult.status == PaymentStatus.pending) {
      throw const PaymentGatewayException(
        'Your payment is still pending. Please wait a moment and try again.',
      );
    }

    if (finalResult.status == PaymentStatus.failed) {
      throw const PaymentGatewayException(
        'Your payment was not completed. Please try again with another method.',
      );
    }

    return finalResult;
  }

  bool _hasExternalCheckout(PaymentGatewayResult result) {
    return result.checkoutUrl?.trim().isNotEmpty == true;
  }

  String? _normalizeEmail(String? email) {
    final normalized = email?.trim();
    return normalized == null || normalized.isEmpty ? null : normalized;
  }

  Future<bool> _startRedirectAndWaitForReturn({
    required String methodLabel,
    required String checkoutUrl,
  }) async {
    final checkoutUri = Uri.tryParse(checkoutUrl.trim());
    if (checkoutUri == null) {
      throw const PaymentGatewayException(
        'The payment page link is invalid. Please try again.',
      );
    }

    final opened = await launchUrl(
      checkoutUri,
      mode: LaunchMode.externalApplication,
    );
    if (!opened) {
      throw const PaymentGatewayException(
        'We could not open the payment page. Please try again.',
      );
    }

    final returned = await _navigation.showAppDialog<bool>(
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        title: Text('Complete $methodLabel Payment'),
        content: const Text(
          'After finishing payment in your browser/app, come back here and tap "I have returned" so we can verify it.',
        ),
        actions: [
          TextButton(
            onPressed: () => _navigation.pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => _navigation.pop(true),
            child: const Text('I have returned'),
          ),
        ],
      ),
    );

    return returned ?? false;
  }
}
