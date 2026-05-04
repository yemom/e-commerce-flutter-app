import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/order.dart';
import '../providers/orders_provider.dart';

class OrderDetailScreen extends ConsumerWidget {
  const OrderDetailScreen({super.key, required this.orderId});

  final String orderId;

  Order? _findOrder(List<Order> orders) {
    for (final order in orders) {
      if (order.id == orderId) {
        return order;
      }
    }
    return null;
  }

  Future<void> _updateStatus(
    WidgetRef ref,
    BuildContext context,
    String status,
  ) async {
    try {
      await ref.read(ordersProvider.notifier).updateStatus(orderId, status);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Order updated to ${status.replaceAll('_', ' ')}.'),
          ),
        );
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Unable to update order: $error')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orders = ref.watch(ordersProvider);
    final order = orders.asData == null
        ? null
        : _findOrder(orders.asData!.value);
    if (order == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Order')),
        body: const Center(child: Text('Order not found')),
      );
    }

    final lat = order.deliveryAddress['lat'];
    final lng = order.deliveryAddress['lng'];
    final canStartDelivery = order.status == 'assigned';
    final canMarkDelivered =
        order.status == 'assigned' || order.status == 'out_for_delivery';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Order Details'),
        actions: [
          IconButton(
            onPressed: () => ref
                .read(ordersProvider.notifier)
                .fetchAssigned(showLoader: false),
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Order ID: ${order.id}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              'Customer: ${order.customerName.isEmpty ? order.customerId : order.customerName}',
            ),
            if (order.customerEmail.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text('Email: ${order.customerEmail}'),
            ],
            const SizedBox(height: 8),
            Text('Branch: ${order.branchId}'),
            const SizedBox(height: 8),
            Text('Status: ${order.statusLabel}'),
            if (order.createdAt != null) ...[
              const SizedBox(height: 4),
              Text('Created: ${order.createdAt!.toLocal()}'),
            ],
            if (order.outForDeliveryAt != null) ...[
              const SizedBox(height: 4),
              Text('Out for delivery: ${order.outForDeliveryAt!.toLocal()}'),
            ],
            if (order.deliveredAt != null) ...[
              const SizedBox(height: 4),
              Text('Delivered: ${order.deliveredAt!.toLocal()}'),
            ],
            const SizedBox(height: 16),
            Text(
              'Address: ${order.addressLine.isEmpty ? 'No delivery address' : order.addressLine}',
            ),
            const SizedBox(height: 8),
            if (lat != null && lng != null) ...[
              Text('Coordinates: ${lat.toString()}, ${lng.toString()}'),
              const SizedBox(height: 8),
              Container(
                height: 160,
                color: Colors.grey.shade200,
                child: const Center(
                  child: Text(
                    'Map preview available when map integration is added.',
                  ),
                ),
              ),
            ] else ...[
              const Text('No coordinates available'),
            ],
            const SizedBox(height: 16),
            Text('Items', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            ...order.items.map(
              (item) => ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(item.productName),
                subtitle: Text('Quantity: ${item.quantity}'),
                trailing: Text('ETB ${item.lineTotal.toStringAsFixed(2)}'),
              ),
            ),
            const SizedBox(height: 12),
            Text('Subtotal: ETB ${order.subtotal.toStringAsFixed(2)}'),
            Text('Delivery fee: ETB ${order.deliveryFee.toStringAsFixed(2)}'),
            Text('Total: ETB ${order.total.toStringAsFixed(2)}'),
            const SizedBox(height: 16),
            if (canStartDelivery)
              ElevatedButton(
                onPressed: () =>
                    _updateStatus(ref, context, 'out_for_delivery'),
                child: const Text('Start Delivery'),
              ),
            if (canStartDelivery) const SizedBox(height: 8),
            if (canMarkDelivered)
              ElevatedButton(
                onPressed: () => _updateStatus(ref, context, 'delivered'),
                child: const Text('Mark Delivered'),
              ),
          ],
        ),
      ),
    );
  }
}
