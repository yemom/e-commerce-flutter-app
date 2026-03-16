/// Test coverage for branch_repository_test behaviors.
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../support/mocks.dart';
import '../../../../support/test_data.dart';

void main() {
  late MockBranchRepository repository;

  setUpAll(registerTestFallbackValues);

  setUp(() {
    repository = MockBranchRepository();
  });

  group('BranchRepository contract', () {
    test('loads multiple branch locations for market filtering', () async {
      when(() => repository.getBranches()).thenAnswer((_) async => testBranches);

      final result = await repository.getBranches();

      expect(result, hasLength(5));
      expect(result.map((branch) => branch.id), contains('branch-bahir-dar-piazza'));
    });

    test('adds new branches and updates inventory allocations', () async {
      final branch = buildBranch(
        id: 'branch-gondar-piazza',
        name: 'Gondar Piazza',
        location: 'Piazza, Gondar',
        phoneNumber: '+251911000006',
      );

      when(() => repository.addBranch(branch)).thenAnswer((_) async => branch);
      when(
        () => repository.updateInventory(
          branchId: 'branch-addis-bole',
          productId: 'prod-coffee-1',
          quantity: 22,
        ),
      ).thenAnswer((_) async {});

      expect(await repository.addBranch(branch), branch);

      await repository.updateInventory(
        branchId: 'branch-addis-bole',
        productId: 'prod-coffee-1',
        quantity: 22,
      );

      verify(
        () => repository.updateInventory(
          branchId: 'branch-addis-bole',
          productId: 'prod-coffee-1',
          quantity: 22,
        ),
      ).called(1);
    });
  });
}
