/// Manages login, account creation, logout, and auth session state.
library;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_storage/firebase_storage.dart';

import 'package:e_commerce_app_with_django/firebase_options.dart';
import 'package:e_commerce_app_with_django/features/auth/domain/models/auth_session.dart';
import 'package:e_commerce_app_with_django/features/auth/domain/models/user_role.dart';

enum AuthStatus {
  loading,
  authenticated,
  unauthenticated,
}

@immutable
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

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier(this._ref) : super(const AuthState.loading());

  static const String superAdminEmail = '12yemom@gmail.com';

  final Ref _ref;
  FirebaseAuth get _auth => _ref.read(firebaseAuthProvider);
  FirebaseFirestore get _firestore => _ref.read(firestoreProvider);

  // Keep email checks consistent by always trimming spaces and lowercasing.
  String _normalizedEmail(String value) => value.trim().toLowerCase();

  // Converts Firebase sign-in errors into clear messages for end users.
  String _friendlySignInError(FirebaseAuthException error) {
    switch (error.code) {
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'user-not-found':
        return 'No account was found with this email. Please sign up first.';
      case 'wrong-password':
      case 'invalid-credential':
        return 'The email or password is not correct. Please try again.';
      case 'user-disabled':
        return 'This account has been disabled. Please contact support.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait a moment and try again.';
      case 'network-request-failed':
        return 'No internet connection. Please check your network and try again.';
      default:
        return 'We could not sign you in right now. Please try again.';
    }
  }

  // Converts Firebase sign-up errors into clear messages for end users.
  String _friendlySignUpError(FirebaseAuthException error) {
    switch (error.code) {
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'email-already-in-use':
        return 'This email is already registered. Please sign in instead.';
      case 'weak-password':
        return 'Please choose a stronger password with at least 6 characters.';
      case 'operation-not-allowed':
        return 'Sign up is currently unavailable. Please try again later.';
      case 'network-request-failed':
        return 'No internet connection. Please check your network and try again.';
      default:
        return 'We could not create your account right now. Please try again.';
    }
  }

  // Generic fallback for non-auth Firebase exceptions.
  String _friendlyFirebaseError(String fallback) =>
      '$fallback Please try again in a moment.';

  Future<void> bootstrap() async {
    // Restore auth state when the app starts.
    final user = _auth.currentUser;
    if (user == null) {
      state = const AuthState(status: AuthStatus.unauthenticated);
      return;
    }

    try {
      // Rebuild the session from Firebase so role and approval changes are always current.
      final session = await _buildSession(user);
      state = AuthState(status: AuthStatus.authenticated, session: session);
    } on StateError catch (error) {
      await _auth.signOut();
      state = AuthState(status: AuthStatus.unauthenticated, error: error.message);
    }
  }

  Future<void> login({required String identifier, required String password}) async {
    // Normalize input to avoid mismatch caused by extra spaces or mixed case.
    final email = _normalizedEmail(identifier);

    if (email.isEmpty || password.trim().isEmpty) {
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
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = credential.user;
      if (user == null) {
        state = const AuthState(status: AuthStatus.unauthenticated, error: 'Unable to sign in.');
        return;
      }

      // Session details are read from Firestore because role and approval are app-specific.
      final session = await _buildSession(user);
      state = AuthState(status: AuthStatus.authenticated, session: session);
    } on FirebaseAuthException catch (error) {
      state = AuthState(
        status: AuthStatus.unauthenticated,
        error: _friendlySignInError(error),
      );
    } on FirebaseException catch (error) {
      state = AuthState(
        status: AuthStatus.unauthenticated,
        error: _friendlyFirebaseError('We could not sign you in.'),
      );
    } on StateError catch (error) {
      state = AuthState(
        status: AuthStatus.unauthenticated,
        error: error.message,
      );
    }
  }

  Future<void> logout() async {
    // Clear Firebase session and update app state.
    await _auth.signOut();
    state = const AuthState(status: AuthStatus.unauthenticated);
  }

  Future<void> signUp({
    required String fullName,
    required String email,
    required String password,
  }) async {
    final normalizedEmail = _normalizedEmail(email);
    final trimmedName = fullName.trim();

    if (normalizedEmail.isEmpty || password.trim().isEmpty) {
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

    if (password.trim().length < 6) {
      state = const AuthState(
        status: AuthStatus.unauthenticated,
        error: 'Password must be at least 6 characters.',
      );
      return;
    }

    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: normalizedEmail,
        password: password.trim(),
      );
      final user = credential.user;
      if (user == null) {
        state = const AuthState(status: AuthStatus.unauthenticated, error: 'Unable to create account.');
        return;
      }

      if (trimmedName.isNotEmpty) {
        // Save display name in Firebase Auth profile for convenience.
        await user.updateDisplayName(trimmedName);
      }

      await _firestore.collection('users').doc(user.uid).set(
        {
          'id': user.uid,
          'email': normalizedEmail,
          'name': trimmedName.isEmpty ? normalizedEmail.split('@').first : trimmedName,
          'role': _resolveInitialRole(normalizedEmail).value,
          'approved': normalizedEmail == superAdminEmail,
          'createdAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      // New users are immediately converted into a session after their profile document is created.
      final session = await _buildSession(user);
      state = AuthState(status: AuthStatus.authenticated, session: session);
    } on FirebaseAuthException catch (error) {
      state = AuthState(
        status: AuthStatus.unauthenticated,
        error: _friendlySignUpError(error),
      );
    } on FirebaseException catch (error) {
      state = AuthState(
        status: AuthStatus.unauthenticated,
        error: _friendlyFirebaseError('We could not create your account.'),
      );
    } on StateError catch (error) {
      state = AuthState(status: AuthStatus.unauthenticated, error: error.message);
    }
  }

  Future<AuthSession> _buildSession(User user) async {
    // Make sure the user has a matching Firestore document before deriving app-specific auth state.
    await _ensureUserDocument(user);

    final token = await user.getIdToken() ?? '';
    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    final data = userDoc.data() ?? const <String, dynamic>{};

    final role = AppUserRoleX.fromRaw(data['role']);
    final approved = (data['approved'] as bool?) ?? (role == AppUserRole.superAdmin);

    // Admins are blocked until approval so the UI never exposes admin tools prematurely.
    if (role == AppUserRole.admin && !approved) {
      await _auth.signOut();
      throw StateError('Your admin account is waiting for super admin approval. Please try again later.');
    }

    return AuthSession(
      token: token,
      userName: (data['name'] as String?)?.trim().isNotEmpty == true
          ? data['name'] as String
          : user.displayName ?? user.email?.split('@').first ?? 'User',
      email: (data['email'] as String?) ?? user.email ?? '',
      userId: user.uid,
      role: role,
      approved: approved,
    );
  }

  Future<void> createAdminAccount({
    required String name,
    required String email,
    required String password,
  }) async {
    final session = state.session;
    if (session == null || !session.isSuperAdmin) {
      throw StateError('Only a super admin can create admin accounts.');
    }

    final normalizedEmail = _normalizedEmail(email);
    final trimmedName = name.trim();
    final trimmedPassword = password.trim();

    if (trimmedName.isEmpty) {
      throw StateError('Please enter the admin name.');
    }
    if (!normalizedEmail.contains('@')) {
      throw StateError('Please enter a valid admin email address.');
    }
    if (trimmedPassword.length < 6) {
      throw StateError('Admin password must be at least 6 characters long.');
    }

    final appName = 'admin-creator-${DateTime.now().microsecondsSinceEpoch}';
    FirebaseApp? secondaryApp;

    try {
      secondaryApp = await Firebase.initializeApp(
        name: appName,
        options: DefaultFirebaseOptions.currentPlatform,
      );
      final secondaryAuth = FirebaseAuth.instanceFor(app: secondaryApp);
      final secondaryFirestore = FirebaseFirestore.instanceFor(app: secondaryApp);

      final credential = await secondaryAuth.createUserWithEmailAndPassword(
        email: normalizedEmail,
        password: trimmedPassword,
      );
      final createdUser = credential.user;

      if (createdUser == null) {
        throw StateError('We could not create the admin account. Please try again.');
      }

      await createdUser.updateDisplayName(trimmedName);

      await secondaryFirestore.collection('users').doc(createdUser.uid).set({
        'id': createdUser.uid,
        'email': normalizedEmail,
        'name': trimmedName,
        'role': AppUserRole.user.value,
        'approved': false,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      await _firestore.collection('users').doc(createdUser.uid).set(
        {
          'email': normalizedEmail,
          'name': trimmedName,
          'role': AppUserRole.admin.value,
          'approved': false,
          'updatedAt': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );

      await secondaryAuth.signOut();
    } on FirebaseAuthException catch (error) {
      throw StateError(_friendlySignUpError(error));
    } on FirebaseException catch (error) {
      throw StateError(_friendlyFirebaseError('We could not create the admin account.'));
    } finally {
      await secondaryApp?.delete();
    }
  }

  Future<void> promoteUserToAdmin(String email) async {
    final session = state.session;
    if (session == null || !session.isSuperAdmin) {
      throw StateError('Only a super admin can create admin accounts.');
    }

    final query = await _firestore
        .collection('users')
        .where('email', isEqualTo: email.trim().toLowerCase())
        .limit(1)
        .get();

    if (query.docs.isEmpty) {
      throw StateError('No user was found with that email. Ask them to sign up first.');
    }

    await query.docs.first.reference.set(
      {
        'role': AppUserRole.admin.value,
        'approved': false,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  Future<void> approveAdmin({required String userId, required bool approved}) async {
    final session = state.session;
    if (session == null || !session.isSuperAdmin) {
      throw StateError('Only a super admin can approve admin accounts.');
    }

    await _firestore.collection('users').doc(userId).set(
      {
        'role': AppUserRole.admin.value,
        'approved': approved,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  Future<void> removeAdmin(String userId) async {
    final session = state.session;
    if (session == null || !session.isSuperAdmin) {
      throw StateError('Only a super admin can remove admin access.');
    }

    await _firestore.collection('users').doc(userId).set(
      {
        'role': AppUserRole.user.value,
        'approved': false,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  AppUserRole _resolveInitialRole(String email) {
    // The configured super admin email always gets the super admin role.
    if (email == superAdminEmail) {
      return AppUserRole.superAdmin;
    }
    return AppUserRole.user;
  }

  Future<void> _ensureUserDocument(User user) async {
    // Keep Firestore user data in sync with Firebase Auth user details.
    final email = (user.email ?? '').trim().toLowerCase();
    final userRef = _firestore.collection('users').doc(user.uid);
    final snapshot = await userRef.get();
    final isSuperAdminAccount = email == superAdminEmail;

    if (!snapshot.exists) {
      await userRef.set({
        'id': user.uid,
        'email': email,
        'name': user.displayName ?? email.split('@').first,
        'role': isSuperAdminAccount ? AppUserRole.superAdmin.value : AppUserRole.user.value,
        'approved': isSuperAdminAccount,
        'createdAt': FieldValue.serverTimestamp(),
      });
      return;
    }

    final data = snapshot.data() ?? const <String, dynamic>{};
    final legacyIsAdmin = data['isAdmin'] as bool?;
    final existingRole = AppUserRoleX.fromRaw(data['role']);
    final roleFromLegacy = legacyIsAdmin == true ? AppUserRole.admin : AppUserRole.user;
    final resolvedRole = data.containsKey('role') ? existingRole : roleFromLegacy;

    // If this is the super admin email, force role and approval to super admin values.
    final nextRole = isSuperAdminAccount ? AppUserRole.superAdmin : resolvedRole;
    final nextApproved = isSuperAdminAccount ? true : (data['approved'] as bool? ?? false);

    await userRef.set(
      {
        'id': user.uid,
        'email': email,
        'name': (data['name'] as String?)?.trim().isNotEmpty == true
            ? data['name']
            : user.displayName ?? email.split('@').first,
        'role': nextRole.value,
        'approved': nextApproved,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>(
  (ref) => AuthNotifier(ref),
);

final firebaseAuthProvider = Provider<FirebaseAuth>((ref) => FirebaseAuth.instance);
final firestoreProvider = Provider<FirebaseFirestore>((ref) => FirebaseFirestore.instance);
final firebaseStorageProvider = Provider<FirebaseStorage>((ref) => FirebaseStorage.instance);