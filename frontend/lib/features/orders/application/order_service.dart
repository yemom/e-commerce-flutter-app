library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:e_commerce_app_with_django/features/orders/domain/models/order.dart';
import 'package:e_commerce_app_with_django/features/orders/presentation/providers/order_provider.dart';
import 'package:e_commerce_app_with_django/features/payment/domain/models/payment.dart';

final orderServiceProvider = Provider<OrderService>((ref) => OrderService(ref));

class OrderService {
  OrderService(this._ref);

  final Ref _ref;

  Future<void> refreshOrders({String? branchId, OrderStatus? status}) {
    return _ref
        .read(orderProvider.notifier)
        .loadOrders(branchId: branchId, status: status);
  }

  Future<Order> confirmOrder(Order order) {
    return _ref.read(orderProvider.notifier).confirmOrderAndReturn(order);
  }

  Future<void> verifyPayment(String orderId) {
    return _ref
        .read(orderProvider.notifier)
        .verifyPayment(orderId: orderId, paymentStatus: PaymentStatus.verified);
  }

  Future<void> markOrderShipped(String orderId) {
    return _ref
        .read(orderProvider.notifier)
        .updateStatus(orderId: orderId, status: OrderStatus.shipped);
  }

  Future<void> markOrderDelivered(String orderId) {
    return _ref
        .read(orderProvider.notifier)
        .updateStatus(orderId: orderId, status: OrderStatus.delivered);
  }
}
