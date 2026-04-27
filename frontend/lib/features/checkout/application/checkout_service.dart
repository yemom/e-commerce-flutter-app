library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:e_commerce_app_with_django/features/cart/presentation/providers/cart_provider.dart';
import 'package:e_commerce_app_with_django/features/checkout/application/order_preview_service.dart';
import 'package:e_commerce_app_with_django/features/orders/application/order_service.dart';
import 'package:e_commerce_app_with_django/features/orders/domain/models/order.dart';
import 'package:e_commerce_app_with_django/features/payment/application/payment_service.dart';
import 'package:e_commerce_app_with_django/features/payment/domain/models/payment.dart';

final checkoutServiceProvider = Provider<CheckoutService>(
  (ref) => CheckoutService(
    ref,
    ref.watch(orderPreviewServiceProvider),
    ref.watch(paymentServiceProvider),
    ref.watch(orderServiceProvider),
  ),
);

class CheckoutService {
  CheckoutService(
    this._ref,
    this._orderPreviewService,
    this._paymentService,
    this._orderService,
  );

  final Ref _ref;
  final OrderPreviewService _orderPreviewService;
  final PaymentService _paymentService;
  final OrderService _orderService;

  Order buildPreviewOrder({
    required CartState cartState,
    required PaymentMethod selectedMethod,
    required String branchId,
    required String customerId,
  }) {
    return _orderPreviewService.buildPreviewOrder(
      cartState: cartState,
      selectedMethod: selectedMethod,
      branchId: branchId,
      customerId: customerId,
    );
  }

  Future<Order?> confirmCheckout({
    required CartState cartState,
    required PaymentMethod selectedMethod,
    required String branchId,
    required String customerId,
    String? customerEmail,
  }) async {
    final previewOrder = buildPreviewOrder(
      cartState: cartState,
      selectedMethod: selectedMethod,
      branchId: branchId,
      customerId: customerId,
    );

    final paymentResult = await _paymentService.processPayment(
      orderId: previewOrder.id,
      customerId: customerId,
      customerEmail: customerEmail,
      method: selectedMethod,
      amount: previewOrder.total,
    );
    if (paymentResult == null) {
      return null;
    }

    final confirmedOrder = await _orderService.confirmOrder(
      previewOrder.copyWith(
        payment: previewOrder.payment.copyWith(
          method: paymentResult.method,
          status: paymentResult.status,
          transactionReference: paymentResult.transactionReference,
          verifiedAt: paymentResult.verifiedAt,
        ),
      ),
    );

    _ref.read(cartProvider.notifier).clear();
    return confirmedOrder;
  }
}
