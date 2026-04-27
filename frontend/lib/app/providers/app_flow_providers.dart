library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:e_commerce_app_with_django/features/admin/presentation/providers/admin_settings_provider.dart';
import 'package:e_commerce_app_with_django/features/auth/presentation/providers/auth_provider.dart';
import 'package:e_commerce_app_with_django/features/branches/presentation/providers/branch_provider.dart';
import 'package:e_commerce_app_with_django/features/categories/presentation/providers/category_provider.dart';
import 'package:e_commerce_app_with_django/features/orders/presentation/providers/order_provider.dart';
import 'package:e_commerce_app_with_django/features/payment/presentation/providers/payment_provider.dart';
import 'package:e_commerce_app_with_django/features/products/presentation/providers/product_provider.dart';

enum AuthFlowStep { login, createAccount }

final authFlowStepProvider = StateProvider<AuthFlowStep>(
  (ref) => AuthFlowStep.login,
);

final storefrontTabIndexProvider = StateProvider<int>((ref) => 0);

final appBootstrapProvider = FutureProvider<void>((ref) async {
  // Let the FutureProvider finish initialization before mutating other providers.
  await Future<void>.delayed(Duration.zero);
  await Future.wait([
    ref.read(authProvider.notifier).bootstrap(),
    ref.read(branchProvider.notifier).loadBranches(),
  ]);
});

final storefrontBootstrapProvider = FutureProvider.autoDispose<void>((
  ref,
) async {
  // Avoid mutating notifier-backed providers in the same initialization frame.
  await Future<void>.delayed(Duration.zero);
  await Future.wait([
    ref.read(productProvider.notifier).loadAllProducts(),
    ref.read(categoryProvider.notifier).loadCategories(),
    ref.read(paymentProvider.notifier).loadPaymentOptions(),
    ref.read(orderProvider.notifier).loadOrders(),
  ]);
});

final adminPortalBootstrapProvider = FutureProvider.autoDispose<void>((
  ref,
) async {
  // Avoid provider-to-provider writes while this FutureProvider is being created.
  await Future<void>.delayed(Duration.zero);
  final branchId = ref.read(branchProvider).selectedBranchId;
  final isSuperAdmin = ref.read(authProvider).session?.isSuperAdmin ?? false;

  if (isSuperAdmin) {
    await Future.wait([
      ref.read(productProvider.notifier).loadAllProducts(),
      ref.read(orderProvider.notifier).loadOrders(),
    ]);
  } else if (branchId != null) {
    await Future.wait([
      ref.read(productProvider.notifier).loadProducts(branchId: branchId),
      ref.read(orderProvider.notifier).loadOrders(branchId: branchId),
    ]);
  } else {
    await Future.wait([
      ref.read(productProvider.notifier).loadAllProducts(),
      ref.read(orderProvider.notifier).loadOrders(),
    ]);
  }

  await Future.wait([
    ref.read(categoryProvider.notifier).loadCategories(),
    ref.read(paymentProvider.notifier).loadPaymentOptions(),
    ref.read(adminSettingsProvider.notifier).load(),
  ]);
});
