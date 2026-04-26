/// Reads payment data from assets and exposes it through the repository contract.
library;
import 'package:e_commerce_app_with_django/core/data/datasources/asset_commerce_data_source.dart';
import 'package:e_commerce_app_with_django/core/data/dtos/payment_dto.dart';
import 'package:e_commerce_app_with_django/features/payment/domain/models/payment.dart';
import 'package:e_commerce_app_with_django/features/payment/domain/repositories/payment_repository.dart';

class AssetPaymentRepository implements PaymentRepository {
  AssetPaymentRepository(this._dataSource);

  final AssetCommerceDataSource _dataSource;
  List<PaymentOptionDto>? _options;
  final List<PaymentDto> _payments = <PaymentDto>[];

  Future<List<PaymentOptionDto>> _paymentOptions() async {
    // Cached options mimic backend-managed payment settings.
    _options ??= await _dataSource.loadPaymentOptions();
    return _options!;
  }

  @override
  Future<PaymentOption> addPaymentOption(PaymentOption option) async {
    final options = await _paymentOptions();
    final dto = PaymentOptionDto.fromDomain(option);
    options.add(dto);
    return dto.toDomain();
  }

  @override
  Future<List<PaymentOption>> getPaymentOptions() async {
    // Keep behavior aligned with backend: expose enabled methods only.
    final options = await _paymentOptions();
    return options.where((option) => option.isEnabled).map((option) => option.toDomain()).toList();
  }

  @override
  Future<PaymentOption> setPaymentMethodEnabled({
    required String optionId,
    required bool isEnabled,
  }) async {
    final options = await _paymentOptions();
    final index = options.indexWhere((option) => option.id == optionId);
    final old = options[index];
    final updated = PaymentOptionDto(
      id: old.id,
      method: old.method,
      label: old.label,
      isEnabled: isEnabled,
    );
    options[index] = updated;
    return updated.toDomain();
  }

  @override
  Future<Payment> verifyPayment({
    required String paymentId,
    required String transactionReference,
  }) async {
    // Local verification creates/updates an in-memory payment record.
    final index = _payments.indexWhere((payment) => payment.id == paymentId);
    if (index == -1) {
      final created = PaymentDto(
        id: paymentId,
        orderId: 'order-$paymentId',
        method: PaymentMethod.telebirr,
        amount: 0,
        status: PaymentStatus.verified,
        transactionReference: transactionReference,
        createdAt: DateTime.now().toUtc(),
        verifiedAt: DateTime.now().toUtc(),
      );
      _payments.add(created);
      return created.toDomain();
    }

    final old = _payments[index];
    final updated = PaymentDto(
      id: old.id,
      orderId: old.orderId,
      method: old.method,
      amount: old.amount,
      status: PaymentStatus.verified,
      transactionReference: transactionReference,
      createdAt: old.createdAt,
      verifiedAt: DateTime.now().toUtc(),
    );
    _payments[index] = updated;
    return updated.toDomain();
  }
}