/// Tracks loaded branches and the currently selected branch.
library;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:e_commerce_app_with_django/core/data/providers.dart';
import 'package:e_commerce_app_with_django/features/branches/domain/models/branch.dart';
import 'package:e_commerce_app_with_django/features/branches/domain/repositories/branch_repository.dart';

final branchRepositoryProvider = Provider<BranchRepository>(
  (ref) => ref.watch(defaultBranchRepositoryProvider),
);

@immutable
class BranchState {
  const BranchState({
    this.branches = const [],
    this.selectedBranchId,
    this.isLoading = false,
  });

  final List<Branch> branches;
  final String? selectedBranchId;
  final bool isLoading;

  BranchState copyWith({
    List<Branch>? branches,
    String? selectedBranchId,
    bool? isLoading,
  }) {
    return BranchState(
      branches: branches ?? this.branches,
      selectedBranchId: selectedBranchId ?? this.selectedBranchId,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class BranchNotifier extends StateNotifier<BranchState> {
  BranchNotifier(this._ref, this._repository) : super(const BranchState());

  final Ref _ref;
  final BranchRepository _repository;

  Future<void> loadBranches() async {
    state = state.copyWith(isLoading: true);
    final branches = await _repository.getBranches();
    // Persisted branch wins; fallback to first branch keeps app usable on first launch.
    final persisted = _ref.read(preferencesDataSourceProvider).getSelectedBranchId();
    state = state.copyWith(
      branches: branches,
      selectedBranchId: persisted ?? (branches.isEmpty ? null : branches.first.id),
      isLoading: false,
    );
  }

  Future<void> selectBranch(String branchId) async {
    // Save selection so the storefront opens on the same branch next time.
    await _ref.read(preferencesDataSourceProvider).setSelectedBranchId(branchId);
    state = state.copyWith(selectedBranchId: branchId);
  }

  void updateBranchInState(Branch updatedBranch) {
    final nextBranches = state.branches
        .map((branch) => branch.id == updatedBranch.id ? updatedBranch : branch)
        .toList();
    state = state.copyWith(branches: nextBranches);
  }
}

final branchProvider = StateNotifierProvider<BranchNotifier, BranchState>(
  (ref) => BranchNotifier(ref, ref.watch(branchRepositoryProvider)),
);