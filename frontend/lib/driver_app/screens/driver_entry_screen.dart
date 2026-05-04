import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:e_commerce_app_with_django/features/auth/presentation/screens/login_screen.dart';

import '../providers/auth_provider.dart';
import 'home_screen.dart';

class DriverEntryScreen extends ConsumerWidget {
  const DriverEntryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);

    // Reuse a single login widget to avoid duplication.
    LoginScreen buildLoginScreen() => LoginScreen(
          onLogin: ({required String identifier, required String password}) async {
            final role = await ref.read(authControllerProvider.notifier).login(identifier, password);
            if (!context.mounted) return;
            if (role == 'driver') {
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (_) => const HomeScreen(),
                ),
              );
            }
          },
        );

    return authState.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (_, __) => buildLoginScreen(),
      data: (token) {
        if (token == null || token.trim().isEmpty) {
          return buildLoginScreen();
        }
        return const HomeScreen();
      },
    );
  }
}
