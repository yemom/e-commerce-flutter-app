library;

import 'package:flutter/material.dart';

import 'package:e_commerce_app_with_django/app/presentation/shells/admin_portal_shell.dart';
import 'package:e_commerce_app_with_django/app/presentation/shells/app_shell.dart';
import 'package:e_commerce_app_with_django/features/auth/domain/models/auth_session.dart';
import 'package:e_commerce_app_with_django/features/auth/domain/models/user_role.dart';

class RoleGate extends StatelessWidget {
  const RoleGate({super.key, required this.session});

  final AuthSession session;

  @override
  Widget build(BuildContext context) {
    if (session.role == AppUserRole.admin ||
        session.role == AppUserRole.superAdmin) {
      return const AdminPortalShell();
    }

    return const AppShell();
  }
}
