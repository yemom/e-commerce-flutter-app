/// Defines payment methods, options, records, and verification states.
library;
import 'package:flutter/foundation.dart';

@immutable
class PaymentMethod {
  const PaymentMethod._(this.id, this.label);

  const PaymentMethod.custom({required this.id, required this.label});

  static const PaymentMethod telebirr = PaymentMethod._('telebirr', 'Telebirr');
  static const PaymentMethod cbe = PaymentMethod._('cbe', 'CBE');
  static const PaymentMethod cashOnDelivery = PaymentMethod._('cashOnDelivery', 'Cash on delivery');

  static const List<PaymentMethod> defaults = [telebirr, cbe, cashOnDelivery];
  static const List<PaymentMethod> values = defaults;

  final String id;
  final String label;

  String get name => id;

  bool get isCustom => !defaults.any((method) => method.id == id);

  static PaymentMethod fromRaw(String value, {String? label}) {
    var normalized = value.trim();
    // Backward compatibility: old data might still use the legacy "chapa" id.
    if (normalized == 'chapa') {
      normalized = cbe.id;
    }

    for (final method in defaults) {
      if (method.id == normalized) {
        return method;
      }
    }

    final resolvedLabel = label?.trim().isNotEmpty == true ? label!.trim() : _humanizePaymentId(normalized);
    return PaymentMethod.custom(id: normalized, label: resolvedLabel);
  }

  @override
  bool operator ==(Object other) => identical(this, other) || other is PaymentMethod && other.id == id;

  @override
  int get hashCode => id.hashCode;
}

enum PaymentStatus {
  pending,
  verified,
  failed,
}

PaymentStatus _paymentStatusFromString(String value) {
  return PaymentStatus.values.firstWhere((status) => status.name == value);
}

String _humanizePaymentId(String value) {
  final withSpaces = value
      .replaceAllMapped(RegExp(r'([a-z])([A-Z])'), (match) => '${match.group(1)} ${match.group(2)}')
      .replaceAll(RegExp(r'[_\-]+'), ' ')
      .trim();

  if (withSpaces.isEmpty) {
    return 'Payment';
  }

  return withSpaces
      .split(RegExp(r'\s+'))
      .map((segment) => segment.isEmpty ? segment : '${segment[0].toUpperCase()}${segment.substring(1)}')
      .join(' ');
}

@immutable
class PaymentOption {
  const PaymentOption({
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

  PaymentOption copyWith({
    String? id,
    PaymentMethod? method,
    String? label,
    bool? isEnabled,
    String? iconUrl,
  }) {
    return PaymentOption(
      id: id ?? this.id,
      method: method ?? this.method,
      label: label ?? this.label,
      isEnabled: isEnabled ?? this.isEnabled,
      iconUrl: iconUrl ?? this.iconUrl,
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

  factory PaymentOption.fromJson(Map<String, dynamic> json) {
    return PaymentOption(
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

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is PaymentOption &&
            runtimeType == other.runtimeType &&
            id == other.id &&
            method == other.method &&
            label == other.label &&
            isEnabled == other.isEnabled &&
            iconUrl == other.iconUrl;
  }

  @override
  int get hashCode => Object.hash(id, method, label, isEnabled, iconUrl);
}

@immutable
class Payment {
  const Payment({
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

  Payment copyWith({
    String? id,
    String? orderId,
    PaymentMethod? method,
    double? amount,
    PaymentStatus? status,
    String? transactionReference,
    DateTime? createdAt,
    DateTime? verifiedAt,
  }) {
    return Payment(
      id: id ?? this.id,
      orderId: orderId ?? this.orderId,
      method: method ?? this.method,
      amount: amount ?? this.amount,
      status: status ?? this.status,
      transactionReference: transactionReference ?? this.transactionReference,
      createdAt: createdAt ?? this.createdAt,
      verifiedAt: verifiedAt ?? this.verifiedAt,
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

  factory Payment.fromJson(Map<String, dynamic> json) {
    return Payment(
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
      verifiedAt: json['verifiedAt'] == null ? null : DateTime.parse(json['verifiedAt'] as String),
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is Payment &&
            runtimeType == other.runtimeType &&
            id == other.id &&
            orderId == other.orderId &&
            method == other.method &&
            amount == other.amount &&
            status == other.status &&
            transactionReference == other.transactionReference &&
            createdAt == other.createdAt &&
            verifiedAt == other.verifiedAt;
  }

  @override
  int get hashCode => Object.hash(
        id,
        orderId,
        method,
        amount,
        status,
        transactionReference,
        createdAt,
        verifiedAt,
      );
}