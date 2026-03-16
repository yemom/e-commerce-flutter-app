/// Holds admin account management and approval state.
library;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show immutable;
import 'package:flutter_riverpod/flutter_riverpod.dart';

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

class AdminSettingsNotifier extends StateNotifier<AdminSettingsState> {
  AdminSettingsNotifier(this._ref, this._firestore) : super(const AdminSettingsState());

  final Ref _ref;
  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _categories => _firestore.collection('categories');
  CollectionReference<Map<String, dynamic>> get _branches => _firestore.collection('branches');
  CollectionReference<Map<String, dynamic>> get _payments => _firestore.collection('payment_options');
  CollectionReference<Map<String, dynamic>> get _users => _firestore.collection('users');

  Future<void> load() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      // Seed remote collections the first time so the dashboard always has something to manage.
      await _seedDefaultsIfEmpty();
      final branchDocs = await _branches.get();
      final categoryDocs = await _categories.get();
      final paymentDocs = await _payments.get();
      final adminDocs = await _users.where('role', whereIn: ['admin', 'super_admin']).get();

      state = state.copyWith(
        isLoading: false,
        branches: branchDocs.docs
            .map(_branchFromDoc)
            .toList()
          ..sort((a, b) => a.name.compareTo(b.name)),
        categories: categoryDocs.docs
            .map(
              _categoryFromDoc,
            )
            .toList(),
        paymentOptions: paymentDocs.docs
            .map(
              _paymentOptionFromDoc,
            )
            .toList()
          ..sort((a, b) => a.label.compareTo(b.label)),
        adminAccounts: adminDocs.docs
            .map(
              _adminFromDoc,
            )
            .toList()
          ..sort((a, b) => a.email.compareTo(b.email)),
      );
    } catch (error) {
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

    // Use a stable slug so categories can be updated later without extra lookups.
    await _categories.doc(categoryId).set(
      {
        'id': categoryId,
        'name': name.trim(),
        'description': description.trim(),
        'image': imageUrl.trim(),
        'isActive': true,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    await load();
  }

  Future<void> toggleCategory(String categoryId, bool isActive) async {
    await _categories.doc(categoryId).set(
      {
        'isActive': isActive,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
    await load();
  }

  Future<Category?> fetchCategoryById(String categoryId) async {
    final categoryDoc = await _categories.doc(categoryId).get();
    if (!categoryDoc.exists) {
      return null;
    }
    return _categoryFromDoc(categoryDoc);
  }

  Future<PaymentOption?> fetchPaymentOptionById(String optionId) async {
    final paymentDoc = await _payments.doc(optionId).get();
    if (!paymentDoc.exists) {
      return null;
    }
    return _paymentOptionFromDoc(paymentDoc);
  }

  Future<AdminAccount?> fetchAdminAccountById(String userId) async {
    final adminDoc = await _users.doc(userId).get();
    if (!adminDoc.exists) {
      return null;
    }
    return _adminFromDoc(adminDoc);
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

    await _categories.doc(categoryId).set(
      {
        'name': trimmedName,
        'description': description.trim(),
        'image': imageUrl.trim(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
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

    await _users.doc(userId).set(
      {
        'name': trimmedName,
        'email': trimmedEmail,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
    await load();
  }

  Future<Branch?> fetchBranchById(String branchId) async {
    final branchDoc = await _branches.doc(branchId).get();
    if (!branchDoc.exists) {
      return null;
    }
    return _branchFromDoc(branchDoc);
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

    await _branches.doc(branchId).set(
      {
        'name': trimmedName,
        'location': location.trim(),
        'phoneNumber': phoneNumber.trim(),
        'isActive': isActive,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
    await load();
  }

  Future<void> deleteCategory(String categoryId) async {
    await _categories.doc(categoryId).delete();
    await load();
  }

  Future<void> addPaymentOption({required String label, String? iconUrl}) async {
    final trimmedLabel = label.trim();
    final optionId = _slugify(trimmedLabel);

    if (trimmedLabel.isEmpty || optionId.isEmpty) {
      return;
    }

    // Admin-defined payment methods are stored remotely so they appear immediately in checkout.
    await _payments.doc(optionId).set(
      {
        'id': optionId,
        'method': optionId,
        'label': trimmedLabel,
        'isEnabled': true,
        'iconUrl': _normalizeOptional(iconUrl),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
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

    await _payments.doc(optionId).set(
      {
        'label': trimmedLabel,
        'iconUrl': _normalizeOptional(iconUrl),
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
    await load();
  }

  Future<void> deletePaymentOption(String optionId) async {
    await _payments.doc(optionId).delete();
    await load();
  }

  Future<void> togglePaymentOption(String optionId, bool isEnabled) async {
    await _payments.doc(optionId).set(
      {
        'isEnabled': isEnabled,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
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

  Future<void> _seedDefaultsIfEmpty() async {
    final paymentSnapshot = await _payments.get();
    if (paymentSnapshot.docs.isNotEmpty) {
      return;
    }

    for (final method in PaymentMethod.defaults) {
      await _payments.doc(method.id).set({
        'id': method.id,
        'method': method.id,
        'label': method.label,
        'isEnabled': true,
        'iconUrl': null,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    }
  }

  void _requireSuperAdmin() {
    // Protect sensitive admin-management actions.
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

  Category _categoryFromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const <String, dynamic>{};
    return Category(
      id: doc.id,
      name: data['name'] as String? ?? 'Category',
      description: data['description'] as String? ?? '',
      imageUrl: (data['image'] as String?) ?? (data['imageUrl'] as String? ?? ''),
      isActive: data['isActive'] as bool? ?? true,
    );
  }

  Branch _branchFromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const <String, dynamic>{};
    return Branch(
      id: doc.id,
      name: data['name'] as String? ?? 'Branch',
      location: data['location'] as String? ?? '',
      phoneNumber: data['phoneNumber'] as String? ?? '',
      isActive: data['isActive'] as bool? ?? true,
    );
  }

  PaymentOption _paymentOptionFromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const <String, dynamic>{};
    return PaymentOption(
      id: doc.id,
      method: PaymentMethod.fromRaw(
        data['method'] as String? ?? doc.id,
        label: data['label'] as String?,
      ),
      label: data['label'] as String? ?? 'Payment',
      isEnabled: data['isEnabled'] as bool? ?? true,
      iconUrl: data['iconUrl'] as String?,
    );
  }

  AdminAccount _adminFromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const <String, dynamic>{};
    return AdminAccount(
      userId: doc.id,
      email: data['email'] as String? ?? '',
      name: data['name'] as String? ?? 'Admin',
      role: AppUserRoleX.fromRaw(data['role']),
      approved: data['approved'] as bool? ?? false,
    );
  }
}

final adminSettingsProvider = StateNotifierProvider<AdminSettingsNotifier, AdminSettingsState>(
  (ref) => AdminSettingsNotifier(ref, ref.watch(firestoreProvider)),
);
