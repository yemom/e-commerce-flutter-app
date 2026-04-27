library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:e_commerce_app_with_django/core/data/providers.dart';
import 'package:e_commerce_app_with_django/features/admin/presentation/providers/admin_settings_provider.dart';
import 'package:e_commerce_app_with_django/features/auth/presentation/providers/auth_provider.dart';
import 'package:e_commerce_app_with_django/features/branches/domain/models/branch.dart';
import 'package:e_commerce_app_with_django/features/branches/presentation/providers/branch_provider.dart';
import 'package:e_commerce_app_with_django/features/categories/domain/models/category.dart';
import 'package:e_commerce_app_with_django/features/categories/presentation/providers/category_provider.dart';
import 'package:e_commerce_app_with_django/features/payment/domain/models/payment.dart';
import 'package:e_commerce_app_with_django/features/payment/presentation/providers/payment_provider.dart';
import 'package:e_commerce_app_with_django/features/products/domain/models/product.dart';
import 'package:e_commerce_app_with_django/features/products/presentation/providers/product_provider.dart';

final adminPortalServiceProvider = Provider<AdminPortalService>(
  (ref) => AdminPortalService(ref),
);

class AdminPortalService {
  AdminPortalService(this._ref);

  final Ref _ref;

  Future<void> addCategory({
    required String name,
    required String description,
    required String imageUrl,
  }) async {
    await _ref
        .read(adminSettingsProvider.notifier)
        .addCategory(name: name, description: description, imageUrl: imageUrl);
    await _ref.read(categoryProvider.notifier).loadCategories();
  }

  Future<void> toggleCategory(String categoryId, bool isActive) async {
    await _ref
        .read(adminSettingsProvider.notifier)
        .toggleCategory(categoryId, isActive);
    await _ref.read(categoryProvider.notifier).loadCategories();
  }

  Future<Category?> fetchCategory(String categoryId) {
    return _ref
        .read(adminSettingsProvider.notifier)
        .fetchCategoryById(categoryId);
  }

  Future<void> updateCategory({
    required String categoryId,
    required String name,
    required String description,
    required String imageUrl,
  }) async {
    await _ref
        .read(adminSettingsProvider.notifier)
        .updateCategory(
          categoryId: categoryId,
          name: name,
          description: description,
          imageUrl: imageUrl,
        );
    await _ref.read(categoryProvider.notifier).loadCategories();
  }

  Future<void> deleteCategory(String categoryId) async {
    await _ref.read(adminSettingsProvider.notifier).deleteCategory(categoryId);
    await _ref.read(categoryProvider.notifier).loadCategories();
  }

  Future<void> addPaymentOption({
    required String label,
    String? iconUrl,
  }) async {
    await _ref
        .read(adminSettingsProvider.notifier)
        .addPaymentOption(label: label, iconUrl: iconUrl);
    await _ref.read(paymentProvider.notifier).loadPaymentOptions();
  }

  Future<PaymentOption?> fetchPaymentOption(String optionId) {
    return _ref
        .read(adminSettingsProvider.notifier)
        .fetchPaymentOptionById(optionId);
  }

  Future<void> updatePaymentOption({
    required String optionId,
    required String label,
    String? iconUrl,
  }) async {
    await _ref
        .read(adminSettingsProvider.notifier)
        .updatePaymentOption(
          optionId: optionId,
          label: label,
          iconUrl: iconUrl,
        );
    await _ref.read(paymentProvider.notifier).loadPaymentOptions();
  }

  Future<void> deletePaymentOption(String optionId) async {
    await _ref
        .read(adminSettingsProvider.notifier)
        .deletePaymentOption(optionId);
    await _ref.read(paymentProvider.notifier).loadPaymentOptions();
  }

  Future<void> togglePaymentOption(String optionId, bool isEnabled) async {
    await _ref
        .read(adminSettingsProvider.notifier)
        .togglePaymentOption(optionId, isEnabled);
    await _ref.read(paymentProvider.notifier).loadPaymentOptions();
  }

  Future<void> createAdminAccount({
    required String name,
    required String email,
    required String password,
  }) {
    return _ref
        .read(adminSettingsProvider.notifier)
        .createAdminAccount(name: name, email: email, password: password);
  }

