/// Describes the data operations available for categories.
library;
import 'package:e_commerce_app_with_django/features/categories/domain/models/category.dart';

abstract class CategoryRepository {
  Future<List<Category>> getCategories();

  Future<Category> createCategory(Category category);

  Future<Category> updateCategory(Category category);

  Future<void> deleteCategory(String categoryId);
}