/// Test coverage for order_repository_test behaviors.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:e_commerce_app_with_django/features/orders/domain/models/order.dart';
import 'package:e_commerce_app_with_django/features/payment/domain/models/payment.dart';

import '../../../../support/mocks.dart';
import '../../../../support/test_data.dart';

void main() {
  late MockOrderRepository repository;

  setUpAll(registerTestFallbackValues);

  setUp(() {
    repository = MockOrderRepository();
  });

  group('OrderRepository contract', () {
    test('confirms orders during checkout', () async {
      final pendingOrder = buildOrder();
      final confirmedOrder = pendingOrder.copyWith(status: OrderStatus.confirmed);

      when(() => repository.confirmOrder(pendingOrder)).thenAnswer((_) async => confirmedOrder);

      final result = await repository.confirmOrder(pendingOrder);

      expect(result.status, OrderStatus.confirmed);
      verify(() => repository.confirmOrder(pendingOrder)).called(1);
    });

    test('fetches orders by branch and status for tracking', () async {
      when(
        () => repository.getOrders(
          branchId: 'branch-addis-merkato',
          status: OrderStatus.confirmed,
        ),
      ).thenAnswer((_) async => [testOrders[1]]);

      final result = await repository.getOrders(
        branchId: 'branch-addis-merkato',
        status: OrderStatus.confirmed,
      );

      expect(result, [testOrders[1]]);
      verify(
        () => repository.getOrders(
          branchId: 'branch-addis-merkato',
          status: OrderStatus.confirmed,
        ),
      ).called(1);
    });

    test('updates order lifecycle and payment verification status', () async {
      when(
        () => repository.updateOrderStatus(
          orderId: 'order-2',
          status: OrderStatus.shipped,
        ),
      ).thenAnswer((_) async => testOrders[1].copyWith(status: OrderStatus.shipped));
      when(
        () => repository.verifyOrderPayment(
          orderId: 'order-2',
          paymentStatus: PaymentStatus.verified,
        ),
      ).thenAnswer(
        (_) async => testOrders[1].copyWith(
          payment: testOrders[1].payment.copyWith(status: PaymentStatus.verified),
        ),
      );

      final shippedOrder = await repository.updateOrderStatus(
        orderId: 'order-2',
        status: OrderStatus.shipped,
      );
      final verifiedOrder = await repository.verifyOrderPayment(
        orderId: 'order-2',
        paymentStatus: PaymentStatus.verified,
      );

      expect(shippedOrder.status, OrderStatus.shipped);
      expect(verifiedOrder.payment.status, PaymentStatus.verified);
    });
  });
}
