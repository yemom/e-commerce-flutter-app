import 'package:flutter/material.dart';

import '../models/order.dart';

class OrderCard extends StatelessWidget {
  const OrderCard({super.key, required this.order});

  final Order order;

  @override
  Widget build(BuildContext context) {
    final customerLabel = order.customerName.isEmpty
        ? order.customerId
        : order.customerName;
    final addressLabel = order.addressLine.isEmpty
        ? 'No delivery address'
        : order.addressLine;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: ListTile(
        title: Text(customerLabel),
        subtitle: Text('$addressLabel\n${order.statusLabel}'),
        isThreeLine: true,
        trailing: Text('ETB ${order.total.toStringAsFixed(2)}'),
        onTap: () => Navigator.pushNamed(
          context,
          '/orderDetail',
          arguments: {'orderId': order.id},
        ),
      ),
    );
  }
}
