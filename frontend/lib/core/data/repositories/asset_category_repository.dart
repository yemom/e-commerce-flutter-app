/// Reads category data from assets and exposes it through the repository contract.
library;
import 'package:e_commerce_app_with_django/core/data/datasources/asset_commerce_data_source.dart';
import 'package:e_commerce_app_with_django/core/data/dtos/category_dto.dart';
import 'package:e_commerce_app_with_django/features/categories/domain/models/category.dart';
import 'package:e_commerce_app_with_django/features/categories/domain/repositories/category_repository.dart';

class AssetCategoryRepository implements CategoryRepository {
  AssetCategoryRepository(this._dataSource);

  final AssetCommerceDataSource _dataSource;
  List<CategoryDto>? _cache;

  Future<List<CategoryDto>> _categories() async {
    // Keep categories in-memory for local/offline development flows.
    _cache ??= await _dataSource.loadCategories();
    return _cache!;
  }

  @override
  Future<Category> createCategory(Category category) async {
    final list = await _categories();
    final dto = CategoryDto.fromDomain(category);
    list.add(dto);
    return dto.toDomain();
  }

  @override
  Future<void> deleteCategory(String categoryId) async {
    final list = await _categories();
    list.removeWhere((item) => item.id == categoryId);
  }

  @override
  Future<List<Category>> getCategories() async {
    final list = await _categories();
    return list.map((dto) => dto.toDomain()).toList();
  }

  @override
  Future<Category> updateCategory(Category category) async {
    final list = await _categories();
    final dto = CategoryDto.fromDomain(category);
    final index = list.indexWhere((item) => item.id == category.id);
    // Upsert behavior mirrors backend update semantics for local mode.
    if (index == -1) {
      list.add(dto);
    } else {
      list[index] = dto;
    }
    return dto.toDomain();
  }
}