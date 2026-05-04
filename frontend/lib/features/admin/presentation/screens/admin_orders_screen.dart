/// Dedicated admin page for refreshing, reviewing, and acting on orders.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:e_commerce_app_with_django/core/presentation/widgets/app_formatters.dart';
import 'package:e_commerce_app_with_django/features/auth/presentation/providers/auth_provider.dart';
import 'package:e_commerce_app_with_django/features/branches/domain/models/branch.dart';
import 'package:e_commerce_app_with_django/features/branches/presentation/providers/branch_provider.dart';
import 'package:e_commerce_app_with_django/features/orders/domain/models/order.dart';
import 'package:e_commerce_app_with_django/features/orders/presentation/providers/order_provider.dart';
import 'package:e_commerce_app_with_django/features/payment/domain/models/payment.dart';
import 'package:e_commerce_app_with_django/features/admin/presentation/providers/admin_drivers_provider.dart';
import 'package:e_commerce_app_with_django/features/admin/domain/models/admin_driver.dart';

class AdminOrdersPage extends ConsumerStatefulWidget {
  const AdminOrdersPage({super.key});

  @override
  ConsumerState<AdminOrdersPage> createState() => _AdminOrdersPageState();
}

class _AdminOrdersPageState extends ConsumerState<AdminOrdersPage> {
  // Optional server-side status filter controlled by the ChoiceChips.
  OrderStatus? _statusFilter;

  @override
  void initState() {
    super.initState();
    // Load once after first frame so provider reads have a valid context.
    Future<void>.microtask(_loadOrders);
  }

  Future<void> _loadOrders() async {
    // Super admins can review all branches; branch admins see current branch only.
    final session = ref.read(authProvider).session;
    final branchId = ref.read(branchProvider).selectedBranchId;
    await ref
        .read(orderProvider.notifier)
        .loadOrders(
          branchId: session?.isSuperAdmin == true ? null : branchId,
          status: _statusFilter,
        );
  }

