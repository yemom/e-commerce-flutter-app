/// Reads branch data from a backend API backed by MongoDB.
library;

import 'package:e_commerce_app_with_django/core/data/datasources/commerce_api_data_source.dart';
import 'package:e_commerce_app_with_django/core/data/dtos/branch_dto.dart';
import 'package:e_commerce_app_with_django/features/branches/domain/models/branch.dart';
import 'package:e_commerce_app_with_django/features/branches/domain/repositories/branch_repository.dart';

class RemoteBranchRepository implements BranchRepository {
  RemoteBranchRepository(this._dataSource);

  final CommerceApiDataSource _dataSource;

  @override
  Future<Branch> addBranch(Branch branch) async {
    final payload = await _dataSource.postItem(
      '/branches',
      body: BranchDto.fromDomain(branch).toJson(),
    );
    return BranchDto.fromJson(payload).toDomain();
  }

  @override
  Future<List<Branch>> getBranches() async {
    final payload = await _dataSource.getCollection('/branches');
    return payload
        .map(BranchDto.fromJson)
        .map((dto) => dto.toDomain())
        .toList();
  }

  @override
  Future<void> updateInventory({
    required String branchId,
    required String productId,
    required int quantity,
  }) async {
    // Inventory update endpoint also ensures branch-product relationship exists.
    await _dataSource.patchItem(
      '/branches/$branchId/inventory',
      body: {'productId': productId, 'quantity': quantity},
    );
  }
}
