import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../providers/orders_provider.dart';
import '../widgets/order_card.dart';

class OrdersScreen extends ConsumerStatefulWidget {
  const OrdersScreen({super.key});

  @override
  ConsumerState<OrdersScreen> createState() => _OrdersScreenState();
}

class _OrdersScreenState extends ConsumerState<OrdersScreen> {
  String _filter = 'all';

  List _applyFilter(List list) {
    if (_filter == 'all') return list;
    if (_filter == 'assigned') return list.where((o) => o.status == 'assigned').toList();
    if (_filter == 'out_for_delivery') return list.where((o) => o.status == 'out_for_delivery').toList();
    if (_filter == 'delivered') return list.where((o) => o.status == 'delivered').toList();
    return list;
  }

  Future<void> _showStatusActions(BuildContext context, dynamic order) async {
    final notifier = ref.read(ordersProvider.notifier);
    await showModalBottomSheet<void>(
      context: context,
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(title: Text('Order ${order.id}'), subtitle: Text(order.addressLine ?? '')),
              if (order.status != 'out_for_delivery')
                ListTile(
                  leading: const Icon(Icons.local_shipping_outlined),
                  title: const Text('Mark Out for Delivery'),
                  onTap: () async {
                    Navigator.of(context).pop();
                    await notifier.updateStatus(order.id, 'out_for_delivery');
                  },
                ),
              if (order.status != 'delivered')
                ListTile(
                  leading: const Icon(Icons.check_circle_outline),
                  title: const Text('Mark Delivered'),
                  onTap: () async {
                    Navigator.of(context).pop();
                    await notifier.updateStatus(order.id, 'delivered');
                  },
                ),
              ListTile(
                leading: const Icon(Icons.info_outline),
                title: const Text('View details'),
                onTap: () {
                  Navigator.of(context).pop();
                  Navigator.pushNamed(context, '/orderDetail', arguments: {'orderId': order.id});
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final ordersAsync = ref.watch(ordersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Assigned Orders'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (v) => setState(() => _filter = v),
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'all', child: Text('All')),
              PopupMenuItem(value: 'assigned', child: Text('Assigned')),
              PopupMenuItem(value: 'out_for_delivery', child: Text('Out for delivery')),
              PopupMenuItem(value: 'delivered', child: Text('Delivered')),
            ],
            icon: const Icon(Icons.filter_list),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(ordersProvider.notifier).fetchAssigned(showLoader: false),
        child: ordersAsync.when(
          data: (list) {
            final filtered = _applyFilter(list);
            if (filtered.isEmpty) {
              return ListView(
                children: const [
                  SizedBox(height: 160),
                  Center(child: Text('No orders have been assigned yet.')),
                ],
              );
            }
            return ListView.builder(
              itemCount: filtered.length,
              itemBuilder: (_, i) => GestureDetector(
                onTap: () => _showStatusActions(context, filtered[i]),
                child: OrderCard(order: filtered[i]),
              ),
            );
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, st) => ListView(
            children: [
              const SizedBox(height: 160),
              Center(child: Text('Error: $e')),
            ],
          ),
        ),
      ),
    );
  }
}
