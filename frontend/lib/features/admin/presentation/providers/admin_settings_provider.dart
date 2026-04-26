/// Holds admin account management and settings state.
library;

import 'package:flutter/foundation.dart' show immutable;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:e_commerce_app_with_django/core/data/datasources/commerce_api_data_source.dart';
import 'package:e_commerce_app_with_django/core/data/providers.dart';
import 'package:e_commerce_app_with_django/features/auth/domain/models/user_role.dart';
import 'package:e_commerce_app_with_django/features/auth/presentation/providers/auth_provider.dart';
import 'package:e_commerce_app_with_django/features/branches/domain/models/branch.dart';
import 'package:e_commerce_app_with_django/features/categories/domain/models/category.dart';
import 'package:e_commerce_app_with_django/features/payment/domain/models/payment.dart';

@immutable
class AdminAccount {
  const AdminAccount({
    required this.userId,
    required this.email,
    required this.name,
    required this.role,
    required this.approved,
  });

  final String userId;
  final String email;
  final String name;
  final AppUserRole role;
  final bool approved;
}

@immutable
/// Holds UI state for Admin Settings.
class AdminSettingsState {
  const AdminSettingsState({
    this.branches = const [],
    this.categories = const [],
    this.paymentOptions = const [],
    this.adminAccounts = const [],
    this.isLoading = false,
    this.error,
  });

  final List<Branch> branches;
  final List<Category> categories;
  final List<PaymentOption> paymentOptions;
  final List<AdminAccount> adminAccounts;
  final bool isLoading;
  final String? error;

  AdminSettingsState copyWith({
    List<Branch>? branches,
    List<Category>? categories,
    List<PaymentOption>? paymentOptions,
    List<AdminAccount>? adminAccounts,
    bool? isLoading,
    String? error,
  }) {
    return AdminSettingsState(
      branches: branches ?? this.branches,
      categories: categories ?? this.categories,
      paymentOptions: paymentOptions ?? this.paymentOptions,
      adminAccounts: adminAccounts ?? this.adminAccounts,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Handles Admin Settings state and actions.
class AdminSettingsNotifier extends StateNotifier<AdminSettingsState> {
  AdminSettingsNotifier(this._ref, this._api) : super(const AdminSettingsState());

  final Ref _ref;
  final CommerceApiDataSource _api;

  Future<void> load() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final branchPayload = await _api.getCollection('/branches');
      final categoryPayload = await _api.getCollection('/categories');
      final paymentPayload = await _api.getCollection(
        '/payment-options',
        queryParameters: const {'includeDisabled': 'true'},
      );

      final session = _ref.read(authProvider).session;
      final adminAccounts = session?.isSuperAdmin == true
          ? await _ref.read(authProvider.notifier).listAdminAccounts()
          : const <Map<String, dynamic>>[];

      state = state.copyWith(
        isLoading: false,
        branches: branchPayload.map(_branchFromJson).toList()
          ..sort((a, b) => a.name.compareTo(b.name)),
        categories: categoryPayload.map(_categoryFromJson).toList()
          ..sort((a, b) => a.name.compareTo(b.name)),
        paymentOptions: paymentPayload.map(_paymentOptionFromJson).toList()
          ..sort((a, b) => a.label.compareTo(b.label)),
        adminAccounts: adminAccounts.map(_adminFromJson).toList()
          ..sort((a, b) => a.email.compareTo(b.email)),
      );
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        error: 'We could not load admin settings right now. Please try again.',
      );
    }
  }

  Future<void> addCategory({
    required String name,
    required String description,
    required String imageUrl,
  }) async {
    final categoryId = _slugify(name);
    if (categoryId.isEmpty) {
      return;
    }

    await _api.postItem(
      '/categories',
      body: {
        'id': categoryId,
        'name': name.trim(),
        'description': description.trim(),
        'imageUrl': imageUrl.trim(),
        'isActive': true,
      },
    );

    await load();
  }

  Future<void> toggleCategory(String categoryId, bool isActive) async {
    await _api.patchItem('/categories/$categoryId', body: {'isActive': isActive});
    await load();
  }

  Future<Category?> fetchCategoryById(String categoryId) async {
    final categories = await _api.getCollection('/categories');
    final data = categories.where((item) => item['id'] == categoryId).firstOrNull;
    if (data == null) {
      return null;
    }
    return _categoryFromJson(data);
  }

  Future<PaymentOption?> fetchPaymentOptionById(String optionId) async {
    final options = await _api.getCollection(
      '/payment-options',
      queryParameters: const {'includeDisabled': 'true'},
    );
    final data = options.where((item) => item['id'] == optionId).firstOrNull;
    if (data == null) {
      return null;
    }
    return _paymentOptionFromJson(data);
  }

  Future<AdminAccount?> fetchAdminAccountById(String userId) async {
    final payload = await _ref.read(authProvider.notifier).fetchAdminAccountById(userId);
    if (payload.isEmpty) {
      return null;
    }
    return _adminFromJson(payload);
  }

  Future<void> updateCategory({
    required String categoryId,
    required String name,
    required String description,
    required String imageUrl,
  }) async {
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      return;
    }

