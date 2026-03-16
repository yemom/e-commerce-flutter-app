/// Exposes shared Riverpod providers for data sources and repositories.
library;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:e_commerce_app_with_django/core/data/datasources/asset_commerce_data_source.dart';
import 'package:e_commerce_app_with_django/core/data/datasources/preferences_data_source.dart';
import 'package:e_commerce_app_with_django/core/data/repositories/asset_branch_repository.dart';
import 'package:e_commerce_app_with_django/core/data/repositories/asset_category_repository.dart';
import 'package:e_commerce_app_with_django/core/data/repositories/asset_order_repository.dart';
import 'package:e_commerce_app_with_django/core/data/repositories/asset_payment_repository.dart';
import 'package:e_commerce_app_with_django/core/data/repositories/asset_product_repository.dart';
import 'package:e_commerce_app_with_django/features/branches/domain/repositories/branch_repository.dart';
import 'package:e_commerce_app_with_django/features/categories/domain/repositories/category_repository.dart';
import 'package:e_commerce_app_with_django/features/orders/domain/repositories/order_repository.dart';
import 'package:e_commerce_app_with_django/features/payment/domain/repositories/payment_repository.dart';
import 'package:e_commerce_app_with_django/features/products/domain/repositories/product_repository.dart';

final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) => throw UnimplementedError('SharedPreferences must be overridden in main.'),
);

final preferencesDataSourceProvider = Provider<PreferencesDataSource>(
  (ref) => PreferencesDataSource(ref.watch(sharedPreferencesProvider)),
);

final assetCommerceDataSourceProvider = Provider<AssetCommerceDataSource>(
  (ref) => const AssetCommerceDataSource(),
);

final defaultProductRepositoryProvider = Provider<ProductRepository>(
  (ref) => AssetProductRepository(ref.watch(assetCommerceDataSourceProvider)),
);

final defaultCategoryRepositoryProvider = Provider<CategoryRepository>(
  (ref) => AssetCategoryRepository(ref.watch(assetCommerceDataSourceProvider)),
);

final defaultBranchRepositoryProvider = Provider<BranchRepository>(
  (ref) => AssetBranchRepository(ref.watch(assetCommerceDataSourceProvider)),
);

final defaultPaymentRepositoryProvider = Provider<PaymentRepository>(
  (ref) => AssetPaymentRepository(ref.watch(assetCommerceDataSourceProvider)),
);

final defaultOrderRepositoryProvider = Provider<OrderRepository>(
  (ref) => AssetOrderRepository(ref.watch(assetCommerceDataSourceProvider)),
);