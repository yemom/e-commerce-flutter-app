import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:e_commerce_app_with_django/features/auth/presentation/providers/auth_provider.dart' as app_auth;

import '../providers/auth_provider.dart';
import '../providers/profile_provider.dart';
import '../providers/orders_provider.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  Timer? _locationTimer;
  @override
  void initState() {
    super.initState();
    Future<void>.microtask(() {
      ref.invalidate(driverProfileProvider);
      ref.read(ordersProvider.notifier).fetchAssigned();
    });

    // Start periodic location updates for driver app
    _locationTimer = Timer.periodic(const Duration(seconds: 10), (_) {
      unawaited(_sendLocation());
    });
  }

  @override
  void dispose() {
    _locationTimer?.cancel();
    super.dispose();
  }

  Future<void> _sendLocation() async {
    try {
      final serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) return;

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) return;

      final pos = await Geolocator.getCurrentPosition();
      final api = ref.read(apiServiceProvider);
      await api.updateDriverLocation({'lat': pos.latitude, 'lng': pos.longitude});
    } catch (_) {
      // silent fail — periodic retries will continue
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authControllerProvider);
    final profileAsync = ref.watch(driverProfileProvider);
    final orders = ref.watch(ordersProvider);

    final assignedCount = orders.maybeWhen(
      data: (list) => list.where((order) => order.status == 'assigned').length,
      orElse: () => 0,
    );
    final activeDeliveryCount = orders.maybeWhen(
      data: (list) =>
          list.where((order) => order.status == 'out_for_delivery').length,
      orElse: () => 0,
    );
    final deliveredCount = orders.maybeWhen(
      data: (list) => list.where((order) => order.status == 'delivered').length,
      orElse: () => 0,
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Driver Home'),
        actions: [
          IconButton(
            onPressed: () => Navigator.pushNamed(context, '/editProfile'),
            icon: const Icon(Icons.person_outline),
            tooltip: 'Edit Profile',
          ),
          IconButton(
            onPressed: () => ref.read(ordersProvider.notifier).fetchAssigned(),
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            onPressed: () async {
              await ref.read(authControllerProvider.notifier).logout();
              await ref.read(app_auth.authProvider.notifier).logout();
            },
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(driverProfileProvider);
          await ref.read(ordersProvider.notifier).fetchAssigned();
        },
        child: orders.when(
          loading: () => ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const SizedBox(height: 8),
              const LinearProgressIndicator(minHeight: 2),
              const SizedBox(height: 24),
            ],
          ),
          error: (error, _) => ListView(
            padding: const EdgeInsets.all(16),
            children: [Text('Profile load failed or orders error: $error')],
          ),
          data: (list) {
            final headerWidgets = <Widget>[];
            headerWidgets.add(
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8,
                ),
                child: profileAsync.when(
                  loading: () => const LinearProgressIndicator(minHeight: 2),
                  error: (error, _) => Text('Profile load failed: $error'),
                  data: (profile) => Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        profile.name,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text('Status: ${profile.currentStatus}'),
                      Text(
                        'Vehicle: ${profile.vehicleType.isEmpty ? 'n/a' : profile.vehicleType}',
                      ),
                      Text(
                        'License: ${profile.licenseNumber.isEmpty ? 'n/a' : profile.licenseNumber}',
                      ),
                      Text('Active orders: ${profile.activeOrdersCount}'),
                      const SizedBox(height: 4),
                      Text(
                        'Authenticated: ${auth.asData?.value?.trim().isNotEmpty == true ? 'Yes' : 'No'}',
                      ),
                    ],
                  ),
                ),
              ),
            );

            headerWidgets.add(
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: SizedBox(
                    width: 180,
                    child: ElevatedButton.icon(
                      onPressed: () => Navigator.pushNamed(context, '/orders'),
                      icon: const Icon(Icons.list_alt),
                      label: const Text('View orders'),
                    ),
                  ),
                ),
              ),
            );

            headerWidgets.add(const SizedBox(height: 8));
            headerWidgets.add(
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Delivery Summary',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('Assigned orders: $assignedCount'),
                    Text('Out for delivery: $activeDeliveryCount'),
                    Text('Delivered: $deliveredCount'),
                  ],
                ),
              ),
            );

            // Build a single ListView that contains header widgets followed by order items.
            return ListView.builder(
              padding: const EdgeInsets.only(bottom: 32),
              itemCount: headerWidgets.length + list.length,
              itemBuilder: (context, index) {
                if (index < headerWidgets.length) return headerWidgets[index];
                final order = list[index - headerWidgets.length];
                return Card(
                  margin: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: ListTile(
                    title: Text('Order ${order.id}'),
                    subtitle: Text(
                      '${order.statusLabel} • ${order.addressLine.isEmpty ? 'No address' : order.addressLine}',
                    ),
                    trailing: Text('ETB ${order.total.toStringAsFixed(2)}'),
                    onTap: () => Navigator.pushNamed(
                      context,
                      '/orderDetail',
                      arguments: {'orderId': order.id},
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
