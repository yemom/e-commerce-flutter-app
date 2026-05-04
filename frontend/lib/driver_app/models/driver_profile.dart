import 'order.dart';

class DriverProfile {
  DriverProfile({
    required this.id,
    required this.name,
    required this.phone,
    required this.email,
    required this.vehicleType,
    required this.licenseNumber,
    required this.isOnline,
    required this.currentStatus,
    required this.activeOrdersCount,
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
  final List<Order> assignedOrders;
  final List<Order> deliveryHistory;

  factory DriverProfile.fromJson(Map<String, dynamic> json) {
    return DriverProfile(
      id: (json['id'] as String?)?.trim() ?? '',
      name: (json['name'] as String?)?.trim() ?? '',
      phone: (json['phone'] as String?)?.trim() ?? '',
      email: (json['email'] as String?)?.trim() ?? '',
      vehicleType: (json['vehicleType'] as String?)?.trim() ?? '',
      licenseNumber: (json['licenseNumber'] as String?)?.trim() ?? '',
      isOnline: json['isOnline'] as bool? ?? false,
      currentStatus: (json['currentStatus'] as String?)?.trim() ?? '',
      activeOrdersCount: (json['activeOrdersCount'] as num?)?.toInt() ?? 0,
      assignedOrders: (json['assignedOrders'] as List<dynamic>? ?? const [])
          .map((item) => Order.fromJson(item as Map<String, dynamic>))
          .toList(growable: false),
      deliveryHistory: (json['deliveryHistory'] as List<dynamic>? ?? const [])
          .map((item) => Order.fromJson(item as Map<String, dynamic>))
          .toList(growable: false),
    );
  }
}