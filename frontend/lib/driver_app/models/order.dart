class OrderItem {
  OrderItem({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
  });

  final String productId;
  final String productName;
  final int quantity;
  final double unitPrice;

  double get lineTotal => quantity * unitPrice;

  factory OrderItem.fromJson(Map<String, dynamic> json) => OrderItem(
    productId: json['productId'] as String,
    productName: json['productName'] as String,
    quantity: (json['quantity'] as num).toInt(),
    unitPrice: (json['unitPrice'] as num).toDouble(),
  );
}

class Order {
  Order({
    required this.id,
    required this.branchId,
    required this.customerId,
    required this.customerName,
    required this.customerEmail,
    required this.deliveryAddress,
    required this.status,
    required this.items,
    required this.subtotal,
    required this.deliveryFee,
    required this.total,
    this.createdAt,
    this.outForDeliveryAt,
    this.deliveredAt,
  });

  final String id;
  final String branchId;
  final String customerId;
  final String customerName;
  final String customerEmail;
  final Map<String, dynamic> deliveryAddress;
  final String status;
  final List<OrderItem> items;
  final double subtotal;
  final double deliveryFee;
  final double total;
  final DateTime? createdAt;
  final DateTime? outForDeliveryAt;
  final DateTime? deliveredAt;

  String get statusLabel {
    switch (status) {
      case 'assigned':
        return 'Assigned';
      case 'out_for_delivery':
        return 'Out for delivery';
      case 'delivered':
        return 'Delivered';
      case 'confirmed':
        return 'Confirmed';
      case 'pending':
        return 'Pending';
      default:
        return status;
    }
  }

  String get addressLine {
    final line1 = deliveryAddress['line1']?.toString().trim() ?? '';
    if (line1.isNotEmpty) {
      return line1;
    }
    final city = deliveryAddress['city']?.toString().trim() ?? '';
    return city;
  }

  factory Order.fromJson(Map<String, dynamic> json) => Order(
    id: json['id'] as String,
    branchId: (json['branchId'] as String?)?.trim() ?? '',
    customerId: (json['customerId'] as String?)?.trim() ?? '',
    customerName: (json['customerName'] as String?)?.trim() ?? '',
    customerEmail: (json['customerEmail'] as String?)?.trim() ?? '',
    deliveryAddress: Map<String, dynamic>.from(
      json['deliveryAddress'] as Map<String, dynamic>? ??
          const <String, dynamic>{},
    ),
    status: (json['status'] as String?)?.trim() ?? 'assigned',
    items: (json['items'] as List<dynamic>? ?? const <dynamic>[])
        .map((e) => OrderItem.fromJson(e as Map<String, dynamic>))
        .toList(),
    subtotal: (json['subtotal'] as num?)?.toDouble() ?? 0,
    deliveryFee: (json['deliveryFee'] as num?)?.toDouble() ?? 0,
    total: (json['total'] as num?)?.toDouble() ?? 0,
    createdAt: _asDateTime(json['createdAt']),
    outForDeliveryAt: _asDateTime(json['outForDeliveryAt']),
    deliveredAt: _asDateTime(json['deliveredAt']),
  );

  static DateTime? _asDateTime(Object? value) {
    if (value is String && value.trim().isNotEmpty) {
      return DateTime.tryParse(value);
    }
    return null;
  }
}
