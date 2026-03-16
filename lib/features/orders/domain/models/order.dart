/// Defines orders, order items, and order lifecycle states.
library;
import 'package:flutter/foundation.dart';

import 'package:e_commerce_app_with_django/features/payment/domain/models/payment.dart';

enum OrderStatus {
  pending,
  confirmed,
  shipped,
  delivered,
}

OrderStatus _orderStatusFromString(String value) {
  return OrderStatus.values.firstWhere((status) => status.name == value);
}

@immutable
class OrderItem {
  const OrderItem({
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
  });

  final String productId;
  final String productName;
  final int quantity;
  final double unitPrice;

  OrderItem copyWith({
    String? productId,
    String? productName,
    int? quantity,
    double? unitPrice,
  }) {
    return OrderItem(
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      quantity: quantity ?? this.quantity,
      unitPrice: unitPrice ?? this.unitPrice,
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

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      productId: json['productId'] as String,
      productName: json['productName'] as String,
      quantity: json['quantity'] as int,
      unitPrice: (json['unitPrice'] as num).toDouble(),
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is OrderItem &&
            runtimeType == other.runtimeType &&
            productId == other.productId &&
            productName == other.productName &&
            quantity == other.quantity &&
            unitPrice == other.unitPrice;
  }

  @override
  int get hashCode => Object.hash(productId, productName, quantity, unitPrice);
}

@immutable
class Order {
  const Order({
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
  final List<OrderItem> items;
  final OrderStatus status;
  final Payment payment;
  final double subtotal;
  final double deliveryFee;
  final double total;
  final DateTime createdAt;

  Order copyWith({
    String? id,
    String? branchId,
    String? customerId,
    List<OrderItem>? items,
    OrderStatus? status,
    Payment? payment,
    double? subtotal,
    double? deliveryFee,
    double? total,
    DateTime? createdAt,
  }) {
    return Order(
      id: id ?? this.id,
      branchId: branchId ?? this.branchId,
      customerId: customerId ?? this.customerId,
      items: items ?? this.items,
      status: status ?? this.status,
      payment: payment ?? this.payment,
      subtotal: subtotal ?? this.subtotal,
      deliveryFee: deliveryFee ?? this.deliveryFee,
      total: total ?? this.total,
      createdAt: createdAt ?? this.createdAt,
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

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'] as String,
      branchId: json['branchId'] as String,
      customerId: json['customerId'] as String,
      items: (json['items'] as List<dynamic>)
          .map((item) => OrderItem.fromJson(item as Map<String, dynamic>))
          .toList(),
      status: _orderStatusFromString(json['status'] as String),
      payment: Payment.fromJson(json['payment'] as Map<String, dynamic>),
      subtotal: (json['subtotal'] as num).toDouble(),
      deliveryFee: (json['deliveryFee'] as num).toDouble(),
      total: (json['total'] as num).toDouble(),
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is Order &&
            runtimeType == other.runtimeType &&
            id == other.id &&
            branchId == other.branchId &&
            customerId == other.customerId &&
            listEquals(items, other.items) &&
            status == other.status &&
            payment == other.payment &&
            subtotal == other.subtotal &&
            deliveryFee == other.deliveryFee &&
            total == other.total &&
            createdAt == other.createdAt;
  }

  @override
  int get hashCode => Object.hash(
        id,
        branchId,
        customerId,
        Object.hashAll(items),
        status,
        payment,
        subtotal,
        deliveryFee,
        total,
        createdAt,
      );
}