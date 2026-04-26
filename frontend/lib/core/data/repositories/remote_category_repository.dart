/// Reads category data from a backend API backed by MongoDB.
library;

import 'package:e_commerce_app_with_django/core/data/datasources/commerce_api_data_source.dart';
import 'package:e_commerce_app_with_django/core/data/dtos/category_dto.dart';
import 'package:e_commerce_app_with_django/features/categories/domain/models/category.dart';
import 'package:e_commerce_app_with_django/features/categories/domain/repositories/category_repository.dart';

class RemoteCategoryRepository implements CategoryRepository {
  RemoteCategoryRepository(this._dataSource);

  final CommerceApiDataSource _dataSource;

  @override
  Future<Category> createCategory(Category category) async {
    final payload = await _dataSource.postItem(
      '/categories',
      body: CategoryDto.fromDomain(category).toJson(),
    );
    return CategoryDto.fromJson(payload).toDomain();
  }

  @override
  Future<void> deleteCategory(String categoryId) {
    return _dataSource.deleteItem('/categories/$categoryId');
  }

  @override
  Future<List<Category>> getCategories() async {
    final payload = await _dataSource.getCollection('/categories');
    return payload
        .map(CategoryDto.fromJson)
        .map((dto) => dto.toDomain())
        .toList();
  }

  @override
  Future<Category> updateCategory(Category category) async {
    // PATCH by category id keeps immutable ids stable while updating mutable fields.
    final payload = await _dataSource.patchItem(
      '/categories/${category.id}',
      body: CategoryDto.fromDomain(category).toJson(),
    );
    return CategoryDto.fromJson(payload).toDomain();
  }
}
