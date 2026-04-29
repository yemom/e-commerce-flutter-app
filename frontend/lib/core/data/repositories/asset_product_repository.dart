/// Reads product data from assets and exposes it through the repository contract.
library;
import 'package:e_commerce_app_with_django/core/data/datasources/asset_commerce_data_source.dart';
import 'package:e_commerce_app_with_django/core/data/dtos/product_dto.dart';
import 'package:e_commerce_app_with_django/features/products/domain/models/product.dart';
import 'package:e_commerce_app_with_django/features/products/domain/repositories/product_repository.dart';

class AssetProductRepository implements ProductRepository {
  AssetProductRepository(this._dataSource);

  final AssetCommerceDataSource _dataSource;
  List<ProductDto>? _cache;

  Future<List<ProductDto>> _products() async {
    // Product asset cache behaves like an in-memory mock database.
    _cache ??= await _dataSource.loadProducts();
    return _cache!;
  }

  @override
  Future<Product> getProduct(String productId) async {
    final list = await _products();
    final dto = list.firstWhere((item) => item.id == productId);
    return dto.toDomain();
  }

  @override
  Future<Product> addProduct(Product product) async {
    final list = await _products();
    final dto = ProductDto.fromDomain(product);
    list.add(dto);
    return dto.toDomain();
  }

  @override
  Future<void> assignProductToBranch({
    required String productId,
    required String branchId,
    required int quantity,
  }) async {
    final list = await _products();
    final index = list.indexWhere((dto) => dto.id == productId);
    if (index == -1) {
      return;
    }
    final item = list[index];
    // Update both branch membership and stock snapshot for selected branch.
    final branchIds = <String>{...item.branchIds, branchId}.toList();
    final stock = Map<String, int>.from(item.stockByBranch)..[branchId] = quantity;
    list[index] = item.copyWith(branchIds: branchIds, stockByBranch: stock);
  }

  @override
  Future<void> deleteProduct(String productId) async {
    final list = await _products();
    list.removeWhere((dto) => dto.id == productId);
  }

  @override
  Future<List<Product>> getProducts({
    String? branchId,
    String? categoryId,
    String? query,
  }) async {
    final normalizedQuery = query?.trim().toLowerCase();
    final list = await _products();

    // Match backend behavior: only available products are shown in storefront.
    return list.where((dto) {
      final matchesBranch = branchId == null || dto.branchIds.contains(branchId);
      final matchesCategory = categoryId == null || dto.categoryId == categoryId;
      final matchesQuery = normalizedQuery == null ||
          normalizedQuery.isEmpty ||
          dto.name.toLowerCase().contains(normalizedQuery) ||
          dto.description.toLowerCase().contains(normalizedQuery);
      return dto.isAvailable && matchesBranch && matchesCategory && matchesQuery;
    }).map((dto) => dto.toDomain()).toList();
  }

  @override
  Future<Product> updateProduct(Product product) async {
    final list = await _products();
    final index = list.indexWhere((dto) => dto.id == product.id);
    final dto = ProductDto.fromDomain(product);
    if (index == -1) {
      list.add(dto);
    } else {
      list[index] = dto;
    }
    return dto.toDomain();
  }
}

extension on ProductDto {
  // Lightweight local copy helper used by the asset repository update path.
  ProductDto copyWith({
    String? id,
    String? name,
    String? description,
    String? imageUrl,
    double? price,
    String? categoryId,
    List<String>? branchIds,
    Map<String, int>? stockByBranch,
    bool? isAvailable,
    List<String>? availableSizes,
    List<ProductColorOption>? availableColors,
    List<String>? imageUrls,
    String? selectedSize,
    ProductColorOption? selectedColor,
  }) {
    return ProductDto(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      price: price ?? this.price,
      categoryId: categoryId ?? this.categoryId,
      branchIds: branchIds ?? this.branchIds,
      stockByBranch: stockByBranch ?? this.stockByBranch,
      isAvailable: isAvailable ?? this.isAvailable,
      availableSizes: availableSizes ?? this.availableSizes,
      availableColors: availableColors ?? this.availableColors,
      imageUrls: imageUrls ?? this.imageUrls,
      selectedSize: selectedSize ?? this.selectedSize,
      selectedColor: selectedColor ?? this.selectedColor,
    );
  }
}