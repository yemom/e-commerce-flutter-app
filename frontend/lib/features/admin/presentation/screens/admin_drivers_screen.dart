/// Admin screen for searching, filtering, creating, editing, and deleting drivers.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:e_commerce_app_with_django/app/services/app_navigation_service.dart';
import 'package:e_commerce_app_with_django/features/admin/domain/models/admin_driver.dart';
import 'package:e_commerce_app_with_django/features/admin/presentation/providers/admin_drivers_provider.dart';
import 'package:e_commerce_app_with_django/features/admin/presentation/screens/admin_driver_detail_screen.dart';

class AdminDriversScreen extends ConsumerStatefulWidget {
  /// Creates the admin driver management page.
  const AdminDriversScreen({super.key});

  @override
  ConsumerState<AdminDriversScreen> createState() => _AdminDriversScreenState();
}

class _AdminDriversScreenState extends ConsumerState<AdminDriversScreen> {
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _orderIdController = TextEditingController();
  String? _statusFilter;
  String? _vehicleTypeFilter;

  /// Loads the driver list using the current filter values.
  Future<void> _reloadDrivers() async {
    await ref.read(adminDriversProvider.notifier).loadDrivers(
      query: _searchController.text.trim(),
      status: _statusFilter,
      vehicleType: _vehicleTypeFilter,
    );
  }

