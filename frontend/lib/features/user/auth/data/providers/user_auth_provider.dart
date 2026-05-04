import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:e_commerce_app_with_django/core/auth/auth_storage.dart';
import 'package:e_commerce_app_with_django/core/data/providers.dart';

import '../services/user_api_service.dart';

final userAuthStorageProvider = Provider<AuthStorage>((ref) => const AuthStorage());

final userApiServiceProvider = Provider<UserApiService>((ref) {
  final storage = ref.read(userAuthStorageProvider);
  return UserApiService(
    baseUrl: ref.watch(appApiBaseUrlProvider),
    getToken: storage.readToken,
  );
});

final userAuthProvider = StateNotifierProvider<UserAuthController, AsyncValue<String?>>(
  (ref) => UserAuthController(ref.read(userApiServiceProvider), ref.read(userAuthStorageProvider)),
);

class UserAuthController extends StateNotifier<AsyncValue<String?>> {
  UserAuthController(this.api, this.storage) : super(const AsyncValue.data(null));

  final UserApiService api;
  final AuthStorage storage;

  Future<String> login(String identifier, String password) async {
    state = const AsyncValue.loading();
    try {
      final res = await api.login(identifier, password);
      final token = (res['token'] ?? res['accessToken'] ?? res['access_token']) as String?;
      final role = ((res['user'] as Map<String, dynamic>?)?['role'] as String?) ?? 'user';
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