import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:e_commerce_app_with_django/core/data/providers.dart';

import '../services/api_service.dart';
import '../services/auth_service.dart';

final authStorageProvider = Provider((ref) => AuthStorage());

final apiServiceProvider = Provider<ApiService>((ref) {
  final storage = ref.read(authStorageProvider);
  final baseUrl = ref.watch(appApiBaseUrlProvider);
  return ApiService(baseUrl: baseUrl, getToken: storage.readToken);
});

final authControllerProvider =
    StateNotifierProvider<AuthController, AsyncValue<String?>>((ref) {
      final storage = ref.read(authStorageProvider);
      return AuthController(storage, ref.read(apiServiceProvider));
    });

class AuthController extends StateNotifier<AsyncValue<String?>> {
  AuthController(this.storage, this.api) : super(const AsyncValue.data(null)) {
    _load();
  }

  final AuthStorage storage;
  final ApiService api;

  Future<void> _load() async {
    state = const AsyncValue.loading();
    try {
      final token = await storage.readToken();
      state = AsyncValue.data(token);
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
    }
  }
  // auth_provider.dart

  Future<String> login(String identifier, String password) async {
    state = const AsyncValue.loading();
    try {
      final res = await api.loginDriver({
        'identifier': identifier,
        'password': password,
      });

      final token =
          (res['token'] ?? res['accessToken'] ?? res['access_token'])
              as String?;
      if (token == null || token.isEmpty) {
        throw Exception('No token returned from server.');
      }

      final user = res['user'] as Map<String, dynamic>?;
      final role = (user != null ? (user['role'] as String?) : null) ?? '';

      await storage.saveToken(token);
      await storage.saveRole(role);

      state = AsyncValue.data(token);
      return role;
    } catch (error, stackTrace) {
      state = AsyncValue.error(error, stackTrace);
      rethrow;
    }
  }

  Future<void> register({
    required String name,
    required String phone,
    required String password,
    required String email,
    required String vehicleType,
    required String phoneNumber,
    required String licenseNumber,
  }) async {
    state = const AsyncValue.loading();
    try {
      final res = await api.registerDriver({
        'name': name,
        'phone': phone,
        'password': password,
        'email': email,
        'vehicleType': vehicleType,
        'phoneNumber': phoneNumber,
        'licenseNumber': licenseNumber,
      });
      final token = res['token'] as String?;
      if (token != null && token.trim().isNotEmpty) {
        await storage.saveToken(token);
        state = AsyncValue.data(token);
        return;
      }
      state = const AsyncValue.data(null);
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
