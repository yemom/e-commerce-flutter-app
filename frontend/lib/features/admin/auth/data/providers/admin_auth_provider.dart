import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:e_commerce_app_with_django/core/auth/auth_storage.dart';
import 'package:e_commerce_app_with_django/core/data/providers.dart';

import '../services/admin_api_service.dart';

final adminAuthStorageProvider = Provider<AuthStorage>((ref) => const AuthStorage());

final adminApiServiceProvider = Provider<AdminApiService>((ref) {
  final storage = ref.read(adminAuthStorageProvider);
  return AdminApiService(
    baseUrl: ref.watch(appApiBaseUrlProvider),
    getToken: storage.readToken,
  );
});

final adminAuthProvider = StateNotifierProvider<AdminAuthController, AsyncValue<String?>>(
  (ref) => AdminAuthController(ref.read(adminApiServiceProvider), ref.read(adminAuthStorageProvider)),
);

class AdminAuthController extends StateNotifier<AsyncValue<String?>> {
  AdminAuthController(this.api, this.storage) : super(const AsyncValue.data(null));

  final AdminApiService api;
  final AuthStorage storage;

  Future<String> login(String identifier, String password) async {
    state = const AsyncValue.loading();
    try {
      final res = await api.login(identifier, password);
      final token = (res['token'] ?? res['accessToken'] ?? res['access_token']) as String?;
      final role = ((res['user'] as Map<String, dynamic>?)?['role'] as String?) ?? 'admin';
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