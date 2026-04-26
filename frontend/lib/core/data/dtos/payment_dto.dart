/// Converts raw payment data into the app's payment models.
library;

import 'package:e_commerce_app_with_django/features/payment/domain/models/payment.dart';

PaymentStatus _paymentStatusFromString(String value) {
  return PaymentStatus.values.firstWhere((status) => status.name == value);
}

class PaymentOptionDto {
  const PaymentOptionDto({
    required this.id,
    required this.method,
    required this.label,
    required this.isEnabled,
    this.iconUrl,
  });

  final String id;
  final PaymentMethod method;
  final String label;
  final bool isEnabled;
  final String? iconUrl;

  factory PaymentOptionDto.fromJson(Map<String, dynamic> json) {
    return PaymentOptionDto(
      id: json['id'] as String,
      method: PaymentMethod.fromRaw(
        json['method'] as String,
        label: json['label'] as String?,
      ),
      label: json['label'] as String,
      isEnabled: json['isEnabled'] as bool,
      iconUrl: json['iconUrl'] as String?,
    );
  }

  PaymentOption toDomain() {
    return PaymentOption(
      id: id,
      method: method,
      label: label,
      isEnabled: isEnabled,
      iconUrl: iconUrl,
    );
  }

  factory PaymentOptionDto.fromDomain(PaymentOption option) {
    return PaymentOptionDto(
      id: option.id,
      method: option.method,
      label: option.label,
      isEnabled: option.isEnabled,
      iconUrl: option.iconUrl,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'method': method.name,
      'label': label,
      'isEnabled': isEnabled,
      'iconUrl': iconUrl,
    };
  }
}

class PaymentDto {
  const PaymentDto({
    required this.id,
    required this.orderId,
    required this.method,
    required this.amount,
    required this.status,
    required this.transactionReference,
    required this.createdAt,
    this.verifiedAt,
  });

  final String id;
  final String orderId;
  final PaymentMethod method;
  final double amount;
  final PaymentStatus status;
  final String transactionReference;
  final DateTime createdAt;
  final DateTime? verifiedAt;

  factory PaymentDto.fromJson(Map<String, dynamic> json) {
    return PaymentDto(
      id: json['id'] as String,
      orderId: json['orderId'] as String,
      method: PaymentMethod.fromRaw(
        json['method'] as String,
        label: json['methodLabel'] as String?,
      ),
      amount: (json['amount'] as num).toDouble(),
      status: _paymentStatusFromString(json['status'] as String),
      transactionReference: json['transactionReference'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      verifiedAt: json['verifiedAt'] == null
          ? null
          : DateTime.parse(json['verifiedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'orderId': orderId,
      'method': method.name,
      'methodLabel': method.label,
      'amount': amount,
      'status': status.name,
      'transactionReference': transactionReference,
      'createdAt': createdAt.toIso8601String(),
      'verifiedAt': verifiedAt?.toIso8601String(),
    };
  }

  Payment toDomain() {
    return Payment(
      id: id,
      orderId: orderId,
      method: method,
      amount: amount,
      status: status,
      transactionReference: transactionReference,
      createdAt: createdAt,
      verifiedAt: verifiedAt,
    );
  }

  factory PaymentDto.fromDomain(Payment payment) {
    return PaymentDto(
      id: payment.id,
      orderId: payment.orderId,
      method: payment.method,
      amount: payment.amount,
      status: payment.status,
      transactionReference: payment.transactionReference,
      createdAt: payment.createdAt,
      verifiedAt: payment.verifiedAt,
    );
  }
}
