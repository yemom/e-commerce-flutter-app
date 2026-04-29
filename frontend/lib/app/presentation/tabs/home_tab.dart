library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:e_commerce_app_with_django/app/providers/app_flow_providers.dart';
import 'package:e_commerce_app_with_django/app/services/app_navigation_service.dart';
import 'package:e_commerce_app_with_django/app/presentation/widgets/app_status_screen.dart';
import 'package:e_commerce_app_with_django/features/auth/presentation/providers/auth_provider.dart';
import 'package:e_commerce_app_with_django/features/cart/presentation/providers/cart_provider.dart';
import 'package:e_commerce_app_with_django/features/categories/presentation/providers/category_provider.dart';
import 'package:e_commerce_app_with_django/features/categories/presentation/screens/category_screen.dart';
import 'package:e_commerce_app_with_django/features/branches/presentation/providers/branch_provider.dart';
import 'package:e_commerce_app_with_django/features/products/presentation/providers/product_provider.dart';
import 'package:e_commerce_app_with_django/features/products/presentation/screens/product_detail_screen.dart';
import 'package:e_commerce_app_with_django/features/products/presentation/screens/product_list_screen.dart';

class HomeTab extends ConsumerWidget {
  const HomeTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final branchState = ref.watch(branchProvider);
    final productState = ref.watch(productProvider);
    final categoryState = ref.watch(categoryProvider);
    final session = authState.session;

    if (session == null) {
      return const AppLoadingScreen();
    }

    final navigation = ref.read(appNavigationServiceProvider);
    final productNotifier = ref.read(productProvider.notifier);

    return ProductListScreen(
      products: productState.products,
      branches: branchState.branches,
      categories: categoryState.categories,
      selectedBranchId: productState.selectedBranchId,
      selectedCategoryId: productState.selectedCategoryId,
      searchQuery: productState.searchQuery,
      userName: session.userName,
      onSearchChanged: (value) => productNotifier.searchProducts(value),
      onBranchChanged: (value) async {
        if (value == null) {
          await productNotifier.loadAllProducts();
          return;
        }

        await ref.read(branchProvider.notifier).selectBranch(value);
        await productNotifier.loadProducts(branchId: value);
      },
      onCategoryChanged: (value) => productNotifier.filterByCategory(value),
      onSeeAll: () async {
        await productNotifier.searchProducts('');
        await productNotifier.filterByCategory(null);
        await productNotifier.loadAllProducts();
      },
      onLogout: () => ref.read(authProvider.notifier).logout(),
      onOpenProfile: () {
        ref.read(storefrontTabIndexProvider.notifier).state = 3;
      },
      onOpenCategoryScreen: () {
        navigation.push(
          CategoryScreen(
            categories: categoryState.categories,
            selectedCategoryId: productState.selectedCategoryId,
            onBackToHome: navigation.pop,
            onCategorySelected: (categoryId) {
              productNotifier.filterByCategory(categoryId);
              navigation.pop();
            },
          ),
        );
      },
      onProductSelected: (product) {
        navigation.push(
          ProductDetailScreen(
            product: product,
            onAddToCart: ref.read(cartProvider.notifier).addProduct,
            onFetchProduct: (productId) => ref.read(productRepositoryProvider).getProduct(productId),
          ),
        );
      },
    );
  }
}