  /// Opens the dialog used to create or update a driver.
  Future<void> _showDriverDialog({AdminDriver? driver}) async {
    final nameController = TextEditingController(text: driver?.name ?? '');
    final phoneController = TextEditingController(text: driver?.phone ?? '');
    final emailController = TextEditingController(text: driver?.email ?? '');
    final passwordController = TextEditingController();
    final vehicleTypeController = TextEditingController(text: driver?.vehicleType ?? '');
    final licenseController = TextEditingController(text: driver?.licenseNumber ?? '');
    var isOnline = driver?.isOnline ?? false;
    final formKey = GlobalKey<FormState>();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setStateDialog) {
            return AlertDialog(
              title: Text(driver == null ? 'Add Driver' : 'Edit Driver'),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _buildTextField(
                        controller: nameController,
                        label: 'Full name',
                        validator: (value) => value == null || value.trim().isEmpty ? 'Name is required.' : null,
                      ),
                      const SizedBox(height: 12),
                      _buildTextField(
                        controller: phoneController,
                        label: 'Phone number',
                        keyboardType: TextInputType.phone,
                        validator: (value) => value == null || value.trim().isEmpty ? 'Phone is required.' : null,
                      ),
                      const SizedBox(height: 12),
                      _buildTextField(
                        controller: emailController,
                        label: 'Email',
                        keyboardType: TextInputType.emailAddress,
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
                      _buildTextField(
                        controller: driver == null ? passwordController : null,
                        label: driver == null ? 'Password' : 'Password (optional)',
                        obscureText: true,
                        validator: driver == null
                            ? (value) => value == null || value.trim().length < 6 ? 'Password must be at least 6 characters.' : null
                            : null,
                      ),
                      const SizedBox(height: 12),
                      _buildTextField(
                        controller: vehicleTypeController,
                        label: 'Vehicle type',
                        validator: (value) => value == null || value.trim().isEmpty ? 'Vehicle type is required.' : null,
                      ),
                      const SizedBox(height: 12),
                      _buildTextField(
                        controller: licenseController,
                        label: 'License number',
                        validator: (value) => value == null || value.trim().isEmpty ? 'License number is required.' : null,
                      ),
                      const SizedBox(height: 8),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Online'),
                        value: isOnline,
                        onChanged: (value) => setStateDialog(() => isOnline = value),
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
                    final notifier = ref.read(adminDriversProvider.notifier);
                    if (driver == null) {
                      await notifier.createDriver(
                        name: nameController.text.trim(),
                        phone: phoneController.text.trim(),
                        email: emailController.text.trim(),
                        password: passwordController.text.trim(),
                        vehicleType: vehicleTypeController.text.trim(),
                        licenseNumber: licenseController.text.trim(),
                        isOnline: isOnline,
                      );
                    } else {
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
                      await notifier.updateDriver(driverId: driver.id, updates: updates);
                    }
                    if (!dialogContext.mounted) {
                      return;
                    }
                    Navigator.of(dialogContext).pop();
                  },
                  child: Text(driver == null ? 'Create' : 'Update'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// Opens a confirmation dialog before deleting a driver.
  Future<void> _confirmDelete(AdminDriver driver) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete driver'),
          content: Text('Delete ${driver.name}? This action cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFB91C1C), foregroundColor: Colors.white),
              onPressed: () async {
                await ref.read(adminDriversProvider.notifier).deleteDriver(driver.id);
                if (!dialogContext.mounted) {
                  return;
                }
                Navigator.of(dialogContext).pop();
              },
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }

  /// Opens a small assignment modal for the chosen order id.
  Future<void> _showAssignOrderDialog(List<AdminDriver> drivers) async {
    final availableDrivers = drivers.where((driver) => driver.statusLabel != 'Busy' && driver.isOnline).toList(growable: false);
    String? selectedDriverId = availableDrivers.isNotEmpty ? availableDrivers.first.id : null;
    final formKey = GlobalKey<FormState>();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setStateDialog) {
            return AlertDialog(
              title: const Text('Assign driver to order'),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildTextField(
                      controller: _orderIdController,
                      label: 'Order ID',
                      validator: (value) => value == null || value.trim().isEmpty ? 'Order ID is required.' : null,
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      initialValue: selectedDriverId,
                      decoration: const InputDecoration(labelText: 'Available driver'),
                      items: availableDrivers
                          .map(
                            (driver) => DropdownMenuItem<String>(
                              value: driver.id,
                              child: Text('${driver.name} (${driver.statusLabel})'),
                            ),
                          )
                          .toList(growable: false),
                      onChanged: (value) => setStateDialog(() => selectedDriverId = value),
                      validator: (value) => value == null || value.isEmpty ? 'Pick a driver.' : null,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (!(formKey.currentState?.validate() ?? false) || selectedDriverId == null) {
                      return;
                    }
                    await ref.read(adminDriversProvider.notifier).assignDriverToOrder(
                      orderId: _orderIdController.text.trim(),
                      driverId: selectedDriverId!,
                    );
                    if (!dialogContext.mounted) {
                      return;
                    }
                    Navigator.of(dialogContext).pop();
                  },
                  child: const Text('Assign'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  /// Builds a labeled text field used by the create/edit dialogs.
  Widget _buildTextField({
    required TextEditingController? controller,
    required String label,
    String? Function(String?)? validator,
    bool obscureText = false,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(labelText: label),
    );
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _reloadDrivers();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _orderIdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final driversState = ref.watch(adminDriversProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Driver Management'),
        actions: [
          IconButton(
            tooltip: 'Assign order',
            onPressed: driversState.maybeWhen(
              data: (drivers) => drivers.isEmpty ? null : () => _showAssignOrderDialog(drivers),
              orElse: () => null,
            ),
            icon: const Icon(Icons.local_shipping_outlined),
          ),
          IconButton(
            tooltip: 'Add driver',
            onPressed: () => _showDriverDialog(),
            icon: const Icon(Icons.person_add_alt_1_outlined),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _reloadDrivers,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Search and filters',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      labelText: 'Search by name, phone, email, or vehicle',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: IconButton(
                        tooltip: 'Search',
                        onPressed: _reloadDrivers,
                        icon: const Icon(Icons.tune),
                      ),
                    ),
                    onSubmitted: (_) => _reloadDrivers(),
                  ),
                  const SizedBox(height: 12),
                  Wrap(
                    spacing: 12,
                    runSpacing: 12,
                    children: [
                      SizedBox(
                        width: 180,
                        child: DropdownButtonFormField<String?>(
                          initialValue: _statusFilter,
                          decoration: const InputDecoration(labelText: 'Status'),
                          items: const [
                            DropdownMenuItem<String?>(value: null, child: Text('All')),
                            DropdownMenuItem<String?>(value: 'available', child: Text('Available')),
                            DropdownMenuItem<String?>(value: 'busy', child: Text('Busy')),
                            DropdownMenuItem<String?>(value: 'offline', child: Text('Offline')),
                          ],
                          onChanged: (value) async {
                            setState(() => _statusFilter = value);
                            await _reloadDrivers();
                          },
                        ),
                      ),
                      SizedBox(
                        width: 200,
                        child: DropdownButtonFormField<String?>(
                          initialValue: _vehicleTypeFilter,
                          decoration: const InputDecoration(labelText: 'Vehicle type'),
                          items: const [
                            DropdownMenuItem<String?>(value: null, child: Text('All vehicles')),
                            DropdownMenuItem<String?>(value: 'bike', child: Text('Bike')),
                            DropdownMenuItem<String?>(value: 'car', child: Text('Car')),
                            DropdownMenuItem<String?>(value: 'scooter', child: Text('Scooter')),
                            DropdownMenuItem<String?>(value: 'van', child: Text('Van')),
                          ],
                          onChanged: (value) async {
                            setState(() => _vehicleTypeFilter = value);
                            await _reloadDrivers();
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            driversState.when(
              loading: () => const Padding(
                padding: EdgeInsets.only(top: 72),
                child: Center(child: CircularProgressIndicator()),
              ),
              error: (error, _) => Padding(
                padding: const EdgeInsets.only(top: 72),
                child: Center(child: Text('Failed to load drivers: $error')),
              ),
              data: (drivers) {
                if (drivers.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.only(top: 72),
                    child: Center(child: Text('No drivers found.')),
                  );
                }

                return Column(
                  children: drivers
                      .map(
                        (driver) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: _DriverCard(
                            driver: driver,
                            onViewDetails: () {
                              final navigation = ref.read(appNavigationServiceProvider);
                              navigation.push(AdminDriverDetailScreen(driverId: driver.id));
                            },
                            onEdit: () => _showDriverDialog(driver: driver),
                            onDelete: () => _confirmDelete(driver),
                          ),
                        ),
                      )
                      .toList(growable: false),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// Renders a compact driver card for the list view.
class _DriverCard extends StatelessWidget {
  /// Creates a card for the given driver.
  const _DriverCard({
    required this.driver,
    required this.onViewDetails,
    required this.onEdit,
    required this.onDelete,
  });

  final AdminDriver driver;
  final VoidCallback onViewDetails;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  /// Converts the driver state into a display color.
  Color _statusColor() {
    switch (driver.statusLabel) {
      case 'Available':
        return const Color(0xFF059669);
      case 'Busy':
        return const Color(0xFFF59E0B);
      default:
        return const Color(0xFF6B7280);
    }
  }

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
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: const Color(0xFFE0E7FF),
                  child: Text(
                    driver.name.isEmpty ? '?' : driver.name[0].toUpperCase(),
                    style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF4338CA)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(driver.name, style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 4),
                      Text(driver.email.isEmpty ? driver.phone : driver.email),
                      Text('Phone: ${driver.phone}'),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.circle, size: 10, color: _statusColor()),
                          const SizedBox(width: 8),
                          Text(
                            'Status: ${driver.statusLabel}',
                            style: TextStyle(
                              color: _statusColor(),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                Chip(
                  backgroundColor: _statusColor().withValues(alpha: 0.12),
                  label: Text(
                    driver.statusLabel,
                    style: TextStyle(color: _statusColor(), fontWeight: FontWeight.w700),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 8,
              children: [
                _InfoChip(label: 'Vehicle', value: driver.vehicleType.isEmpty ? 'n/a' : driver.vehicleType),
                _InfoChip(label: 'License', value: driver.licenseNumber.isEmpty ? 'n/a' : driver.licenseNumber),
                _InfoChip(label: 'Active orders', value: driver.activeOrdersCount.toString()),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                OutlinedButton(onPressed: onViewDetails, child: const Text('View Details')),
                OutlinedButton(onPressed: onEdit, child: const Text('Edit')),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFFB91C1C)),
                  onPressed: onDelete,
                  child: const Text('Delete'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Small label/value chip used by the driver card.
class _InfoChip extends StatelessWidget {
  /// Creates a single info chip.
  const _InfoChip({required this.label, required this.value});

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
