/// Describes the data operations available for customer orders.
library;
import 'package:e_commerce_app_with_django/features/orders/domain/models/order.dart';
import 'package:e_commerce_app_with_django/features/payment/domain/models/payment.dart';

abstract class OrderRepository {
  Future<Order> confirmOrder(Order order);

  Future<List<Order>> getOrders({
    String? branchId,
    OrderStatus? status,
  });

  Future<Order> updateOrderStatus({
    required String orderId,
    required OrderStatus status,
  });

  Future<Order> verifyOrderPayment({
    required String orderId,
    required PaymentStatus paymentStatus,
  });
}