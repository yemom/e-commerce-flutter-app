/// Test coverage for order_test behaviors.
library;

import 'package:flutter_test/flutter_test.dart';

import 'package:e_commerce_app_with_django/features/orders/domain/models/order.dart';
import 'package:e_commerce_app_with_django/features/payment/domain/models/payment.dart';

import '../../../../support/test_data.dart';

void main() {
  group('Order', () {
    test('stores branch, payment, totals, and line items', () {
      final order = buildOrder();

      expect(order.id, 'order-1');
      expect(order.branchId, 'branch-addis-bole');
      expect(order.items, hasLength(1));
      expect(order.status, OrderStatus.pending);
      expect(order.payment.method, PaymentMethod.telebirr);
      expect(order.subtotal, 440);
      expect(order.deliveryFee, 50);
      expect(order.total, 490);
    });

    test('supports full order tracking lifecycle', () {
      expect(OrderStatus.values, contains(OrderStatus.pending));
      expect(OrderStatus.values, contains(OrderStatus.confirmed));
      expect(OrderStatus.values, contains(OrderStatus.shipped));
      expect(OrderStatus.values, contains(OrderStatus.delivered));
    });

    test('copyWith updates status and nested payment data', () {
      final order = buildOrder();

      final updated = order.copyWith(
        status: OrderStatus.confirmed,
        payment: order.payment.copyWith(status: PaymentStatus.verified),
      );

      expect(updated.status, OrderStatus.confirmed);
      expect(updated.payment.status, PaymentStatus.verified);
      expect(updated.total, order.total);
    });

    test('serializes and deserializes nested items and payment', () {
      final order = buildOrder(
        status: OrderStatus.shipped,
        payment: buildPayment(
          status: PaymentStatus.verified,
          verifiedAt: fixedDate,
        ),
      );

      final recreated = Order.fromJson(order.toJson());

      expect(recreated, equals(order));
      expect(recreated.items.first.quantity, 2);
      expect(recreated.payment.status, PaymentStatus.verified);
    });
  });
}
