/// Tracks category loading state and the active category selection.
library;
import 'package:flutter/foundation.dart' hide Category;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:e_commerce_app_with_django/core/data/providers.dart';
import 'package:e_commerce_app_with_django/features/categories/domain/models/category.dart';
import 'package:e_commerce_app_with_django/features/categories/domain/repositories/category_repository.dart';

final categoryRepositoryProvider = Provider<CategoryRepository>(
  (ref) => ref.watch(defaultCategoryRepositoryProvider),
);

@immutable
/// Holds UI state for Category.
class CategoryState {
  const CategoryState({this.categories = const [], this.isLoading = false});

  final List<Category> categories;
  final bool isLoading;

  CategoryState copyWith({List<Category>? categories, bool? isLoading}) {
    return CategoryState(
      categories: categories ?? this.categories,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

/// Handles Category state and actions.
class CategoryNotifier extends StateNotifier<CategoryState> {
  CategoryNotifier(this._repository) : super(const CategoryState());

  final CategoryRepository _repository;

  Future<void> loadCategories() async {
    state = state.copyWith(isLoading: true);
    // Fetch once per load trigger and replace full list for predictable UI rendering.
    final categories = await _repository.getCategories();
    state = state.copyWith(categories: categories, isLoading: false);
  }
}

final categoryProvider = StateNotifierProvider<CategoryNotifier, CategoryState>(
  (ref) => CategoryNotifier(ref.watch(categoryRepositoryProvider)),
);
