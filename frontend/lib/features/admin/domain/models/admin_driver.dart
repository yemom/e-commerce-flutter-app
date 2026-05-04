/// Represents a delivery driver visible in the admin dashboard.
library;

import 'package:flutter/foundation.dart';

@immutable
class DriverOrderSummary {
  /// Creates a compact order summary for driver detail pages.
  const DriverOrderSummary({
    required this.id,
    required this.status,
    required this.customerId,
    required this.customerName,
    required this.branchId,
    required this.total,
    required this.itemCount,
    required this.deliveryAddressLine,
    required this.createdAt,
    this.deliveredAt,
  });

  final String id;
  final String status;
  final String customerId;
  final String customerName;
  final String branchId;
  final double total;
  final int itemCount;
  final String deliveryAddressLine;
  final DateTime? createdAt;
  final DateTime? deliveredAt;

  /// Builds an order summary from the backend payload.
  factory DriverOrderSummary.fromJson(Map<String, dynamic> json) {
    return DriverOrderSummary(
      id: (json['id'] as String?)?.trim() ?? '',
      status: (json['status'] as String?)?.trim() ?? 'pending',
      customerId: (json['customerId'] as String?)?.trim() ?? '',
      customerName: (json['customerName'] as String?)?.trim() ?? '',
      branchId: (json['branchId'] as String?)?.trim() ?? '',
      total: (json['total'] as num?)?.toDouble() ?? 0,
      itemCount: (json['itemCount'] as num?)?.toInt() ?? 0,
      deliveryAddressLine:
          (json['deliveryAddressLine'] as String?)?.trim() ?? '',
      createdAt: _asDateTime(json['createdAt']),
      deliveredAt: _asDateTime(json['deliveredAt']),
    );
  }

  /// Converts a dynamic timestamp into a DateTime when possible.
  static DateTime? _asDateTime(Object? value) {
    if (value is DateTime) {
      return value;
    }
    if (value is String && value.trim().isNotEmpty) {
      return DateTime.tryParse(value);
    }
    return null;
  }
}

@immutable
class AdminDriver {
  /// Creates the immutable driver model used by the dashboard.
  const AdminDriver({
    required this.id,
    required this.name,
    required this.phone,
    required this.email,
    required this.vehicleType,
    required this.licenseNumber,
    required this.isOnline,
    required this.currentStatus,
    required this.activeOrdersCount,
    required this.createdAt,
    required this.updatedAt,
    required this.assignedOrders,
    required this.deliveryHistory,
  });

  final String id;
  final String name;
  final String phone;
  final String email;
  final String vehicleType;
  final String licenseNumber;
  final bool isOnline;
  final String currentStatus;
  final int activeOrdersCount;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final List<DriverOrderSummary> assignedOrders;
  final List<DriverOrderSummary> deliveryHistory;

  /// Builds a driver model from the API response.
  factory AdminDriver.fromJson(Map<String, dynamic> json) {
    return AdminDriver(
      id: (json['id'] as String?)?.trim() ?? '',
      name: (json['name'] as String?)?.trim() ?? '',
      phone: (json['phone'] as String?)?.trim() ?? '',
      email: (json['email'] as String?)?.trim() ?? '',
      vehicleType: (json['vehicleType'] as String?)?.trim() ?? '',
      licenseNumber: (json['licenseNumber'] as String?)?.trim() ?? '',
      isOnline: json['isOnline'] as bool? ?? false,
      currentStatus: (json['currentStatus'] as String?)?.trim() ?? '',
      activeOrdersCount: (json['activeOrdersCount'] as num?)?.toInt() ?? 0,
      createdAt: DriverOrderSummary._asDateTime(json['createdAt']),
      updatedAt: DriverOrderSummary._asDateTime(json['updatedAt']),
      assignedOrders: (json['assignedOrders'] as List<dynamic>? ?? const [])
          .map(
            (item) => DriverOrderSummary.fromJson(item as Map<String, dynamic>),
          )
          .toList(growable: false),
      deliveryHistory: (json['deliveryHistory'] as List<dynamic>? ?? const [])
          .map(
            (item) => DriverOrderSummary.fromJson(item as Map<String, dynamic>),
          )
          .toList(growable: false),
    );
  }

  /// Returns a readable status label for the dashboard.
  String get statusLabel {
    switch (currentStatus.toLowerCase()) {
      case 'available':
        return 'Available';
      case 'busy':
        return 'Busy';
      default:
        return isOnline ? 'Available' : 'Offline';
    }
  }

  /// Returns a copy with updated fields.
  AdminDriver copyWith({
    String? id,
    String? name,
    String? phone,
    String? email,
    String? vehicleType,
    String? licenseNumber,
    bool? isOnline,
    String? currentStatus,
    int? activeOrdersCount,
    DateTime? createdAt,
    DateTime? updatedAt,
    List<DriverOrderSummary>? assignedOrders,
    List<DriverOrderSummary>? deliveryHistory,
  }) {
    return AdminDriver(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      vehicleType: vehicleType ?? this.vehicleType,
      licenseNumber: licenseNumber ?? this.licenseNumber,
      isOnline: isOnline ?? this.isOnline,
      currentStatus: currentStatus ?? this.currentStatus,
      activeOrdersCount: activeOrdersCount ?? this.activeOrdersCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      assignedOrders: assignedOrders ?? this.assignedOrders,
      deliveryHistory: deliveryHistory ?? this.deliveryHistory,
    );
  }
}
