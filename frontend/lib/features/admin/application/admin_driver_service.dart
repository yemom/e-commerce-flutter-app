/// Provides API access for driver management and delivery operations.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:e_commerce_app_with_django/core/data/datasources/commerce_api_data_source.dart';
import 'package:e_commerce_app_with_django/core/data/providers.dart';
import 'package:e_commerce_app_with_django/features/auth/presentation/providers/auth_provider.dart';
import 'package:e_commerce_app_with_django/features/admin/domain/models/admin_driver.dart';

final adminDriverServiceProvider = Provider<AdminDriverService>(
  (ref) => AdminDriverService(ref),
);

class AdminDriverService {
  /// Creates the service with a Riverpod ref so it can reuse the shared API client and auth session.
  AdminDriverService(this._ref);

  final Ref _ref;

  /// Returns the shared JSON API client.
  CommerceApiDataSource get _api => _ref.read(commerceApiDataSourceProvider);

  /// Builds admin auth headers from the current session token.
  Map<String, String> _authHeaders() {
    final token = _ref.read(authProvider).session?.token.trim() ?? '';
    if (token.isEmpty) {
      throw StateError('Admin authentication token is not available.');
    }
    return <String, String>{'Authorization': 'Bearer $token'};
  }

  /// Loads all drivers with optional search and filter parameters.
  Future<List<AdminDriver>> listDrivers({
    String? query,
    String? status,
    String? vehicleType,
  }) async {
    final payload = await _getDriversCollection(
      query: query,
      status: status,
      vehicleType: vehicleType,
    );
    return payload.map((item) => AdminDriver.fromJson(item)).toList(growable: false);
  }

  /// Loads one driver with assigned orders and delivery history.
  Future<AdminDriver> getDriver(String driverId) async {
    final payload = await _getDriverItem(driverId);
    return AdminDriver.fromJson(payload);
  }

  /// Creates a new driver record for delivery operations.
  Future<AdminDriver> createDriver({
    required String name,
    required String phone,
    required String email,
    required String password,
    required String vehicleType,
    required String licenseNumber,
    required bool isOnline,
  }) async {
    final payload = await _postDriverItem(<String, dynamic>{
      'name': name,
      'phone': phone,
      'email': email,
      'password': password,
      'vehicleType': vehicleType,
      'licenseNumber': licenseNumber,
      'isOnline': isOnline,
    });
    return AdminDriver.fromJson(payload);
  }

  /// Updates an existing driver record.
  Future<AdminDriver> updateDriver({
    required String driverId,
    required Map<String, dynamic> updates,
  }) async {
    final payload = await _patchDriverItem(driverId, updates);
    return AdminDriver.fromJson(payload);
  }

  /// Deletes a driver from the system.
  Future<void> deleteDriver(String driverId) async {
    await _deleteDriverItem(driverId);
  }

  /// Assigns a driver to an order and marks the order as assigned.
  Future<void> assignDriverToOrder({
    required String orderId,
    required String driverId,
    Map<String, dynamic>? location,
  }) async {
    final body = <String, dynamic>{'driverId': driverId};
    if (location != null) body['location'] = location;
    await _api.patchItem(
      '/orders/$orderId/assign-driver',
      headers: _authHeaders(),
      body: body,
    );
  }

  Future<List<Map<String, dynamic>>> _getDriversCollection({
    String? query,
    String? status,
    String? vehicleType,
  }) async {
    final queryParameters = <String, String?>{
      'q': query,
      'status': status,
      'vehicleType': vehicleType,
    };
    try {
      return await _api.getCollection(
        '/auth/drivers',
        queryParameters: queryParameters,
        headers: _authHeaders(),
      );
    } on CommerceApiException catch (error) {
      if (error.statusCode != 404) rethrow;
      return _api.getCollection(
        '/drivers',
        queryParameters: queryParameters,
        headers: _authHeaders(),
      );
    }
  }

  Future<Map<String, dynamic>> _getDriverItem(String driverId) async {
    try {
      return await _api.getItem('/auth/drivers/$driverId', headers: _authHeaders());
    } on CommerceApiException catch (error) {
      if (error.statusCode != 404) rethrow;
      return _api.getItem('/drivers/$driverId', headers: _authHeaders());
    }
  }

  Future<Map<String, dynamic>> _postDriverItem(Map<String, dynamic> body) async {
    try {
      return await _api.postItem('/auth/drivers', headers: _authHeaders(), body: body);
    } on CommerceApiException catch (error) {
      if (error.statusCode != 404) rethrow;
      return _api.postItem('/drivers', headers: _authHeaders(), body: body);
    }
  }

  Future<Map<String, dynamic>> _patchDriverItem(String driverId, Map<String, dynamic> body) async {
    try {
      return await _api.patchItem('/auth/drivers/$driverId', headers: _authHeaders(), body: body);
    } on CommerceApiException catch (error) {
      if (error.statusCode != 404) rethrow;
      return _api.patchItem('/drivers/$driverId', headers: _authHeaders(), body: body);
    }
  }

  Future<void> _deleteDriverItem(String driverId) async {
    try {
      await _api.deleteItem('/auth/drivers/$driverId', headers: _authHeaders());
    } on CommerceApiException catch (error) {
      if (error.statusCode != 404) rethrow;
      await _api.deleteItem('/drivers/$driverId', headers: _authHeaders());
    }
  }
}
