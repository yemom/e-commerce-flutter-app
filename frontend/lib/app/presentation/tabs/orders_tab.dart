library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:e_commerce_app_with_django/app/services/app_navigation_service.dart';
import 'package:e_commerce_app_with_django/app/presentation/widgets/app_status_screen.dart';
import 'package:e_commerce_app_with_django/features/auth/presentation/providers/auth_provider.dart';
import 'package:e_commerce_app_with_django/features/checkout/presentation/screens/flow/order_tracking_screen.dart';
import 'package:e_commerce_app_with_django/features/orders/application/order_service.dart';
import 'package:e_commerce_app_with_django/features/orders/presentation/providers/order_provider.dart';
import 'package:e_commerce_app_with_django/features/orders/presentation/screens/user_orders_screen.dart';

class OrdersTab extends ConsumerWidget {
  const OrdersTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final orderState = ref.watch(orderProvider);
    final session = authState.session;

    if (session == null) {
      return const AppLoadingScreen();
    }

    final navigation = ref.read(appNavigationServiceProvider);
    final userOrders = orderState.orders
        .where((order) => order.customerId == session.userId)
        .toList();

    return UserOrdersScreen(
      orders: userOrders,
      isLoading: orderState.isLoading,
      onRefresh: () => ref.read(orderServiceProvider).refreshOrders(),
      onTrackOrder: (order) {
        navigation.push(OrderTrackingScreen(order: order));
      },
    );
  }
}
