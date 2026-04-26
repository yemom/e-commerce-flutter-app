/// Reads order data from a backend API backed by MongoDB.
library;

import 'package:e_commerce_app_with_django/core/data/datasources/commerce_api_data_source.dart';
import 'package:e_commerce_app_with_django/core/data/dtos/order_dto.dart';
import 'package:e_commerce_app_with_django/features/orders/domain/models/order.dart';
import 'package:e_commerce_app_with_django/features/orders/domain/repositories/order_repository.dart';
import 'package:e_commerce_app_with_django/features/payment/domain/models/payment.dart';

class RemoteOrderRepository implements OrderRepository {
  RemoteOrderRepository(this._dataSource);

  final CommerceApiDataSource _dataSource;

  @override
  Future<Order> confirmOrder(Order order) async {
    // Order creation uses DTO normalization so backend receives consistent field names.
    final payload = await _dataSource.postItem(
      '/orders',
      body: OrderDto.fromDomain(order).toJson(),
    );
    return OrderDto.fromJson(payload).toDomain();
  }

  @override
  Future<List<Order>> getOrders({String? branchId, OrderStatus? status}) async {
    // Backend accepts status by enum name string.
    final payload = await _dataSource.getCollection(
      '/orders',
      queryParameters: {'branchId': branchId, 'status': status?.name},
    );
    return payload.map(OrderDto.fromJson).map((dto) => dto.toDomain()).toList();
  }

  @override
  Future<Order> updateOrderStatus({
    required String orderId,
    required OrderStatus status,
  }) async {
    final payload = await _dataSource.patchItem(
      '/orders/$orderId',
      body: {'status': status.name},
    );
    return OrderDto.fromJson(payload).toDomain();
  }

  @override
  Future<Order> verifyOrderPayment({
    required String orderId,
    required PaymentStatus paymentStatus,
  }) async {
    // Payment status sync happens through order payment endpoint.
    final payload = await _dataSource.patchItem(
      '/orders/$orderId/payment',
      body: {'paymentStatus': paymentStatus.name},
    );
    return OrderDto.fromJson(payload).toDomain();
  }
}