    await _api.patchItem(
      '/categories/$categoryId',
      body: {
        'name': trimmedName,
        'description': description.trim(),
        'imageUrl': imageUrl.trim(),
      },
    );
    await load();
  }

  Future<void> updateAdminAccount({
    required String userId,
    required String name,
    required String email,
  }) async {
    _requireSuperAdmin();
    final trimmedName = name.trim();
    final trimmedEmail = email.trim().toLowerCase();
    if (trimmedName.isEmpty || trimmedEmail.isEmpty) {
      return;
    }

    await _ref.read(authProvider.notifier).updateAdminAccount(
      userId: userId,
      name: trimmedName,
      email: trimmedEmail,
    );
    await load();
  }

  Future<Branch?> fetchBranchById(String branchId) async {
    final branches = await _api.getCollection('/branches');
    final data = branches.where((item) => item['id'] == branchId).firstOrNull;
    if (data == null) {
      return null;
    }
    return _branchFromJson(data);
  }

  Future<void> updateBranch({
    required String branchId,
    required String name,
    required String location,
    required String phoneNumber,
    required bool isActive,
  }) async {
    _requireSuperAdmin();
    final trimmedName = name.trim();
    if (trimmedName.isEmpty) {
      return;
    }

    await _api.postItem(
      '/branches',
      body: {
        'id': branchId,
        'name': trimmedName,
        'location': location.trim(),
        'phoneNumber': phoneNumber.trim(),
        'isActive': isActive,
      },
    );
    await load();
  }

  Future<void> deleteBranch(String branchId) async {
    _requireSuperAdmin();
    await _api.deleteItem('/branches/$branchId');
    await load();
  }

  Future<void> deleteCategory(String categoryId) async {
    await _api.deleteItem('/categories/$categoryId');
    await load();
  }

  Future<void> addPaymentOption({required String label, String? iconUrl}) async {
    final trimmedLabel = label.trim();
    final optionId = _slugify(trimmedLabel);
    if (trimmedLabel.isEmpty || optionId.isEmpty) {
      return;
    }

    await _api.postItem(
      '/payment-options',
      body: {
        'id': optionId,
        'method': optionId,
        'label': trimmedLabel,
        'isEnabled': true,
        'iconUrl': _normalizeOptional(iconUrl),
      },
    );
    await load();
  }

  Future<void> updatePaymentOption({
    required String optionId,
    required String label,
    String? iconUrl,
  }) async {
    final trimmedLabel = label.trim();
    if (trimmedLabel.isEmpty) {
      return;
    }

    await _api.patchItem(
      '/payment-options/$optionId',
      body: {
        'label': trimmedLabel,
        'iconUrl': _normalizeOptional(iconUrl),
      },
    );
    await load();
  }

  Future<void> deletePaymentOption(String optionId) async {
    await _api.deleteItem('/payment-options/$optionId');
    await load();
  }

  Future<void> togglePaymentOption(String optionId, bool isEnabled) async {
    await _api.patchItem('/payment-options/$optionId', body: {'isEnabled': isEnabled});
    await load();
  }

  Future<void> createAdminAccount({
    required String name,
    required String email,
    required String password,
  }) async {
    _requireSuperAdmin();
    await _ref.read(authProvider.notifier).createAdminAccount(
      name: name.trim(),
      email: email.trim().toLowerCase(),
      password: password,
    );
    await load();
  }

  Future<void> approveAdmin({required String userId, required bool approved}) async {
    _requireSuperAdmin();
    await _ref.read(authProvider.notifier).approveAdmin(userId: userId, approved: approved);
    await load();
  }

  Future<void> removeAdmin(String userId) async {
    _requireSuperAdmin();
    await _ref.read(authProvider.notifier).removeAdmin(userId);
    await load();
  }

  void _requireSuperAdmin() {
    final session = _ref.read(authProvider).session;
    if (session == null || !session.isSuperAdmin) {
      throw StateError('Only a super admin can manage admin accounts.');
    }
  }

  String _slugify(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-|-$'), '');
  }

  String? _normalizeOptional(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }
    return trimmed;
  }

  Category _categoryFromJson(Map<String, dynamic> data) {
    return Category(
      id: (data['id'] as String?) ?? '',
      name: (data['name'] as String?) ?? 'Category',
      description: (data['description'] as String?) ?? '',
      imageUrl: (data['imageUrl'] as String?) ?? ((data['image'] as String?) ?? ''),
      isActive: (data['isActive'] as bool?) ?? true,
    );
  }

  Branch _branchFromJson(Map<String, dynamic> data) {
    return Branch(
      id: (data['id'] as String?) ?? '',
      name: (data['name'] as String?) ?? 'Branch',
      location: (data['location'] as String?) ?? '',
      phoneNumber: (data['phoneNumber'] as String?) ?? '',
      isActive: (data['isActive'] as bool?) ?? true,
    );
  }

  PaymentOption _paymentOptionFromJson(Map<String, dynamic> data) {
    return PaymentOption(
      id: (data['id'] as String?) ?? '',
      method: PaymentMethod.fromRaw(
        (data['method'] as String?) ?? ((data['id'] as String?) ?? ''),
        label: data['label'] as String?,
      ),
      label: (data['label'] as String?) ?? 'Payment',
      isEnabled: (data['isEnabled'] as bool?) ?? true,
      iconUrl: data['iconUrl'] as String?,
    );
  }

  AdminAccount _adminFromJson(Map<String, dynamic> data) {
    return AdminAccount(
      userId: (data['id'] as String?) ?? '',
      email: (data['email'] as String?) ?? '',
      name: (data['name'] as String?) ?? 'Admin',
      role: AppUserRoleX.fromRaw(data['role']),
      approved: (data['approved'] as bool?) ?? false,
    );
  }
}

final adminSettingsProvider = StateNotifierProvider<AdminSettingsNotifier, AdminSettingsState>(
  (ref) => AdminSettingsNotifier(ref, ref.watch(commerceApiDataSourceProvider)),
);
