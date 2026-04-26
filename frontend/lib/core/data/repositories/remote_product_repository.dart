/// Reads product data from a backend API backed by MongoDB.
library;

import 'package:e_commerce_app_with_django/core/data/datasources/commerce_api_data_source.dart';
import 'package:e_commerce_app_with_django/core/data/dtos/product_dto.dart';
import 'package:e_commerce_app_with_django/features/products/domain/models/product.dart';
import 'package:e_commerce_app_with_django/features/products/domain/repositories/product_repository.dart';

class RemoteProductRepository implements ProductRepository {
  RemoteProductRepository(this._dataSource);

  final CommerceApiDataSource _dataSource;

  @override
  Future<Product> addProduct(Product product) async {
    // Convert domain model to DTO payload before sending over HTTP.
    final payload = await _dataSource.postItem(
      '/products',
      body: ProductDto.fromDomain(product).toJson(),
    );
    return ProductDto.fromJson(payload).toDomain();
  }

  @override
  Future<void> assignProductToBranch({
    required String productId,
    required String branchId,
    required int quantity,
  }) async {
    await _dataSource.patchItem(
      '/products/$productId/branches/$branchId',
      body: {'quantity': quantity},
    );
  }

  @override
  Future<void> deleteProduct(String productId) {
    return _dataSource.deleteItem('/products/$productId');
  }

  @override
  Future<List<Product>> getProducts({
    String? branchId,
    String? categoryId,
    String? query,
  }) async {
    // Query parameters mirror backend filter fields for branch/category/search.
    final payload = await _dataSource.getCollection(
      '/products',
      queryParameters: {
        'branchId': branchId,
        'categoryId': categoryId,
        'query': query,
      },
    );
    return payload
        .map(ProductDto.fromJson)
      // Map transport DTOs back into domain models used by UI/business logic.
        .map((dto) => dto.toDomain())
        .toList();
  }

  @override
  Future<Product> updateProduct(Product product) async {
    final payload = await _dataSource.patchItem(
      '/products/${product.id}',
      body: ProductDto.fromDomain(product).toJson(),
    );
    return ProductDto.fromJson(payload).toDomain();
  }
}
