/// Converts raw order data into the app's order model.
library;

import 'package:e_commerce_app_with_django/core/data/dtos/payment_dto.dart';
import 'package:e_commerce_app_with_django/features/orders/domain/models/order.dart';

OrderStatus _orderStatusFromString(String value) {
  for (final status in OrderStatus.values) {
    if (status.name == value) {
      return status;
    }
  }
  return OrderStatus.confirmed;
}

class OrderItemDto {
  const OrderItemDto({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
  });

  final String productId;
  final String productName;
  final int quantity;
  final double unitPrice;

  factory OrderItemDto.fromJson(Map<String, dynamic> json) {
    return OrderItemDto(
      productId: json['productId'] as String,
      productName: json['productName'] as String,
      quantity: json['quantity'] as int,
      unitPrice: (json['unitPrice'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'productName': productName,
      'quantity': quantity,
      'unitPrice': unitPrice,
    };
  }

  OrderItem toDomain() {
    return OrderItem(
      productId: productId,
      productName: productName,
      quantity: quantity,
      unitPrice: unitPrice,
    );
  }

  factory OrderItemDto.fromDomain(OrderItem item) {
    return OrderItemDto(
      productId: item.productId,
      productName: item.productName,
      quantity: item.quantity,
      unitPrice: item.unitPrice,
    );
  }
}

class OrderDto {
  const OrderDto({
    required this.id,
    required this.branchId,
    required this.customerId,
    this.customerName = '',
    this.customerEmail = '',
    this.deliveryAddress = const <String, dynamic>{},
    required this.items,
    required this.status,
    required this.payment,
    required this.subtotal,
    required this.deliveryFee,
    required this.total,
    required this.createdAt,
    this.driverId = '',
    this.assignedDriver = const <String, dynamic>{},
    this.outForDeliveryAt,
    this.deliveredAt,
  });

  final String id;
  final String branchId;
  final String customerId;
  final String customerName;
  final String customerEmail;
  final Map<String, dynamic> deliveryAddress;
  final List<OrderItemDto> items;
  final OrderStatus status;
  final PaymentDto payment;
  final double subtotal;
  final double deliveryFee;
  final double total;
  final DateTime createdAt;
  final String driverId;
  final Map<String, dynamic> assignedDriver;
  final DateTime? outForDeliveryAt;
  final DateTime? deliveredAt;

  factory OrderDto.fromJson(Map<String, dynamic> json) {
    return OrderDto(
      id: json['id'] as String,
      branchId: json['branchId'] as String,
      customerId: json['customerId'] as String,
      customerName: (json['customerName'] as String?)?.trim() ?? '',
      customerEmail: (json['customerEmail'] as String?)?.trim() ?? '',
      deliveryAddress: Map<String, dynamic>.from(
        json['deliveryAddress'] as Map<String, dynamic>? ??
            const <String, dynamic>{},
      ),
      items: (json['items'] as List<dynamic>)
          .map((item) => OrderItemDto.fromJson(item as Map<String, dynamic>))
          .toList(),
      status: _orderStatusFromString(json['status'] as String),
      payment: PaymentDto.fromJson(json['payment'] as Map<String, dynamic>),
      subtotal: (json['subtotal'] as num).toDouble(),
      deliveryFee: (json['deliveryFee'] as num).toDouble(),
      total: (json['total'] as num).toDouble(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      driverId: (json['driverId'] as String?)?.trim() ?? '',
      assignedDriver: Map<String, dynamic>.from(
        json['assignedDriver'] as Map<String, dynamic>? ??
            const <String, dynamic>{},
      ),
      outForDeliveryAt: _asDateTime(json['outForDeliveryAt']),
      deliveredAt: _asDateTime(json['deliveredAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'branchId': branchId,
      'customerId': customerId,
      'customerName': customerName,
      'customerEmail': customerEmail,
      'deliveryAddress': deliveryAddress,
      'items': items.map((item) => item.toJson()).toList(),
      'status': status.name,
      'payment': payment.toJson(),
      'subtotal': subtotal,
      'deliveryFee': deliveryFee,
      'total': total,
      'createdAt': createdAt.toIso8601String(),
      'driverId': driverId,
      'assignedDriver': assignedDriver,
      'outForDeliveryAt': outForDeliveryAt?.toIso8601String(),
      'deliveredAt': deliveredAt?.toIso8601String(),
    };
  }

  Order toDomain() {
    return Order(
      id: id,
      branchId: branchId,
      customerId: customerId,
      customerName: customerName,
      customerEmail: customerEmail,
      deliveryAddress: deliveryAddress,
      items: items.map((item) => item.toDomain()).toList(),
      status: status,
      payment: payment.toDomain(),
      subtotal: subtotal,
      deliveryFee: deliveryFee,
      total: total,
      createdAt: createdAt,
      driverId: driverId,
      assignedDriver: assignedDriver,
      outForDeliveryAt: outForDeliveryAt,
      deliveredAt: deliveredAt,
    );
  }

  factory OrderDto.fromDomain(Order order) {
    return OrderDto(
      id: order.id,
      branchId: order.branchId,
      customerId: order.customerId,
      customerName: order.customerName,
      customerEmail: order.customerEmail,
      deliveryAddress: order.deliveryAddress,
      items: order.items.map(OrderItemDto.fromDomain).toList(),
      status: order.status,
      payment: PaymentDto.fromDomain(order.payment),
      subtotal: order.subtotal,
      deliveryFee: order.deliveryFee,
      total: order.total,
      createdAt: order.createdAt,
      driverId: order.driverId,
      assignedDriver: order.assignedDriver,
      outForDeliveryAt: order.outForDeliveryAt,
      deliveredAt: order.deliveredAt,
    );
  }

  static DateTime? _asDateTime(Object? value) {
    if (value is String && value.trim().isNotEmpty) {
      return DateTime.tryParse(value);
    }
    return null;
  }
}
