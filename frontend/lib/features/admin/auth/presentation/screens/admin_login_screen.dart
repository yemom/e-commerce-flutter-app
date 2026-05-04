import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:e_commerce_app_with_django/features/auth/presentation/screens/login_screen.dart';

import '../../data/providers/admin_auth_provider.dart';

class AdminLoginScreen extends ConsumerWidget {
  const AdminLoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return LoginScreen(
      onLogin: ({required String identifier, required String password}) async {
        final role = await ref.read(adminAuthProvider.notifier).login(identifier, password);
        if (!context.mounted) return;
        if (role == 'admin' || role == 'super_admin') {
          Navigator.pushNamedAndRemoveUntil(context, '/admin/home', (route) => false);
        }
      },
    );
  }
}