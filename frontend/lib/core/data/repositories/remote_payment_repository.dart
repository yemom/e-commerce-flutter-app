/// Reads payment data from a backend API backed by MongoDB.
library;

import 'package:e_commerce_app_with_django/core/data/datasources/commerce_api_data_source.dart';
import 'package:e_commerce_app_with_django/core/data/dtos/payment_dto.dart';
import 'package:e_commerce_app_with_django/features/payment/domain/models/payment.dart';
import 'package:e_commerce_app_with_django/features/payment/domain/repositories/payment_repository.dart';

class RemotePaymentRepository implements PaymentRepository {
  RemotePaymentRepository(this._dataSource);

  final CommerceApiDataSource _dataSource;

  @override
  Future<PaymentOption> addPaymentOption(PaymentOption option) async {
    final payload = await _dataSource.postItem(
      '/payment-options',
      body: PaymentOptionDto.fromDomain(option).toJson(),
    );
    return PaymentOptionDto.fromJson(payload).toDomain();
  }

  @override
  Future<List<PaymentOption>> getPaymentOptions() async {
    // Storefront reads enabled options from backend-configured payment methods.
    final payload = await _dataSource.getCollection('/payment-options');
    return payload
        .map(PaymentOptionDto.fromJson)
        .map((dto) => dto.toDomain())
        .toList();
  }

  @override
  Future<PaymentOption> setPaymentMethodEnabled({
    required String optionId,
    required bool isEnabled,
  }) async {
    final payload = await _dataSource.patchItem(
      '/payment-options/$optionId',
      body: {'isEnabled': isEnabled},
    );
    return PaymentOptionDto.fromJson(payload).toDomain();
  }

  @override
  Future<Payment> verifyPayment({
    required String paymentId,
    required String transactionReference,
  }) async {
    // Verification endpoint returns authoritative payment status and metadata.
    final payload = await _dataSource.postItem(
      '/payments/$paymentId/verify',
      body: {'transactionReference': transactionReference},
    );
    return PaymentDto.fromJson(payload).toDomain();
  }
}
