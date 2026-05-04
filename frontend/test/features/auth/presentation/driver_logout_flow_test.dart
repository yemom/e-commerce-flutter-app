/// End-to-end widget coverage for driver logout returning to the main login flow.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:e_commerce_app_with_django/app/presentation/gateway/app_gateway.dart';
import 'package:e_commerce_app_with_django/app/providers/app_flow_providers.dart';
import 'package:e_commerce_app_with_django/features/auth/domain/models/auth_session.dart';
import 'package:e_commerce_app_with_django/features/auth/domain/models/user_role.dart';
import 'package:e_commerce_app_with_django/features/auth/presentation/providers/auth_provider.dart' as main_auth;
import 'package:e_commerce_app_with_django/features/branches/domain/models/branch.dart';
import 'package:e_commerce_app_with_django/features/branches/domain/repositories/branch_repository.dart';
import 'package:e_commerce_app_with_django/features/branches/presentation/providers/branch_provider.dart';
import 'package:e_commerce_app_with_django/driver_app/models/order.dart';
import 'package:e_commerce_app_with_django/driver_app/providers/orders_provider.dart';
import 'package:e_commerce_app_with_django/driver_app/providers/profile_provider.dart';
import 'package:e_commerce_app_with_django/driver_app/providers/auth_provider.dart' as driver_auth;
import 'package:e_commerce_app_with_django/driver_app/services/api_service.dart';
import 'package:e_commerce_app_with_django/driver_app/services/auth_service.dart';

class _TestMainAuthNotifier extends main_auth.AuthNotifier {
  _TestMainAuthNotifier(Ref ref, main_auth.AuthState initial) : super(ref) {
    state = initial;
  }

  @override
  Future<void> logout() async {
    state = const main_auth.AuthState(status: main_auth.AuthStatus.unauthenticated);
  }
}

class _TestBranchNotifier extends BranchNotifier {
  _TestBranchNotifier(Ref ref, BranchState initial)
      : super(ref, _TestBranchRepository()) {
    state = initial;
  }
}

class _TestOrdersController extends OrdersController {
  _TestOrdersController() : super(_TestApiService()) {
    state = const AsyncValue.data(<Order>[]);
  }

  @override
  Future<void> fetchAssigned({bool showLoader = true}) async {
    state = const AsyncValue.data(<Order>[]);
  }

  @override
  Future<void> updateStatus(String orderId, String status) async {}
}

class _TestDriverProfileNotifier extends DriverProfileNotifier {
  _TestDriverProfileNotifier() : super(_TestApiService()) {
    state = const AsyncValue.data(
      DriverProfile(
        name: 'Driver One',
        phone: '0000000000',
        email: 'driver@example.com',
        vehicleType: 'Car',
        licenseNumber: 'LIC-001',
        currentStatus: 'online',
        activeOrdersCount: 0,
      ),
    );
  }

  @override
  Future<void> fetch() async {
    state = const AsyncValue.data(
      DriverProfile(
        name: 'Driver One',
        phone: '0000000000',
        email: 'driver@example.com',
        vehicleType: 'Car',
        licenseNumber: 'LIC-001',
        currentStatus: 'online',
        activeOrdersCount: 0,
      ),
    );
  }

  @override
  Future<void> updateProfile({
    required String name,
    required String phone,
    required String email,
    required String vehicleType,
    required String licenseNumber,
    String? currentPassword,
    String? newPassword,
  }) async {}
}

class _TestBranchRepository implements BranchRepository {
  @override
  Future<Branch> addBranch(Branch branch) async => branch;

  @override
  Future<List<Branch>> getBranches() async => <Branch>[];

  @override
  Future<void> updateInventory({
    required String branchId,
    required String productId,
    required int quantity,
  }) async {}
}

class _TestAuthStorage extends AuthStorage {
  _TestAuthStorage(this._token);

  final String _token;

  @override
  Future<void> clear() async {}

  @override
  Future<String?> readToken() async => _token;

  @override
  Future<void> saveToken(String token) async {}
}

class _TestApiService extends ApiService {
  _TestApiService() : super(baseUrl: 'http://localhost:8000', getToken: () async => null);

  @override
  Future<Map<String, dynamic>> loginDriver(Map<String, dynamic> data) async {
    return <String, dynamic>{'token': 'driver-token'};
  }

  @override
  Future<Map<String, dynamic>> registerDriver(Map<String, dynamic> data) async {
    return <String, dynamic>{'token': 'driver-token'};
  }

  @override
  Future<List<dynamic>> getAssignedOrders({String? status}) async => <dynamic>[];

  @override
  Future<Map<String, dynamic>> getDriverProfile() async => <String, dynamic>{};

  @override
  Future<Map<String, dynamic>> updateDriverProfile(Map<String, dynamic> data) async => <String, dynamic>{};

  @override
  Future<Map<String, dynamic>> updateOrderStatus(
    String orderId,
    Map<String, dynamic> body,
  ) async => <String, dynamic>{};
}

void main() {
  testWidgets('driver logout returns to main login screen', (tester) async {
    final driverSession = AuthSession(
      token: 'main-driver-token',
      userName: 'Driver One',
      email: 'driver@example.com',
      userId: 'driver-1',
      role: AppUserRole.driver,
      approved: true,
    );

    final container = ProviderContainer(
      overrides: [
        appBootstrapProvider.overrideWith((ref) async {}),
        branchProvider.overrideWith(
          (ref) => _TestBranchNotifier(
            ref,
            BranchState(
              branches: [
                const Branch(
                  id: 'branch-1',
                  name: 'Main Branch',
                  location: 'Central',
                  phoneNumber: '0000000000',
                  isActive: true,
                ),
              ],
              selectedBranchId: 'branch-1',
              isLoading: false,
            ),
          ),
        ),
        main_auth.authProvider.overrideWith(
          (ref) => _TestMainAuthNotifier(
            ref,
            main_auth.AuthState(
              status: main_auth.AuthStatus.authenticated,
              session: driverSession,
            ),
          ),
        ),
        driver_auth.authStorageProvider.overrideWith(
          (ref) => _TestAuthStorage('driver-token'),
        ),
        driver_auth.apiServiceProvider.overrideWith(
          (ref) => _TestApiService(),
        ),
        ordersProvider.overrideWith((ref) => _TestOrdersController()),
        driverProfileProvider.overrideWith(
          (ref) => _TestDriverProfileNotifier(),
        ),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(home: AppGateway()),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Driver Home'), findsOneWidget);
    expect(find.text('View orders'), findsOneWidget);

    await tester.tap(find.byIcon(Icons.logout));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Login Account'), findsOneWidget);
    expect(find.text('Email or phone number'), findsOneWidget);
  });
}