import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:e_commerce_app_with_django/features/auth/presentation/screens/login_screen.dart';

import '../../data/providers/user_auth_provider.dart';

class UserLoginScreen extends ConsumerWidget {
  const UserLoginScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return LoginScreen(
      onLogin: ({required String identifier, required String password}) async {
        final role = await ref.read(userAuthProvider.notifier).login(identifier, password);
        if (!context.mounted) return;
        if (role == 'user') {
          Navigator.pushNamedAndRemoveUntil(context, '/user/home', (route) => false);
        }
      },
    );
  }
}