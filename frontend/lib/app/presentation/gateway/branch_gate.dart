library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:e_commerce_app_with_django/app/presentation/gateway/role_gate.dart';
import 'package:e_commerce_app_with_django/app/presentation/widgets/app_status_screen.dart';
import 'package:e_commerce_app_with_django/features/auth/domain/models/auth_session.dart';
import 'package:e_commerce_app_with_django/features/branches/presentation/providers/branch_provider.dart';
import 'package:e_commerce_app_with_django/features/branches/presentation/screens/branch_selection_screen.dart';

class BranchGate extends ConsumerWidget {
  const BranchGate({super.key, required this.session});

  final AuthSession session;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final branchState = ref.watch(branchProvider);

    if (branchState.isLoading) {
      return const AppLoadingScreen();
    }

    if (branchState.selectedBranchId == null) {
      return BranchSelectionScreen(
        branches: branchState.branches,
        selectedBranchId: branchState.selectedBranchId,
        onSelected: (branchId) async {
          await ref.read(branchProvider.notifier).selectBranch(branchId);
        },
        onContinue: () {},
      );
    }

    return RoleGate(session: session);
  }
}
