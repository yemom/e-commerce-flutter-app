import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/order.dart';
import '../services/api_service.dart';
import 'auth_provider.dart';

final ordersProvider =
    StateNotifierProvider<OrdersController, AsyncValue<List<Order>>>((ref) {
      final api = ref.read(apiServiceProvider);
      return OrdersController(api);
    });

class OrdersController extends StateNotifier<AsyncValue<List<Order>>> {
  OrdersController(this.api) : super(const AsyncValue.loading()) {
    fetchAssigned();
  }

  final ApiService api;

  Future<void> fetchAssigned({bool showLoader = true}) async {
    if (showLoader || !state.hasValue) {
      state = const AsyncValue.loading();
    }

    // Use AsyncValue.guard but avoid writing state after disposal.
    final next = await AsyncValue.guard(() async {
      final list = await api.getAssignedOrders();
      return list
          .map((e) => Order.fromJson(e as Map<String, dynamic>))
          .toList(growable: false);
    });
    if (!mounted) return;
    state = next;
  }

  Future<void> updateStatus(String orderId, String status) async {
    await api.updateOrderStatus(orderId, {'status': status});
    await fetchAssigned(showLoader: false);
  }
}