  Future<void> _runAction(
    Future<void> Function() action,
    String successMessage,
  ) async {
    try {
      // Run admin action, then immediately refresh list so badges/chips stay accurate.
      await action();
      await _loadOrders();
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(successMessage)));
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('We could not update that order. Please try again.'),
        ),
      );
    }
  }

  Future<void> _showOrderDetails({required Order order, required List<Branch> branches, required List<AdminDriver> drivers}) async {
    final availableDrivers = drivers.where((driver) => driver.isOnline && driver.statusLabel != 'Busy').toList(growable: false);
    String? selectedDriverId = order.driverId.isNotEmpty ? order.driverId : (availableDrivers.isNotEmpty ? availableDrivers.first.id : null);

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setStateDialog) {
            return AlertDialog(
              title: Text('Order ${order.id}'),
              content: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('Branch: ${_branchName(order.branchId, branches)}'),
                    Text('Customer: ${order.customerName.isEmpty ? order.customerId : order.customerName}'),
                    Text('Status: ${_orderStatusLabel(order.status)}'),
                    Text('Payment: ${_paymentStatusLabel(order.payment.status)}'),
                    Text('Driver: ${order.driverId.isEmpty ? 'Unassigned' : order.driverId}'),
                    const SizedBox(height: 12),
                    Text('Address: ${order.addressLine.isEmpty ? 'No delivery address' : order.addressLine}'),
                    const SizedBox(height: 12),
                    const Text('Items', style: TextStyle(fontWeight: FontWeight.bold)),
                    for (final item in order.items)
                      Text('${item.productName} x${item.quantity}'),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: selectedDriverId,
                      decoration: const InputDecoration(labelText: 'Assign driver'),
                      items: availableDrivers
                          .map((driver) => DropdownMenuItem<String>(value: driver.id, child: Text('${driver.name} (${driver.statusLabel})')))
                          .toList(growable: false),
                      onChanged: (value) => setStateDialog(() => selectedDriverId = value),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Close')),
                    FilledButton(
                      onPressed: selectedDriverId == null
                          ? null
                          : () async {
                              // Pass the order's delivery address as the explicit
                              // location payload so the driver receives precise
                              // coordinates and address information when assigned.
                              await ref.read(adminDriversProvider.notifier).assignDriverToOrder(
                                orderId: order.id,
                                driverId: selectedDriverId!,
                                location: order.deliveryAddress,
                              );
                              await _loadOrders();
                              if (dialogContext.mounted) Navigator.of(dialogContext).pop();
                            },
                      child: const Text('Assign driver'),
                    ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final orderState = ref.watch(orderProvider);
    final branches = ref.watch(branchProvider).branches;
    // Sort by business priority first, then newest order timestamp.
    final orders = List<Order>.from(orderState.orders)
      ..sort((a, b) {
        final priority = _priority(a.status).compareTo(_priority(b.status));
        return priority != 0 ? priority : b.createdAt.compareTo(a.createdAt);
      });
    final pendingCount = orders
        .where((order) => order.status == OrderStatus.pending)
        .length;
    final paymentReviewCount = orders
        .where((order) => order.payment.status == PaymentStatus.pending)
        .length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Orders'),
        actions: [
          IconButton(
            tooltip: 'Refresh orders',
            onPressed: _loadOrders,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF3EBDD), Color(0xFFF8F6F1)],
          ),
        ),
        child: RefreshIndicator(
          onRefresh: _loadOrders,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: const Color(0xFFE7ECF3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      pendingCount > 0
                          ? '$pendingCount pending order(s) need attention'
                          : 'Orders are up to date',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'This page refreshes when opened so admins always review the latest orders before taking action.',
                      style: TextStyle(color: Color(0xFF6B7280), height: 1.4),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        Chip(label: Text('${orders.length} total')),
                        Chip(label: Text('$pendingCount pending')),
                        Chip(label: Text('$paymentReviewCount payment review')),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  ChoiceChip(
                    label: const Text('All'),
                    selected: _statusFilter == null,
                    onSelected: (_) async {
                      setState(() => _statusFilter = null);
                      await _loadOrders();
                    },
                  ),
                  for (final status in OrderStatus.values)
                    ChoiceChip(
                      label: Text(_orderStatusLabel(status)),
                      selected: _statusFilter == status,
                      onSelected: (_) async {
                        setState(() => _statusFilter = status);
                        await _loadOrders();
                      },
                    ),
                ],
              ),
              const SizedBox(height: 12),
              if (orderState.isLoading && orders.isEmpty)
                const SizedBox(
                  height: 260,
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (orders.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Text('No orders found.'),
                  ),
                )
              else
                ...orders.map((order) {
                  // Compute which actions are currently valid for this order state.
                  final canVerify =
                      order.payment.status == PaymentStatus.pending;
                  final canShip =
                      order.status == OrderStatus.pending ||
                      order.status == OrderStatus.confirmed;
                  final canDeliver =
                      order.status == OrderStatus.shipped ||
                      order.status == OrderStatus.out_for_delivery;
                  return GestureDetector(
                    onTap: () => _showOrderDetails(order: order, branches: branches, drivers: ref.read(adminDriversProvider).maybeWhen(data: (value) => value, orElse: () => const <AdminDriver>[])),
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(color: const Color(0xFFE7ECF3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Order ${order.id}',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleMedium,
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${_branchName(order.branchId, branches)} - ${_formatDate(order.createdAt)}',
                                    style: const TextStyle(
                                      color: Color(0xFF7B8091),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Chip(label: Text(_orderStatusLabel(order.status))),
                          ],
                        ),
                        const SizedBox(height: 10),
                        for (final item in order.items.take(3))
                          Padding(
                            padding: const EdgeInsets.only(bottom: 6),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    '${item.productName} x${item.quantity}',
                                  ),
                                ),
                                Text(
                                  formatPrice(item.unitPrice * item.quantity),
                                ),
                              ],
                            ),
                          ),
                        if (order.items.length > 3)
                          Text(
                            '+ ${order.items.length - 3} more item(s)',
                            style: const TextStyle(color: Color(0xFF7B8091)),
                          ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            Chip(
                              label: Text(
                                'Payment: ${_paymentStatusLabel(order.payment.status)}',
                              ),
                            ),
                            Chip(
                              label: Text('Total: ${formatPrice(order.total)}'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            if (canVerify)
                              OutlinedButton.icon(
                                onPressed: () => _runAction(
                                  () => ref
                                      .read(orderProvider.notifier)
                                      .verifyPayment(
                                        orderId: order.id,
                                        paymentStatus: PaymentStatus.verified,
                                      ),
                                  'Payment verified successfully.',
                                ),
                                icon: const Icon(Icons.verified_outlined),
                                label: const Text('Verify Payment'),
                              ),
                            if (canShip)
                              OutlinedButton.icon(
                                onPressed: () => _runAction(
                                  () => ref
                                      .read(orderProvider.notifier)
                                      .updateStatus(
                                        orderId: order.id,
                                        status: OrderStatus.shipped,
                                      ),
                                  'Order marked as shipped.',
                                ),
                                icon: const Icon(Icons.local_shipping_outlined),
                                label: const Text('Mark Shipped'),
                              ),
                            if (canDeliver)
                              FilledButton.icon(
                                onPressed: () => _runAction(
                                  () => ref
                                      .read(orderProvider.notifier)
                                      .updateStatus(
                                        orderId: order.id,
                                        status: OrderStatus.delivered,
                                      ),
                                  'Order marked as delivered.',
                                ),
                                icon: const Icon(Icons.inventory_2_outlined),
                                label: const Text('Mark Delivered'),
                              ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Tap to view details and assign a driver.',
                          style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
                        ),
                        ],
                      ),
                    ),
                  );
                }),
            ],
          ),
        ),
      ),
    );
  }
}

int _priority(OrderStatus status) {
  // Lower number means higher urgency in the list ordering.
  switch (status) {
    case OrderStatus.pending:
      return 0;
    case OrderStatus.confirmed:
      return 1;
    case OrderStatus.assigned:
      return 2;
    case OrderStatus.out_for_delivery:
      return 3;
    case OrderStatus.shipped:
      return 4;
    case OrderStatus.delivered:
      return 5;
  }
}

String _orderStatusLabel(OrderStatus status) {
  switch (status) {
    case OrderStatus.pending:
      return 'Pending';
    case OrderStatus.confirmed:
      return 'Confirmed';
    case OrderStatus.assigned:
      return 'Assigned';
    case OrderStatus.out_for_delivery:
      return 'Out for delivery';
    case OrderStatus.shipped:
      return 'Shipped';
    case OrderStatus.delivered:
      return 'Delivered';
  }
}

String _paymentStatusLabel(PaymentStatus status) {
  switch (status) {
    case PaymentStatus.pending:
      return 'Pending';
    case PaymentStatus.verified:
      return 'Verified';
    case PaymentStatus.failed:
      return 'Failed';
  }
}

String _branchName(String branchId, List<Branch> branches) {
  // Resolve friendly branch names for display; fall back to raw id if missing.
  for (final branch in branches) {
    if (branch.id == branchId) return branch.name;
  }
  return branchId;
}

String _formatDate(DateTime value) {
  // Keep date format compact and readable for admin list rows.
  final local = value.toLocal();
  final minute = local.minute.toString().padLeft(2, '0');
  return '${local.year}-${local.month.toString().padLeft(2, '0')}-${local.day.toString().padLeft(2, '0')} ${local.hour}:$minute';
}
