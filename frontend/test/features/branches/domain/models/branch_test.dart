/// Test coverage for branch_test behaviors.
library;

import 'package:flutter_test/flutter_test.dart';

import 'package:e_commerce_app_with_django/features/branches/domain/models/branch.dart';

import '../../../../support/test_data.dart';

void main() {
  group('Branch', () {
    test('supports at least five active market branches', () {
      expect(testBranches, hasLength(greaterThanOrEqualTo(5)));
      expect(testBranches.where((branch) => branch.isActive), hasLength(5));
    });

    test('stores branch contact and location details', () {
      final branch = buildBranch();

      expect(branch.id, 'branch-addis-bole');
      expect(branch.name, 'Addis Bole');
      expect(branch.location, contains('Addis Ababa'));
      expect(branch.phoneNumber, startsWith('+251'));
    });

    test('copyWith updates operational state', () {
      final branch = buildBranch();

      final updated = branch.copyWith(isActive: false);

      expect(updated.id, branch.id);
      expect(updated.isActive, isFalse);
      expect(updated.location, branch.location);
    });

    test('round-trips through json serialization', () {
      final branch = buildBranch();

      final recreated = Branch.fromJson(branch.toJson());

      expect(recreated, equals(branch));
    });
  });
}
