/// Tracks the product catalog, filters, search, and loading state.
library;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:e_commerce_app_with_django/core/data/providers.dart';
import 'package:e_commerce_app_with_django/features/products/domain/models/product.dart';
import 'package:e_commerce_app_with_django/features/products/domain/repositories/product_repository.dart';

final productRepositoryProvider = Provider<ProductRepository>(
  (ref) => ref.watch(defaultProductRepositoryProvider),
);

@immutable
/// Holds UI state for Product.
class ProductState {
  const ProductState({
    this.products = const [],
    this.selectedBranchId,
    this.selectedCategoryId,
    this.searchQuery = '',
    this.isLoading = false,
  });

  final List<Product> products;
  final String? selectedBranchId;
  final String? selectedCategoryId;
  final String searchQuery;
  final bool isLoading;

  ProductState copyWith({
    List<Product>? products,
    String? selectedBranchId,
    String? selectedCategoryId,
    String? searchQuery,
    bool? isLoading,
    bool clearSelectedCategory = false,
  }) {
    // clearSelectedCategory is used when branch changes to avoid stale filters.
    return ProductState(
      products: products ?? this.products,
      selectedBranchId: selectedBranchId ?? this.selectedBranchId,
      selectedCategoryId:
          clearSelectedCategory ? null : (selectedCategoryId ?? this.selectedCategoryId),
      searchQuery: searchQuery ?? this.searchQuery,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

/// Handles Product state and actions.
class ProductNotifier extends StateNotifier<ProductState> {
  ProductNotifier(this._repository) : super(const ProductState());

  final ProductRepository _repository;

  Future<void> loadProducts({required String branchId}) async {
    // Changing branches resets category and search so the catalog stays consistent with the branch context.
    state = state.copyWith(
      isLoading: true,
      selectedBranchId: branchId,
      clearSelectedCategory: true,
      searchQuery: '',
    );
    final products = await _repository.getProducts(branchId: branchId);
    state = state.copyWith(products: products, isLoading: false);
  }

  Future<void> loadAllProducts() async {
    // Load full catalog across branches from MongoDB.
    state = state.copyWith(
      isLoading: true,
      selectedBranchId: null,
      clearSelectedCategory: true,
      searchQuery: '',
    );
    final products = await _repository.getProducts();
    state = state.copyWith(products: products, isLoading: false);
  }

  Future<void> filterByCategory(String? categoryId) async {
    // Category filtering keeps the current branch and search query applied.
    final products = await _repository.getProducts(
      branchId: state.selectedBranchId,
      categoryId: categoryId,
      query: state.searchQuery.isEmpty ? null : state.searchQuery,
    );
    state = state.copyWith(
      products: products,
      selectedCategoryId: categoryId,
    );
  }

  Future<void> searchProducts(String query) async {
    // Search is always scoped to the currently active branch and category filters.
    final products = await _repository.getProducts(
      branchId: state.selectedBranchId,
      categoryId: state.selectedCategoryId,
      query: query,
    );
    state = state.copyWith(products: products, searchQuery: query);
  }
}

final productProvider = StateNotifierProvider<ProductNotifier, ProductState>(
  (ref) => ProductNotifier(ref.watch(productRepositoryProvider)),
);
