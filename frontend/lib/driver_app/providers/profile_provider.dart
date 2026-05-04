// lib/driver_app/providers/profile_provider.dart

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/api_service.dart';
import 'auth_provider.dart';

// ── Model ────────────────────────────────────────────────────────────────────

class DriverProfile {
  const DriverProfile({
    required this.name,
    required this.phone,
    required this.email,
    required this.vehicleType,
    required this.licenseNumber,
    required this.currentStatus,
    required this.activeOrdersCount,
  });

  final String name;
  final String phone;
  final String email;
  final String vehicleType;
  final String licenseNumber;
  final String currentStatus;
  final int activeOrdersCount;

  factory DriverProfile.fromJson(Map<String, dynamic> json) => DriverProfile(
        name: json['name'] as String? ?? '',
        phone: json['phone'] as String? ?? '',
        email: json['email'] as String? ?? '',
        vehicleType: json['vehicleType'] as String? ?? '',
        licenseNumber: json['licenseNumber'] as String? ?? '',
        currentStatus: json['currentStatus'] as String? ?? 'offline',
        activeOrdersCount: json['activeOrdersCount'] as int? ?? 0,
      );

  DriverProfile copyWith({
    String? name,
    String? phone,
    String? email,
    String? vehicleType,
    String? licenseNumber,
    String? currentStatus,
    int? activeOrdersCount,
  }) =>
      DriverProfile(
        name: name ?? this.name,
        phone: phone ?? this.phone,
        email: email ?? this.email,
        vehicleType: vehicleType ?? this.vehicleType,
        licenseNumber: licenseNumber ?? this.licenseNumber,
        currentStatus: currentStatus ?? this.currentStatus,
        activeOrdersCount: activeOrdersCount ?? this.activeOrdersCount,
      );
}

// ── Notifier ─────────────────────────────────────────────────────────────────

class DriverProfileNotifier
    extends StateNotifier<AsyncValue<DriverProfile>> {
  DriverProfileNotifier(this._api) : super(const AsyncValue.loading()) {
    fetch();
  }

  final ApiService _api;

  /// Loads the profile from the backend.
  Future<void> fetch() async {
    state = const AsyncValue.loading();
    try {
      final json = await _api.getDriverProfile();
      if (!mounted) return;
      state = AsyncValue.data(DriverProfile.fromJson(json));
    } catch (e, st) {
      if (!mounted) return;
      state = AsyncValue.error(e, st);
    }
  }

  /// Updates the profile and refreshes state on success.
  Future<void> updateProfile({
    required String name,
    required String phone,
    required String email,
    required String vehicleType,
    required String licenseNumber,
    String? currentPassword,
    String? newPassword,
  }) async {
    // Optimistically keep current data visible while saving.
    final previous = state;
    try {
      final json = await _api.updateDriverProfile({
        'name': name,
        'phone': phone,
        'email': email,
        'vehicleType': vehicleType,
        'licenseNumber': licenseNumber,
        if (currentPassword != null) 'currentPassword': currentPassword,
        if (newPassword != null) 'newPassword': newPassword,
      });
      if (!mounted) return;
      state = AsyncValue.data(DriverProfile.fromJson(json));
    } catch (e, st) {
      // Roll back to previous state so the form still shows data.
      if (mounted) state = previous;
      Error.throwWithStackTrace(e, st);
    }
  }
}

// ── Provider ─────────────────────────────────────────────────────────────────

/// StateNotifierProvider — supports both .notifier and .when()
final driverProfileProvider =
    StateNotifierProvider<DriverProfileNotifier, AsyncValue<DriverProfile>>(
  (ref) {
    final api = ref.read(apiServiceProvider);
    return DriverProfileNotifier(api);
  },
);