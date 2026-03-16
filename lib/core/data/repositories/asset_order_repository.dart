/// Reads order data from assets and exposes it through the repository contract.
library;
import 'package:e_commerce_app_with_django/core/data/datasources/asset_commerce_data_source.dart';
import 'package:e_commerce_app_with_django/core/data/dtos/order_dto.dart';
import 'package:e_commerce_app_with_django/core/data/dtos/payment_dto.dart';
import 'package:e_commerce_app_with_django/features/orders/domain/models/order.dart';
import 'package:e_commerce_app_with_django/features/orders/domain/repositories/order_repository.dart';
import 'package:e_commerce_app_with_django/features/payment/domain/models/payment.dart';

class AssetOrderRepository implements OrderRepository {
  AssetOrderRepository(this._dataSource);

  final AssetCommerceDataSource _dataSource;
  List<OrderDto>? _cache;

  Future<List<OrderDto>> _orders() async {
    _cache ??= await _dataSource.loadOrders();
    return _cache!;
  }

  @override
  Future<Order> confirmOrder(Order order) async {
    final list = await _orders();
    final confirmed = order.copyWith(status: OrderStatus.confirmed);
    final dto = OrderDto.fromDomain(confirmed);
    list.removeWhere((item) => item.id == confirmed.id);
    list.insert(0, dto);
    return dto.toDomain();
  }

  @override
  Future<List<Order>> getOrders({String? branchId, OrderStatus? status}) async {
    final list = await _orders();
    return list.where((dto) {
      final byBranch = branchId == null || dto.branchId == branchId;
      final byStatus = status == null || dto.status == status;
      return byBranch && byStatus;
    }).map((dto) => dto.toDomain()).toList();
  }

  @override
  Future<Order> updateOrderStatus({
    required String orderId,
    required OrderStatus status,
  }) async {
    final list = await _orders();
    final index = list.indexWhere((dto) => dto.id == orderId);
    if (index == -1) {
      final fallback = list.first;
      final created = OrderDto(
        id: orderId,
        branchId: fallback.branchId,
        customerId: fallback.customerId,
        items: fallback.items,
        status: status,
        payment: fallback.payment,
        subtotal: fallback.subtotal,
        deliveryFee: fallback.deliveryFee,
        total: fallback.total,
        createdAt: DateTime.now().toUtc(),
      );
      list.add(created);
      return created.toDomain();
    }
    final item = list[index];
    final updated = OrderDto(
      id: item.id,
      branchId: item.branchId,
      customerId: item.customerId,
      items: item.items,
      status: status,
      payment: item.payment,
      subtotal: item.subtotal,
      deliveryFee: item.deliveryFee,
      total: item.total,
      createdAt: item.createdAt,
    );
    list[index] = updated;
    return updated.toDomain();
  }

  @override
  Future<Order> verifyOrderPayment({
    required String orderId,
    required PaymentStatus paymentStatus,
  }) async {
    final list = await _orders();
    final index = list.indexWhere((dto) => dto.id == orderId);
    final item = list[index];
    final updated = OrderDto(
      id: item.id,
      branchId: item.branchId,
      customerId: item.customerId,
      items: item.items,
      status: item.status,
      payment: PaymentDto(
        id: item.payment.id,
        orderId: item.payment.orderId,
        method: item.payment.method,
        amount: item.payment.amount,
        status: paymentStatus,
        transactionReference: item.payment.transactionReference,
        createdAt: item.payment.createdAt,
        verifiedAt: paymentStatus == PaymentStatus.verified ? DateTime.now().toUtc() : null,
      ),
      subtotal: item.subtotal,
      deliveryFee: item.deliveryFee,
      total: item.total,
      createdAt: item.createdAt,
    );
    list[index] = updated;
    return updated.toDomain();
  }
}