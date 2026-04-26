/// Lists the user roles supported by the app.
enum AppUserRole {
  superAdmin,
  admin,
  user,
}

extension AppUserRoleX on AppUserRole {
  // Converts enum role to Firestore-safe string value.
  String get value {
    switch (this) {
      case AppUserRole.superAdmin:
        return 'super_admin';
      case AppUserRole.admin:
        return 'admin';
      case AppUserRole.user:
        return 'user';
    }
  }

  // Quick helper to check admin-level access.
  bool get isAdminLike => this == AppUserRole.superAdmin || this == AppUserRole.admin;

  // Converts stored raw value into enum role with safe fallback.
  static AppUserRole fromRaw(Object? raw) {
    final value = (raw as String? ?? '').trim().toLowerCase();
    switch (value) {
      case 'super_admin':
        return AppUserRole.superAdmin;
      case 'admin':
        return AppUserRole.admin;
      case 'user':
      default:
        return AppUserRole.user;
    }
  }
}