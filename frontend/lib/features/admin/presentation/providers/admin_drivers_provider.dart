/// Provides the driver list and detail state for the admin dashboard.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:e_commerce_app_with_django/features/admin/application/admin_driver_service.dart';
import 'package:e_commerce_app_with_django/features/admin/domain/models/admin_driver.dart';

final adminDriversProvider = StateNotifierProvider<AdminDriversController, AsyncValue<List<AdminDriver>>>((ref) {
  return AdminDriversController(ref.read(adminDriverServiceProvider));
});

final adminDriverDetailProvider = FutureProvider.family<AdminDriver, String>((ref, driverId) {
  return ref.read(adminDriverServiceProvider).getDriver(driverId);
});

class AdminDriversController extends StateNotifier<AsyncValue<List<AdminDriver>>> {
  /// Creates the list controller and starts an initial load.
  AdminDriversController(this._service) : super(const AsyncValue.loading()) {
    loadDrivers();
  }

  final AdminDriverService _service;

  String _query = '';
  String? _status;
  String? _vehicleType;

  /// Loads the current driver list using the stored filters.
  Future<void> loadDrivers({
    String? query,
    String? status,
    String? vehicleType,
  }) async {
    if (query != null) {
      _query = query;
    }
    if (status != null) {
      _status = status.isEmpty ? null : status;
    }
    if (vehicleType != null) {
      _vehicleType = vehicleType.isEmpty ? null : vehicleType;
    }

    state = const AsyncValue.loading();
    try {
      final drivers = await _service.listDrivers(
        query: _query.isEmpty ? null : _query,
        status: _status,
        vehicleType: _vehicleType,
      );
      state = AsyncValue.data(drivers);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }

  /// Creates a new driver and refreshes the list.
  Future<void> createDriver({
    required String name,
    required String phone,
    required String email,
    required String password,
    required String vehicleType,
    required String licenseNumber,
    required bool isOnline,
  }) async {
    await _service.createDriver(
      name: name,
      phone: phone,
      email: email,
      password: password,
      vehicleType: vehicleType,
      licenseNumber: licenseNumber,
      isOnline: isOnline,
    );
    await loadDrivers();
  }

  /// Updates a driver and refreshes the list.
  Future<void> updateDriver({
    required String driverId,
    required Map<String, dynamic> updates,
  }) async {
    await _service.updateDriver(driverId: driverId, updates: updates);
    await loadDrivers();
  }

  /// Deletes a driver and refreshes the list.
  Future<void> deleteDriver(String driverId) async {
    await _service.deleteDriver(driverId);
    await loadDrivers();
  }

  /// Assigns a driver to an order and refreshes the list.
  Future<void> assignDriverToOrder({
    required String orderId,
    required String driverId,
    Map<String, dynamic>? location,
  }) async {
    await _service.assignDriverToOrder(orderId: orderId, driverId: driverId, location: location);
    await loadDrivers();
  }
}
