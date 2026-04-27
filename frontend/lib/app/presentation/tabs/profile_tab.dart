library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:e_commerce_app_with_django/app/presentation/widgets/app_status_screen.dart';
import 'package:e_commerce_app_with_django/features/auth/presentation/providers/auth_provider.dart';
import 'package:e_commerce_app_with_django/features/auth/presentation/screens/profile_screen.dart';
import 'package:e_commerce_app_with_django/features/branches/presentation/providers/branch_provider.dart';

class ProfileTab extends ConsumerWidget {
  const ProfileTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final branchState = ref.watch(branchProvider);
    final session = authState.session;

    if (session == null) {
      return const AppLoadingScreen();
    }

    final branchName =
        branchState.branches
            .where((branch) => branch.id == branchState.selectedBranchId)
            .firstOrNull
            ?.name ??
        '';

    return ProfileScreen(
      userName: session.userName,
      email: session.email,
      role: session.role,
      branchName: branchName,
      onLogout: () => ref.read(authProvider.notifier).logout(),
    );
  }
}
