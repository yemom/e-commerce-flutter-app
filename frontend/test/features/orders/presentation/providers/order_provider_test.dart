/// Test coverage for order_provider_test behaviors.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:e_commerce_app_with_django/features/orders/domain/models/order.dart';
import 'package:e_commerce_app_with_django/features/orders/presentation/providers/order_provider.dart';

import '../../../../support/mocks.dart';
import '../../../../support/test_data.dart';

void main() {
  late MockOrderRepository repository;
  late ProviderContainer container;

  setUpAll(registerTestFallbackValues);

  setUp(() {
    repository = MockOrderRepository();
    container = ProviderContainer(
      overrides: [
        orderRepositoryProvider.overrideWithValue(repository),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  group('orderProvider', () {
    test('loads orders filtered by branch and status', () async {
      when(
        () => repository.getOrders(
          branchId: 'branch-addis-merkato',
          status: OrderStatus.confirmed,
        ),
      ).thenAnswer((_) async => [testOrders[1]]);

      await container.read(orderProvider.notifier).loadOrders(
            branchId: 'branch-addis-merkato',
            status: OrderStatus.confirmed,
          );

      final state = container.read(orderProvider);

      expect(state.selectedStatus, OrderStatus.confirmed);
      expect(state.orders.single.id, 'order-2');
    });

    test('confirms a new order during checkout', () async {
      final pendingOrder = buildOrder();
      final confirmedOrder = pendingOrder.copyWith(status: OrderStatus.confirmed);

      when(() => repository.confirmOrder(pendingOrder)).thenAnswer((_) async => confirmedOrder);

      await container.read(orderProvider.notifier).confirmOrder(pendingOrder);

      final state = container.read(orderProvider);

      expect(state.latestConfirmedOrder?.status, OrderStatus.confirmed);
      expect(state.latestConfirmedOrder?.id, 'order-1');
    });

    test('progresses orders through shipped and delivered statuses', () async {
      when(
        () => repository.updateOrderStatus(
          orderId: 'order-2',
          status: OrderStatus.shipped,
        ),
      ).thenAnswer((_) async => testOrders[1].copyWith(status: OrderStatus.shipped));
      when(
        () => repository.updateOrderStatus(
          orderId: 'order-2',
          status: OrderStatus.delivered,
        ),
      ).thenAnswer((_) async => testOrders[1].copyWith(status: OrderStatus.delivered));

      await container.read(orderProvider.notifier).updateStatus(
            orderId: 'order-2',
            status: OrderStatus.shipped,
          );
      await container.read(orderProvider.notifier).updateStatus(
            orderId: 'order-2',
            status: OrderStatus.delivered,
          );

      final state = container.read(orderProvider);

      expect(state.orders.singleWhere((order) => order.id == 'order-2').status, OrderStatus.delivered);
    });
  });
}
