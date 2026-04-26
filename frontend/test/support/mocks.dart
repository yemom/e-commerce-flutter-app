/// Test coverage for mocks behaviors.
library;

import 'package:flutter/widgets.dart';
import 'package:mocktail/mocktail.dart';

import 'package:e_commerce_app_with_django/features/branches/domain/models/branch.dart';
import 'package:e_commerce_app_with_django/features/branches/domain/repositories/branch_repository.dart';
import 'package:e_commerce_app_with_django/features/categories/domain/models/category.dart';
import 'package:e_commerce_app_with_django/features/categories/domain/repositories/category_repository.dart';
import 'package:e_commerce_app_with_django/features/orders/domain/models/order.dart';
import 'package:e_commerce_app_with_django/features/orders/domain/repositories/order_repository.dart';
import 'package:e_commerce_app_with_django/features/payment/domain/models/payment.dart';
import 'package:e_commerce_app_with_django/features/payment/domain/repositories/payment_repository.dart';
import 'package:e_commerce_app_with_django/features/products/domain/models/product.dart';
import 'package:e_commerce_app_with_django/features/products/domain/repositories/product_repository.dart';

class MockProductRepository extends Mock implements ProductRepository {}

class MockOrderRepository extends Mock implements OrderRepository {}

class MockPaymentRepository extends Mock implements PaymentRepository {}

class MockCategoryRepository extends Mock implements CategoryRepository {}

class MockBranchRepository extends Mock implements BranchRepository {}

class MockNavigatorObserver extends Mock implements NavigatorObserver {}

class FakeProduct extends Fake implements Product {}

class FakeCategory extends Fake implements Category {}

class FakeBranch extends Fake implements Branch {}

class FakeOrder extends Fake implements Order {}

class FakePayment extends Fake implements Payment {}

class FakePaymentOption extends Fake implements PaymentOption {}

void registerTestFallbackValues() {
  registerFallbackValue(FakeProduct());
  registerFallbackValue(FakeCategory());
  registerFallbackValue(FakeBranch());
  registerFallbackValue(FakeOrder());
  registerFallbackValue(FakePayment());
  registerFallbackValue(FakePaymentOption());
}
