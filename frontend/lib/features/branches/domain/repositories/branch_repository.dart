/// Describes the data operations available for branch records.
library;
import 'package:e_commerce_app_with_django/features/branches/domain/models/branch.dart';

abstract class BranchRepository {
  Future<List<Branch>> getBranches();

  Future<Branch> addBranch(Branch branch);

  Future<void> updateInventory({
    required String branchId,
    required String productId,
    required int quantity,
  });
}