  Future<AdminAccount?> fetchAdminAccount(String userId) {
    return _ref
        .read(adminSettingsProvider.notifier)
        .fetchAdminAccountById(userId);
  }

  Future<void> updateAdminAccount({
    required String userId,
    required String name,
    required String email,
  }) {
    return _ref
        .read(adminSettingsProvider.notifier)
        .updateAdminAccount(userId: userId, name: name, email: email);
  }

  Future<void> approveAdmin({required String userId, required bool approved}) {
    return _ref
        .read(adminSettingsProvider.notifier)
        .approveAdmin(userId: userId, approved: approved);
  }

  Future<void> removeAdmin(String userId) {
    return _ref.read(adminSettingsProvider.notifier).removeAdmin(userId);
  }

  Future<Branch?> fetchBranch(String branchId) {
    return _ref.read(adminSettingsProvider.notifier).fetchBranchById(branchId);
  }

  Future<void> updateBranch({
    required String branchId,
    required String name,
    required String location,
    required String phoneNumber,
    required bool isActive,
  }) async {
    await _ref
        .read(adminSettingsProvider.notifier)
        .updateBranch(
          branchId: branchId,
          name: name,
          location: location,
          phoneNumber: phoneNumber,
          isActive: isActive,
        );
    _ref
        .read(branchProvider.notifier)
        .updateBranchInState(
          Branch(
            id: branchId,
            name: name,
            location: location,
            phoneNumber: phoneNumber,
            isActive: isActive,
          ),
        );
  }

  Future<void> deleteBranch(String branchId) async {
    await _ref.read(adminSettingsProvider.notifier).deleteBranch(branchId);
    await _ref.read(branchProvider.notifier).loadBranches();
    await _reloadCurrentBranchProducts();
  }

  Future<String> uploadProductImage({
    required List<int> bytes,
    required String fileName,
  }) {
    return _ref
        .read(commerceApiDataSourceProvider)
        .uploadProductImage(bytes: bytes, fileName: fileName);
  }

  Future<void> addProduct(Product product) async {
    await _ref.read(productRepositoryProvider).addProduct(product);
    await _refreshProductsForCreatedProduct(product);
  }

  Future<void> updateProductPrice(Product product, double newPrice) async {
    await _ref
        .read(productRepositoryProvider)
        .updateProduct(product.copyWith(price: newPrice));
    await _refreshProducts();
  }

  Future<void> deleteProduct(String productId) async {
    await _ref.read(productRepositoryProvider).deleteProduct(productId);
    await _refreshProducts();
  }

  Future<void> _refreshProducts() async {
    final isSuperAdmin = _ref.read(authProvider).session?.isSuperAdmin ?? false;
    if (isSuperAdmin) {
      await _ref.read(productProvider.notifier).loadAllProducts();
      return;
    }

    await _reloadCurrentBranchProducts();
  }

  Future<void> _refreshProductsForCreatedProduct(Product product) async {
    final isSuperAdmin = _ref.read(authProvider).session?.isSuperAdmin ?? false;
    if (isSuperAdmin) {
      await _ref.read(productProvider.notifier).loadAllProducts();
      return;
    }

    final branchNotifier = _ref.read(branchProvider.notifier);
    final currentBranchId = _ref.read(branchProvider).selectedBranchId;
    final preferredBranchId = product.branchIds.isNotEmpty
        ? product.branchIds.first
        : currentBranchId;

    if (preferredBranchId == null || preferredBranchId.isEmpty) {
      await _reloadCurrentBranchProducts();
      return;
    }

    if (currentBranchId != preferredBranchId) {
      await branchNotifier.selectBranch(preferredBranchId);
    }

    await _ref.read(productProvider.notifier).searchProducts('');
    await _ref.read(productProvider.notifier).filterByCategory(null);
    await _ref
        .read(productProvider.notifier)
        .loadProducts(branchId: preferredBranchId);
  }

  Future<void> _reloadCurrentBranchProducts() async {
    final branchId = _ref.read(branchProvider).selectedBranchId;
    if (branchId == null || branchId.isEmpty) {
      await _ref.read(productProvider.notifier).loadAllProducts();
      return;
    }

    await _ref.read(productProvider.notifier).loadProducts(branchId: branchId);
  }
}
