/// Exposes shared Riverpod providers for data sources and repositories.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import 'package:e_commerce_app_with_django/core/data/datasources/asset_commerce_data_source.dart';
import 'package:e_commerce_app_with_django/core/data/datasources/commerce_api_data_source.dart';
import 'package:e_commerce_app_with_django/core/data/datasources/preferences_data_source.dart';
import 'package:e_commerce_app_with_django/core/data/repositories/asset_branch_repository.dart';
import 'package:e_commerce_app_with_django/core/data/repositories/asset_category_repository.dart';
import 'package:e_commerce_app_with_django/core/data/repositories/asset_order_repository.dart';
import 'package:e_commerce_app_with_django/core/data/repositories/asset_payment_repository.dart';
import 'package:e_commerce_app_with_django/core/data/repositories/asset_product_repository.dart';
import 'package:e_commerce_app_with_django/core/data/repositories/remote_branch_repository.dart';
import 'package:e_commerce_app_with_django/core/data/repositories/remote_category_repository.dart';
import 'package:e_commerce_app_with_django/core/data/repositories/remote_order_repository.dart';
import 'package:e_commerce_app_with_django/core/data/repositories/remote_payment_repository.dart';
import 'package:e_commerce_app_with_django/core/data/repositories/remote_product_repository.dart';
import 'package:e_commerce_app_with_django/features/branches/domain/repositories/branch_repository.dart';
import 'package:e_commerce_app_with_django/features/categories/domain/repositories/category_repository.dart';
import 'package:e_commerce_app_with_django/features/orders/domain/repositories/order_repository.dart';
import 'package:e_commerce_app_with_django/features/payment/domain/repositories/payment_repository.dart';
import 'package:e_commerce_app_with_django/features/products/domain/repositories/product_repository.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) =>
      throw UnimplementedError('SharedPreferences must be overridden in main.'),
);

final preferencesDataSourceProvider = Provider<PreferencesDataSource>(
  (ref) => PreferencesDataSource(ref.watch(sharedPreferencesProvider)),
);

final assetCommerceDataSourceProvider = Provider<AssetCommerceDataSource>(
  (ref) => const AssetCommerceDataSource(),
);

String _defaultApiBaseUrl() {
  // Web can call localhost directly from the browser on the same machine.
  if (kIsWeb) {
    return 'http://localhost:8000/api';
  }

  switch (defaultTargetPlatform) {
    case TargetPlatform.android:
      // Android emulators access host localhost through 10.0.2.2.
      return 'http://10.0.2.2:8000/api';
    case TargetPlatform.iOS:
    case TargetPlatform.macOS:
    case TargetPlatform.windows:
    case TargetPlatform.linux:
    case TargetPlatform.fuchsia:
      return 'http://localhost:8000/api';
  }
}

String _resolveAppApiBaseUrl() {
  // Let runtime --dart-define override defaults when provided.
  final configured = const String.fromEnvironment('APP_API_BASE_URL').trim();
  return configured.isNotEmpty ? configured : _defaultApiBaseUrl();
}

final appApiBaseUrlProvider = Provider<String>(
  (ref) => _resolveAppApiBaseUrl(),
);

final appApiHttpClientProvider = Provider<http.Client>((ref) {
  final client = http.Client();
  ref.onDispose(client.close);
  return client;
});

final commerceApiDataSourceProvider = Provider<CommerceApiDataSource>(
  (ref) => CommerceApiDataSource(
    baseUrl: ref.watch(appApiBaseUrlProvider),
    client: ref.watch(appApiHttpClientProvider),
  ),
);

final assetProductRepositoryProvider = Provider<ProductRepository>(
  (ref) => AssetProductRepository(ref.watch(assetCommerceDataSourceProvider)),
);

final assetCategoryRepositoryProvider = Provider<CategoryRepository>(
  (ref) => AssetCategoryRepository(ref.watch(assetCommerceDataSourceProvider)),
);

final assetBranchRepositoryProvider = Provider<BranchRepository>(
  (ref) => AssetBranchRepository(ref.watch(assetCommerceDataSourceProvider)),
);

final assetPaymentRepositoryProvider = Provider<PaymentRepository>(
  (ref) => AssetPaymentRepository(ref.watch(assetCommerceDataSourceProvider)),
);

final assetOrderRepositoryProvider = Provider<OrderRepository>(
  (ref) => AssetOrderRepository(ref.watch(assetCommerceDataSourceProvider)),
);

final defaultProductRepositoryProvider = Provider<ProductRepository>((ref) {
  // Prefer remote repositories whenever API is configured and reachable.
  final api = ref.watch(commerceApiDataSourceProvider);
  if (api.isConfigured) {
    return RemoteProductRepository(api);
  }
  return ref.watch(assetProductRepositoryProvider);
});

final defaultCategoryRepositoryProvider = Provider<CategoryRepository>((ref) {
  final api = ref.watch(commerceApiDataSourceProvider);
  if (api.isConfigured) {
    return RemoteCategoryRepository(api);
  }
  return ref.watch(assetCategoryRepositoryProvider);
});

final defaultBranchRepositoryProvider = Provider<BranchRepository>((ref) {
  final api = ref.watch(commerceApiDataSourceProvider);
  if (api.isConfigured) {
    return RemoteBranchRepository(api);
  }
  return ref.watch(assetBranchRepositoryProvider);
});

final defaultPaymentRepositoryProvider = Provider<PaymentRepository>((ref) {
  final api = ref.watch(commerceApiDataSourceProvider);
  if (api.isConfigured) {
    return RemotePaymentRepository(api);
  }
  return ref.watch(assetPaymentRepositoryProvider);
});

final defaultOrderRepositoryProvider = Provider<OrderRepository>((ref) {
  final api = ref.watch(commerceApiDataSourceProvider);
  if (api.isConfigured) {
    return RemoteOrderRepository(api);
  }
  return ref.watch(assetOrderRepositoryProvider);
});
