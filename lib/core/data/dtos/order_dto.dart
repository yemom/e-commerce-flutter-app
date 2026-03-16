/// Converts raw order data into the app's order model.
library;
import 'package:e_commerce_app_with_django/core/data/dtos/payment_dto.dart';
import 'package:e_commerce_app_with_django/features/orders/domain/models/order.dart';

OrderStatus _orderStatusFromString(String value) {
  return OrderStatus.values.firstWhere((status) => status.name == value);
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
    required this.items,
    required this.status,
    required this.payment,
    required this.subtotal,
    required this.deliveryFee,
    required this.total,
    required this.createdAt,
  });

  final String id;
  final String branchId;
  final String customerId;
  final List<OrderItemDto> items;
  final OrderStatus status;
  final PaymentDto payment;
  final double subtotal;
  final double deliveryFee;
  final double total;
  final DateTime createdAt;

  factory OrderDto.fromJson(Map<String, dynamic> json) {
    return OrderDto(
      id: json['id'] as String,
      branchId: json['branchId'] as String,
      customerId: json['customerId'] as String,
      items: (json['items'] as List<dynamic>)
          .map((item) => OrderItemDto.fromJson(item as Map<String, dynamic>))
          .toList(),
      status: _orderStatusFromString(json['status'] as String),
      payment: PaymentDto.fromJson(json['payment'] as Map<String, dynamic>),
      subtotal: (json['subtotal'] as num).toDouble(),
      deliveryFee: (json['deliveryFee'] as num).toDouble(),
      total: (json['total'] as num).toDouble(),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'branchId': branchId,
      'customerId': customerId,
      'items': items.map((item) => item.toJson()).toList(),
      'status': status.name,
      'payment': payment.toJson(),
      'subtotal': subtotal,
      'deliveryFee': deliveryFee,
      'total': total,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  Order toDomain() {
    return Order(
      id: id,
      branchId: branchId,
      customerId: customerId,
      items: items.map((item) => item.toDomain()).toList(),
      status: status,
      payment: payment.toDomain(),
      subtotal: subtotal,
      deliveryFee: deliveryFee,
      total: total,
      createdAt: createdAt,
    );
  }

  factory OrderDto.fromDomain(Order order) {
    return OrderDto(
      id: order.id,
      branchId: order.branchId,
      customerId: order.customerId,
      items: order.items.map(OrderItemDto.fromDomain).toList(),
      status: order.status,
      payment: PaymentDto.fromDomain(order.payment),
      subtotal: order.subtotal,
      deliveryFee: order.deliveryFee,
      total: order.total,
      createdAt: order.createdAt,
    );
  }
}