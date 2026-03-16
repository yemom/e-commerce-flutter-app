/// Lists the signed-in user's orders and current statuses.
library;
import 'package:flutter/material.dart';

import 'package:e_commerce_app_with_django/core/presentation/widgets/app_formatters.dart';
import 'package:e_commerce_app_with_django/features/orders/domain/models/order.dart';

class UserOrdersScreen extends StatelessWidget {
  const UserOrdersScreen({
    super.key,
    required this.orders,
    this.isLoading = false,
    this.onRefresh,
    this.onTrackOrder,
  });

  final List<Order> orders;
  final bool isLoading;
  final Future<void> Function()? onRefresh;
  final ValueChanged<Order>? onTrackOrder;

  @override
  Widget build(BuildContext context) {
    // Show loading, empty state, or order list depending on current data.
    final content = isLoading && orders.isEmpty
        ? const Center(child: CircularProgressIndicator())
        : orders.isEmpty
        ? const Center(child: Text('You do not have any orders yet.'))
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: orders.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final order = orders[index];
                  return Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: const Color(0xFFE7ECF3)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(order.id, style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 6),
                        Text('Status: ${order.status.name}'),
                        Text('Payment: ${order.payment.status.name}'),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                formatPrice(order.total),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF5E56E7),
                                ),
                              ),
                            ),
                            if (onTrackOrder != null)
                              OutlinedButton.icon(
                                onPressed: () => onTrackOrder!(order),
                                icon: const Icon(Icons.local_shipping_outlined),
                                label: const Text('Track'),
                              ),
                          ],
                        ),
                      ],
                    ),
                  );
                },
              );

    return Scaffold(
      appBar: AppBar(title: const Text('My Orders')),
      body: onRefresh == null ? content : RefreshIndicator(onRefresh: onRefresh!, child: content),
    );
  }
}
