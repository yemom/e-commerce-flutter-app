/// Admin detail page for a single driver with assigned orders and delivery history.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:e_commerce_app_with_django/features/admin/domain/models/admin_driver.dart';
import 'package:e_commerce_app_with_django/features/admin/presentation/providers/admin_drivers_provider.dart';

class AdminDriverDetailScreen extends ConsumerWidget {
  /// Creates the detail page for the selected driver.
  const AdminDriverDetailScreen({super.key, required this.driverId});

  final String driverId;

  /// Opens a dialog to update the driver's core profile fields.
  Future<void> _showEditDialog(
    BuildContext context,
    WidgetRef ref,
    AdminDriver driver,
  ) async {
    final nameController = TextEditingController(text: driver.name);
    final phoneController = TextEditingController(text: driver.phone);
    final emailController = TextEditingController(text: driver.email);
    final vehicleTypeController = TextEditingController(
      text: driver.vehicleType,
    );
    final licenseController = TextEditingController(text: driver.licenseNumber);
    final passwordController = TextEditingController();
    var isOnline = driver.isOnline;
    final formKey = GlobalKey<FormState>();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setStateDialog) {
            return AlertDialog(
              title: const Text('Edit driver'),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildField(
                        controller: nameController,
                        label: 'Full name',
                        requiredMessage: 'Name is required.',
                      ),
                      const SizedBox(height: 12),
                      _buildField(
                        controller: phoneController,
                        label: 'Phone',
                        requiredMessage: 'Phone is required.',
                      ),
                      const SizedBox(height: 12),
                      _buildField(
                        controller: emailController,
                        label: 'Email',
                        requiredMessage: 'Email is required.',
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Email is required.';
                          }
                          if (!value.contains('@')) {
                            return 'Enter a valid email.';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),
                      _buildField(
                        controller: vehicleTypeController,
                        label: 'Vehicle type',
                        requiredMessage: 'Vehicle type is required.',
                      ),
                      const SizedBox(height: 12),
                      _buildField(
                        controller: licenseController,
                        label: 'License number',
                        requiredMessage: 'License number is required.',
                      ),
                      const SizedBox(height: 12),
                      _buildField(
                        controller: passwordController,
                        label: 'New password (optional)',
                        requiredMessage: '',
                        obscureText: true,
                        validator: null,
                      ),
                      const SizedBox(height: 8),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Online'),
                        value: isOnline,
                        onChanged: (value) =>
                            setStateDialog(() => isOnline = value),
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (!(formKey.currentState?.validate() ?? false)) {
                      return;
                    }
                    final updates = <String, dynamic>{
                      'name': nameController.text.trim(),
                      'phone': phoneController.text.trim(),
                      'email': emailController.text.trim(),
                      'vehicleType': vehicleTypeController.text.trim(),
                      'licenseNumber': licenseController.text.trim(),
                      'isOnline': isOnline,
                    };
                    if (passwordController.text.trim().isNotEmpty) {
                      updates['password'] = passwordController.text.trim();
                    }
                    await ref
                        .read(adminDriversProvider.notifier)
                        .updateDriver(driverId: driver.id, updates: updates);
                    ref.invalidate(adminDriverDetailProvider(driver.id));
                    if (!context.mounted) {
                      return;
                    }
                    Navigator.of(dialogContext).pop();
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// Shows a modal dialog to assign an order to this driver.
  Future<void> _showAssignOrderDialog(
    BuildContext context,
    WidgetRef ref,
    AdminDriver driver,
  ) async {
    final orderIdController = TextEditingController();
    final formKey = GlobalKey<FormState>();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Assign order to driver'),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: orderIdController,
              decoration: const InputDecoration(labelText: 'Order ID'),
              validator: (value) => (value == null || value.trim().isEmpty)
                  ? 'Order ID is required.'
                  : null,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (!(formKey.currentState?.validate() ?? false)) return;
                final orderId = orderIdController.text.trim();
                try {
                  await ref
                      .read(adminDriversProvider.notifier)
                      .assignDriverToOrder(
                        orderId: orderId,
                        driverId: driver.id,
                      );
                  ref.invalidate(adminDriverDetailProvider(driver.id));
                  if (context.mounted) Navigator.of(dialogContext).pop();
                } catch (err) {
                  // show error
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Failed to assign order: $err')),
                    );
                  }
                }
              },
              child: const Text('Assign'),
            ),
          ],
        );
      },
    );
  }

  /// Builds a reusable text field for the edit dialog.
  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String requiredMessage,
    String? Function(String?)? validator,
    bool obscureText = false,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      validator:
          validator ??
          (value) {
            if (requiredMessage.isEmpty) {
              return null;
            }
            return value == null || value.trim().isEmpty
                ? requiredMessage
                : null;
          },
      decoration: InputDecoration(labelText: label),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final normalizedDriverId = driverId.trim();
    if (normalizedDriverId.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Driver details'),
        ),
        body: const Center(
          child: Text('Driver id is missing. Please go back and try again.'),
        ),
      );
    }

    final driverAsync = ref.watch(adminDriverDetailProvider(normalizedDriverId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Driver details'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: () => ref.invalidate(adminDriverDetailProvider(normalizedDriverId)),
            icon: const Icon(Icons.refresh_outlined),
          ),
        ],
      ),
      body: driverAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Failed to load driver: $error', textAlign: TextAlign.center),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: () => ref.invalidate(adminDriverDetailProvider(normalizedDriverId)),
                  child: const Text('Try again'),
                ),
              ],
            ),
          ),
        ),
        data: (driver) {
          final activeOrders = driver.assignedOrders
              .where((order) => order.status != 'delivered')
              .toList(growable: false);

          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(adminDriverDetailProvider(normalizedDriverId));
              await ref.read(adminDriverDetailProvider(normalizedDriverId).future);
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _HeaderCard(
                  driver: driver,
                  onEdit: () => _showEditDialog(context, ref, driver),
                  onAssign: () => _showAssignOrderDialog(context, ref, driver),
                ),
                const SizedBox(height: 16),
                _SectionCard(
                  title: 'Assigned orders',
                  subtitle: '${activeOrders.length} active order(s)',
                  child: activeOrders.isEmpty
                      ? const Text('No active orders assigned.')
                      : Column(
                          children: activeOrders
                              .map(
                                (order) => ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: const Icon(
                                    Icons.local_shipping_outlined,
                                  ),
                                  title: Text(order.id),
                                  subtitle: Text(
                                    'Customer: ${order.customerName.isEmpty ? order.customerId : order.customerName}\n${order.deliveryAddressLine.isEmpty ? 'No address saved' : order.deliveryAddressLine}',
                                  ),
                                  isThreeLine: true,
                                  trailing: Text(
                                    'ETB ${order.total.toStringAsFixed(2)}\n${order.itemCount} item(s)',
                                    textAlign: TextAlign.end,
                                  ),
                                ),
                              )
                              .toList(growable: false),
                        ),
                ),
                const SizedBox(height: 16),
                _SectionCard(
                  title: 'Delivery history',
                  subtitle:
                      '${driver.deliveryHistory.length} delivered order(s)',
                  child: driver.deliveryHistory.isEmpty
                      ? const Text('No completed deliveries yet.')
                      : Column(
                          children: driver.deliveryHistory
                              .map(
                                (order) => ListTile(
                                  contentPadding: EdgeInsets.zero,
                                  leading: const Icon(
                                    Icons.check_circle_outline,
                                  ),
                                  title: Text(order.id),
                                  subtitle: Text(
                                    'Customer: ${order.customerName.isEmpty ? order.customerId : order.customerName}\n${order.deliveredAt?.toLocal().toString() ?? 'Delivered'}',
                                  ),
                                  isThreeLine: true,
                                  trailing: Text(
                                    'ETB ${order.total.toStringAsFixed(2)}',
                                  ),
                                ),
                              )
                              .toList(growable: false),
                        ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Shows the top summary area for the driver detail page.
class _HeaderCard extends StatelessWidget {
  /// Creates a header card for a driver.
  const _HeaderCard({
    required this.driver,
    required this.onEdit,
    required this.onAssign,
  });

  final AdminDriver driver;
  final VoidCallback onEdit;
  final VoidCallback onAssign;

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(driver.currentStatus);

    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: const Color(0xFFE0E7FF),
                  child: Text(
                    driver.name.isEmpty ? '?' : driver.name[0].toUpperCase(),
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF4338CA),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        driver.name,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 4),
                      Text(driver.email.isEmpty ? driver.phone : driver.email),
                      Text('Phone: ${driver.phone}'),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.circle, size: 10, color: statusColor),
                          const SizedBox(width: 8),
                          Text(
                            'Status: ${driver.statusLabel}',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              color: statusColor,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Chip(
                  label: Text(driver.statusLabel),
                  backgroundColor: statusColor.withValues(alpha: 0.12),
                  side: BorderSide(color: statusColor.withValues(alpha: 0.35)),
                  labelStyle: TextStyle(
                    color: statusColor,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                _MetaChip(
                  label: 'Vehicle',
                  value: driver.vehicleType.isEmpty
                      ? 'n/a'
                      : driver.vehicleType,
                ),
                _MetaChip(
                  label: 'License',
                  value: driver.licenseNumber.isEmpty
                      ? 'n/a'
                      : driver.licenseNumber,
                ),
                _MetaChip(
                  label: 'Active orders',
                  value: driver.activeOrdersCount.toString(),
                ),
                _MetaChip(
                  label: 'Availability',
                  value: driver.isOnline ? 'Online' : 'Offline',
                ),
              ],
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                ConstrainedBox(
                  constraints: const BoxConstraints(minWidth: 140),
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(0, 44),
                    ),
                    onPressed: onEdit,
                    icon: const Icon(Icons.edit_outlined),
                    label: const Text('Edit driver'),
                  ),
                ),
                ConstrainedBox(
                  constraints: const BoxConstraints(minWidth: 140),
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(0, 44),
                    ),
                    onPressed: onAssign,
                    icon: const Icon(Icons.person_add_alt_1_outlined),
                    label: const Text('Assign order'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

Color _statusColor(String status) {
  switch (status.toLowerCase()) {
    case 'available':
      return const Color(0xFF16A34A);
    case 'busy':
      return const Color(0xFFDC2626);
    default:
      return const Color(0xFF64748B);
  }
}

/// Wraps a titled panel for orders and history.
class _SectionCard extends StatelessWidget {
  /// Creates a section card with content.
  const _SectionCard({
    required this.title,
    required this.subtitle,
    required this.child,
  });

  final String title;
  final String subtitle;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 12),
            child,
          ],
        ),
      ),
    );
  }
}

/// Displays small driver metadata chips.
class _MetaChip extends StatelessWidget {
  /// Creates a chip with a label and a value.
  const _MetaChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Text(
        '$label: $value',
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
    );
  }
}
