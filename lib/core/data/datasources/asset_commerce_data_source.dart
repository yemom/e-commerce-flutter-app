/// Loads branch, category, product, order, and payment data from assets.
library;
import 'dart:convert';

import 'package:flutter/services.dart';

import 'package:e_commerce_app_with_django/core/data/dtos/branch_dto.dart';
import 'package:e_commerce_app_with_django/core/data/dtos/category_dto.dart';
import 'package:e_commerce_app_with_django/core/data/dtos/order_dto.dart';
import 'package:e_commerce_app_with_django/core/data/dtos/payment_dto.dart';
import 'package:e_commerce_app_with_django/core/data/dtos/product_dto.dart';

class AssetCommerceDataSource {
  const AssetCommerceDataSource();

  Future<List<BranchDto>> loadBranches() => _loadList(
        'assets/data/branches.json',
        (json) => BranchDto.fromJson(json),
      );

  Future<List<CategoryDto>> loadCategories() => _loadList(
        'assets/data/categories.json',
        (json) => CategoryDto.fromJson(json),
      );

  Future<List<ProductDto>> loadProducts() => _loadList(
        'assets/data/products.json',
        (json) => ProductDto.fromJson(json),
      );

  Future<List<PaymentOptionDto>> loadPaymentOptions() => _loadList(
        'assets/data/payment_options.json',
        (json) => PaymentOptionDto.fromJson(json),
      );

  Future<List<OrderDto>> loadOrders() => _loadList(
        'assets/data/orders.json',
        (json) => OrderDto.fromJson(json),
      );

  Future<List<T>> _loadList<T>(
    String path,
    T Function(Map<String, dynamic> json) fromJson,
  ) async {
    final content = await rootBundle.loadString(path);
    final decoded = jsonDecode(content) as List<dynamic>;
    return decoded
        .map((item) => fromJson(item as Map<String, dynamic>))
        .toList();
  }
}