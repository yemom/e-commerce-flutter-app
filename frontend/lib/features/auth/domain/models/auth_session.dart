/// Stores the signed-in user's identity, role, and approval state.
library;
import 'package:flutter/foundation.dart';

import 'package:e_commerce_app_with_django/features/auth/domain/models/user_role.dart';

@immutable
class AuthSession {
  const AuthSession({
    required this.token,
    required this.userName,
    required this.email,
    required this.userId,
    required this.role,
    required this.approved,
  });

  final String token;
  final String userName;
  final String email;
  final String userId;
  final AppUserRole role;
  final bool approved;

  // True for admin and super admin users.
  bool get isAdmin => role.isAdminLike;
  // True only for super admin user.
  bool get isSuperAdmin => role == AppUserRole.superAdmin;
}