/// Manages login, account creation, logout, and auth session state.
library;

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:e_commerce_app_with_django/core/data/datasources/commerce_api_data_source.dart';
import 'package:e_commerce_app_with_django/core/data/datasources/preferences_data_source.dart';
import 'package:e_commerce_app_with_django/core/data/providers.dart';
import 'package:e_commerce_app_with_django/features/auth/domain/models/auth_session.dart';
import 'package:e_commerce_app_with_django/features/auth/domain/models/user_role.dart';

enum AuthStatus {
  loading,
  authenticated,
  unauthenticated,
}

@immutable
/// Holds UI state for Auth.
class AuthState {
  const AuthState({
    required this.status,
    this.session,
    this.error,
  });

  const AuthState.loading() : this(status: AuthStatus.loading);

  final AuthStatus status;
  final AuthSession? session;
  final String? error;

  AuthState copyWith({AuthStatus? status, AuthSession? session, String? error}) {
    return AuthState(
      status: status ?? this.status,
      session: session ?? this.session,
      error: error,
    );
  }
}

/// Handles Auth state and actions.
class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier(this._ref) : super(const AuthState.loading());

  static const String superAdminEmail = '12yemom@gmail.com';

  final Ref _ref;

  CommerceApiDataSource get _api => _ref.read(commerceApiDataSourceProvider);
  PreferencesDataSource get _prefs => _ref.read(preferencesDataSourceProvider);

  String _normalizedEmail(String value) => value.trim().toLowerCase();

  Map<String, String> _authHeaders(String token) {
    return <String, String>{'Authorization': 'Bearer $token'};
  }

  String _friendlyApiError(Object error, String fallback) {
    // Surface backend/user-facing messages whenever available, otherwise use a safe fallback.
    if (error is CommerceApiException && error.message.trim().isNotEmpty) {
      return error.message.trim();
    }
    if (error is StateError && error.message.trim().isNotEmpty) {
      return error.message.trim();
    }
    return fallback;
  }

  AuthSession _sessionFromApi({
    required Map<String, dynamic> payload,
    String? fallbackToken,
  }) {
    // Some endpoints return {user, token}; others return user fields directly.
    final user = payload['user'] is Map<String, dynamic>
        ? payload['user'] as Map<String, dynamic>
        : payload;

    final token = (payload['token'] as String?)?.trim() ?? fallbackToken ?? '';
    if (token.isEmpty) {
      throw StateError('Missing auth token in response.');
    }

    final email = _normalizedEmail((user['email'] as String?) ?? '');
    final role = AppUserRoleX.fromRaw(user['role']);
    final approved = (user['approved'] as bool?) ?? role != AppUserRole.admin;

    // Pending admins are blocked from session creation until approved by a super admin.
    if (role == AppUserRole.admin && !approved) {
      throw StateError(
        'Your admin account is waiting for super admin approval. Please try again later.',
      );
    }

    return AuthSession(
      token: token,
      userName: (user['name'] as String?)?.trim().isNotEmpty == true
          ? (user['name'] as String).trim()
          : (email.isNotEmpty ? email.split('@').first : 'User'),
      email: email,
      userId: (user['id'] as String?)?.trim() ?? '',
      role: role,
      approved: approved,
    );
  }

  Future<void> bootstrap() async {
    // On app startup, restore a persisted token and validate it with /auth/me.
    if (!_api.isConfigured) {
      state = const AuthState(
        status: AuthStatus.unauthenticated,
        error: 'Backend API is not configured. Please set APP_API_BASE_URL.',
      );
      return;
    }

    final token = _prefs.getAuthToken();
    if (token == null || token.trim().isEmpty) {
      state = const AuthState(status: AuthStatus.unauthenticated);
      return;
    }

    try {
      final payload = await _api.getItem('/auth/me', headers: _authHeaders(token));
      final session = _sessionFromApi(payload: payload, fallbackToken: token);
      await _prefs.saveAuth(token: session.token, userName: session.userName);
      state = AuthState(status: AuthStatus.authenticated, session: session);
    } catch (error) {
      await _prefs.clearAuth();
      state = AuthState(
        status: AuthStatus.unauthenticated,
        error: _friendlyApiError(error, 'Your session expired. Please sign in again.'),
      );
    }
  }

  Future<void> login({required String identifier, required String password}) async {
    final email = _normalizedEmail(identifier);
    final trimmedPassword = password.trim();

    // Keep client-side validation simple and fast before touching the network.
    if (email.isEmpty || trimmedPassword.isEmpty) {
      state = const AuthState(
        status: AuthStatus.unauthenticated,
        error: 'Email and password are required.',
      );
      return;
    }

    if (!email.contains('@')) {
      state = const AuthState(
        status: AuthStatus.unauthenticated,
        error: 'Enter a valid email address.',
      );
      return;
    }

    try {
      // Server returns session payload and token on success.
      final payload = await _api.postItem(
        '/auth/login',
        body: <String, dynamic>{
          'email': email,
          'password': trimmedPassword,
        },
      );
      final session = _sessionFromApi(payload: payload);
      await _prefs.saveAuth(token: session.token, userName: session.userName);
      state = AuthState(status: AuthStatus.authenticated, session: session);
    } catch (error) {
      await _prefs.clearAuth();
      state = AuthState(
        status: AuthStatus.unauthenticated,
        error: _friendlyApiError(error, 'We could not sign you in right now. Please try again.'),
      );
    }
  }

  Future<void> logout() async {
    await _prefs.clearAuth();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  Future<void> signUp({
    required String fullName,
    required String email,
    required String password,
  }) async {
    final normalizedEmail = _normalizedEmail(email);
    final trimmedName = fullName.trim();
    final trimmedPassword = password.trim();

    // Mirror login validation style so auth UX is predictable.
    if (normalizedEmail.isEmpty || trimmedPassword.isEmpty) {
      state = const AuthState(
        status: AuthStatus.unauthenticated,
        error: 'Email and password are required.',
      );
      return;
    }

    if (!normalizedEmail.contains('@')) {
      state = const AuthState(
        status: AuthStatus.unauthenticated,
        error: 'Enter a valid email address.',
      );
      return;
    }

    if (trimmedPassword.length < 6) {
      state = const AuthState(
        status: AuthStatus.unauthenticated,
        error: 'Password must be at least 6 characters.',
      );
      return;
    }

    try {
      final payload = await _api.postItem(
        '/auth/signup',
        body: <String, dynamic>{
          'fullName': trimmedName,
          'email': normalizedEmail,
          'password': trimmedPassword,
        },
      );
      final session = _sessionFromApi(payload: payload);
      await _prefs.saveAuth(token: session.token, userName: session.userName);
      state = AuthState(status: AuthStatus.authenticated, session: session);
    } catch (error) {
      await _prefs.clearAuth();
      state = AuthState(
        status: AuthStatus.unauthenticated,
        error: _friendlyApiError(error, 'We could not create your account right now. Please try again.'),
      );
    }
  }

  Future<String> requestPasswordReset({required String email}) async {
    final normalizedEmail = _normalizedEmail(email);

    if (normalizedEmail.isEmpty || !normalizedEmail.contains('@')) {
      throw StateError('Enter a valid email address.');
    }

    // Request reset token/code delivery to email.
    final payload = await _api.postItem(
      '/auth/password-reset/request',
      body: <String, dynamic>{'email': normalizedEmail},
    );

    return (payload['message'] as String?)?.trim() ?? 'We sent a password reset code to your email address.';
  }

  Future<void> resetPassword({
    required String email,
    required String token,
    required String newPassword,
  }) async {
    final normalizedEmail = _normalizedEmail(email);
    final resetToken = token.trim();
    final trimmedPassword = newPassword.trim();

    if (normalizedEmail.isEmpty || !normalizedEmail.contains('@')) {
      throw StateError('Enter a valid email address.');
    }
    if (resetToken.isEmpty) {
      throw StateError('Reset code is required.');
    }
    if (trimmedPassword.length < 6) {
      throw StateError('Password must be at least 6 characters.');
    }

    // Confirm password reset using the code/token sent by backend.
    await _api.postItem(
      '/auth/password-reset/confirm',
      body: <String, dynamic>{
        'email': normalizedEmail,
        'token': resetToken,
        'newPassword': trimmedPassword,
      },
    );
  }

  Future<List<Map<String, dynamic>>> listAdminAccounts() async {
    final session = _requireSession();
    final payload = await _api.getCollection(
      '/auth/admin-accounts',
      headers: _authHeaders(session.token),
    );
    return payload;
  }

  Future<Map<String, dynamic>> fetchAdminAccountById(String userId) async {
    final session = _requireSession();
    return _api.getItem(
      '/auth/admin-accounts/$userId',
      headers: _authHeaders(session.token),
    );
  }

  Future<void> updateAdminAccount({
    required String userId,
    required String name,
    required String email,
  }) async {
    // All admin-account management endpoints are super-admin only.
    _requireSuperAdmin();
    final session = _requireSession();
    await _api.patchItem(
      '/auth/admin-accounts/$userId',
      headers: _authHeaders(session.token),
      body: <String, dynamic>{
        'name': name.trim(),
        'email': _normalizedEmail(email),
      },
    );
  }

  Future<void> createAdminAccount({
    required String name,
    required String email,
    required String password,
  }) async {
    _requireSuperAdmin();
    final session = _requireSession();
    await _api.postItem(
      '/auth/admin-accounts',
      headers: _authHeaders(session.token),
      body: <String, dynamic>{
        'name': name.trim(),
        'email': _normalizedEmail(email),
        'password': password.trim(),
      },
    );
  }

  Future<void> promoteUserToAdmin(String email) async {
    _requireSuperAdmin();
    final session = _requireSession();
    await _api.postItem(
      '/auth/admin-accounts/promote',
      headers: _authHeaders(session.token),
      body: <String, dynamic>{'email': _normalizedEmail(email)},
    );
  }

  Future<void> approveAdmin({required String userId, required bool approved}) async {
    _requireSuperAdmin();
    final session = _requireSession();
    await _api.patchItem(
      '/auth/admin-accounts/$userId/approval',
      headers: _authHeaders(session.token),
      body: <String, dynamic>{'approved': approved},
    );
  }

  Future<void> removeAdmin(String userId) async {
    _requireSuperAdmin();
    final session = _requireSession();
    await _api.deleteItem(
      '/auth/admin-accounts/$userId/admin-access',
      headers: _authHeaders(session.token),
    );
  }

  AuthSession _requireSession() {
    // Helper used by privileged endpoints that require a logged-in token.
    final session = state.session;
    if (session == null) {
      throw StateError('You must be signed in.');
    }
    return session;
  }

  void _requireSuperAdmin() {
    // Keep legacy super-admin email fallback for existing production data.
    final session = _requireSession();
    if (!session.isSuperAdmin && _normalizedEmail(session.email) != superAdminEmail) {
      throw StateError('Only a super admin can manage admin accounts.');
    }
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>(
  (ref) => AuthNotifier(ref),
);
