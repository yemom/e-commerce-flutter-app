/// Reads branch data from assets and exposes it through the repository contract.
library;
import 'package:e_commerce_app_with_django/core/data/datasources/asset_commerce_data_source.dart';
import 'package:e_commerce_app_with_django/core/data/dtos/branch_dto.dart';
import 'package:e_commerce_app_with_django/features/branches/domain/models/branch.dart';
import 'package:e_commerce_app_with_django/features/branches/domain/repositories/branch_repository.dart';

class AssetBranchRepository implements BranchRepository {
  AssetBranchRepository(this._dataSource);

  final AssetCommerceDataSource _dataSource;
  List<BranchDto>? _cache;

  Future<List<BranchDto>> _branches() async {
    _cache ??= await _dataSource.loadBranches();
    return _cache!;
  }

  @override
  Future<Branch> addBranch(Branch branch) async {
    final list = await _branches();
    final dto = BranchDto.fromDomain(branch);
    list.add(dto);
    return dto.toDomain();
  }

  @override
  Future<List<Branch>> getBranches() async {
    final list = await _branches();
    return list.map((dto) => dto.toDomain()).toList();
  }

  @override
  Future<void> updateInventory({
    required String branchId,
    required String productId,
    required int quantity,
  }) async {}
}