import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class AuthStorage {
  const AuthStorage();

  static const String tokenKey = 'auth_token';
  static const String roleKey = 'auth_role';

  FlutterSecureStorage get _storage => const FlutterSecureStorage();

  Future<void> saveToken(String token) async {
    await _storage.write(key: tokenKey, value: token);
  }

  Future<String?> readToken() async {
    return _storage.read(key: tokenKey);
  }

  Future<void> saveRole(String role) async {
    await _storage.write(key: roleKey, value: role);
  }

  Future<String?> readRole() async {
    return _storage.read(key: roleKey);
  }

  Future<void> clear() async {
    await _storage.delete(key: tokenKey);
    await _storage.delete(key: roleKey);
  }
}