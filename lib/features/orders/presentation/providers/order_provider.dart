/// Tracks order history, confirmation, payment, and delivery updates.
library;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:e_commerce_app_with_django/core/data/providers.dart';
import 'package:e_commerce_app_with_django/features/orders/domain/models/order.dart';
import 'package:e_commerce_app_with_django/features/orders/domain/repositories/order_repository.dart';
import 'package:e_commerce_app_with_django/features/payment/domain/models/payment.dart';

final orderRepositoryProvider = Provider<OrderRepository>(
  (ref) => ref.watch(defaultOrderRepositoryProvider),
);

@immutable
class OrderState {
  const OrderState({
    this.orders = const [],
    this.selectedStatus,
    this.latestConfirmedOrder,
    this.isLoading = false,
  });

  final List<Order> orders;
  final OrderStatus? selectedStatus;
  final Order? latestConfirmedOrder;
  final bool isLoading;

  OrderState copyWith({
    List<Order>? orders,
    OrderStatus? selectedStatus,
    Order? latestConfirmedOrder,
    bool? isLoading,
    bool clearSelectedStatus = false,
  }) {
    return OrderState(
      orders: orders ?? this.orders,
      selectedStatus: clearSelectedStatus ? null : (selectedStatus ?? this.selectedStatus),
      latestConfirmedOrder: latestConfirmedOrder ?? this.latestConfirmedOrder,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class OrderNotifier extends StateNotifier<OrderState> {
  OrderNotifier(this._repository) : super(const OrderState());

  final OrderRepository _repository;

  Future<void> loadOrders({String? branchId, OrderStatus? status}) async {
    state = state.copyWith(isLoading: true, selectedStatus: status);
    final orders = await _repository.getOrders(branchId: branchId, status: status);
    state = state.copyWith(orders: orders, isLoading: false);
  }

  Future<void> confirmOrder(Order order) async {
    await confirmOrderAndReturn(order);
  }

  Future<Order> confirmOrderAndReturn(Order order) async {
    final confirmedOrder = await _repository.confirmOrder(order);
    // Keep the newest confirmed version first so tracking screens can read from state immediately.
    final updatedOrders = [
      confirmedOrder,
      ...state.orders.where((item) => item.id != confirmedOrder.id),
    ];
    state = state.copyWith(
      orders: updatedOrders,
      latestConfirmedOrder: confirmedOrder,
    );
    return confirmedOrder;
  }

  Future<void> updateStatus({required String orderId, required OrderStatus status}) async {
    final updatedOrder = await _repository.updateOrderStatus(orderId: orderId, status: status);
    final currentOrders = List<Order>.from(state.orders);
    final index = currentOrders.indexWhere((order) => order.id == orderId);
    // Insert if missing so admin actions still work even when the list was loaded with different filters.
    if (index == -1) {
      currentOrders.add(updatedOrder.copyWith(id: orderId));
    } else {
      currentOrders[index] = updatedOrder;
    }
    state = state.copyWith(orders: currentOrders);
  }

  Future<void> verifyPayment({
    required String orderId,
    required PaymentStatus paymentStatus,
  }) async {
    final updatedOrder = await _repository.verifyOrderPayment(
      orderId: orderId,
      paymentStatus: paymentStatus,
    );
    final currentOrders = List<Order>.from(state.orders);
    final index = currentOrders.indexWhere((order) => order.id == orderId);
    // Mirror the update strategy used for order status so payment changes never disappear from local state.
    if (index == -1) {
      currentOrders.add(updatedOrder);
    } else {
      currentOrders[index] = updatedOrder;
    }
    state = state.copyWith(orders: currentOrders);
  }
}

final orderProvider = StateNotifierProvider<OrderNotifier, OrderState>(
  (ref) => OrderNotifier(ref.watch(orderRepositoryProvider)),
);