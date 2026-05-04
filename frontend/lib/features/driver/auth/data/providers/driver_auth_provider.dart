import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:e_commerce_app_with_django/core/auth/auth_storage.dart';
import 'package:e_commerce_app_with_django/core/data/providers.dart';

import '../services/driver_api_service.dart';

final driverAuthStorageProvider = Provider<AuthStorage>((ref) => const AuthStorage());

final driverApiServiceProvider = Provider<DriverApiService>((ref) {
  final storage = ref.read(driverAuthStorageProvider);
  return DriverApiService(
    baseUrl: ref.watch(appApiBaseUrlProvider),
    getToken: storage.readToken,
  );
});

final driverAuthProvider = StateNotifierProvider<DriverAuthController, AsyncValue<String?>>(
  (ref) => DriverAuthController(ref.read(driverApiServiceProvider), ref.read(driverAuthStorageProvider)),
);

class DriverAuthController extends StateNotifier<AsyncValue<String?>> {
  DriverAuthController(this.api, this.storage) : super(const AsyncValue.data(null));

  final DriverApiService api;
  final AuthStorage storage;

  Future<String> login(String identifier, String password) async {
    state = const AsyncValue.loading();
    try {
      final res = await api.login(identifier, password);
      final token = (res['token'] ?? res['accessToken'] ?? res['access_token']) as String?;
      final role = ((res['user'] as Map<String, dynamic>?)?['role'] as String?) ?? 'driver';
      if (token == null || token.isEmpty) {
        throw Exception('No token returned from server.');
      }
      await storage.saveToken(token);
      await storage.saveRole(role);
      state = AsyncValue.data(token);
      return role;
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }

  Future<void> logout() async {
    await storage.clear();
    state = const AsyncValue.data(null);
  }
}