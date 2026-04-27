library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:e_commerce_app_with_django/app/presentation/gateway/auth_flow_switcher.dart';
import 'package:e_commerce_app_with_django/app/presentation/gateway/branch_gate.dart';
import 'package:e_commerce_app_with_django/app/presentation/widgets/app_status_screen.dart';
import 'package:e_commerce_app_with_django/app/providers/app_flow_providers.dart';
import 'package:e_commerce_app_with_django/features/auth/presentation/providers/auth_provider.dart';
import 'package:e_commerce_app_with_django/features/branches/presentation/providers/branch_provider.dart';

class AppGateway extends ConsumerWidget {
  const AppGateway({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bootstrap = ref.watch(appBootstrapProvider);
    final authState = ref.watch(authProvider);
    final branchState = ref.watch(branchProvider);

    if (bootstrap.isLoading ||
        authState.status == AuthStatus.loading ||
        branchState.isLoading) {
      return const AppLoadingScreen();
    }

    if (bootstrap.hasError) {
      return const AppMessageScreen(
        message: 'We could not start the app. Please restart and try again.',
      );
    }

    if (authState.status == AuthStatus.unauthenticated) {
      return const AuthFlowSwitcher();
    }

    final session = authState.session;
    if (session == null) {
      return const AppLoadingScreen();
    }

    return BranchGate(session: session);
  }
}
