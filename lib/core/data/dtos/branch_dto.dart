/// Converts raw branch data into the app's branch model.
library;
import 'package:e_commerce_app_with_django/features/branches/domain/models/branch.dart';

class BranchDto {
  const BranchDto({
    required this.id,
    required this.name,
    required this.location,
    required this.phoneNumber,
    required this.isActive,
  });

  final String id;
  final String name;
  final String location;
  final String phoneNumber;
  final bool isActive;

  factory BranchDto.fromJson(Map<String, dynamic> json) {
    return BranchDto(
      id: json['id'] as String,
      name: json['name'] as String,
      location: json['location'] as String,
      phoneNumber: json['phoneNumber'] as String,
      isActive: json['isActive'] as bool,
    );
  }

  factory BranchDto.fromDomain(Branch branch) {
    return BranchDto(
      id: branch.id,
      name: branch.name,
      location: branch.location,
      phoneNumber: branch.phoneNumber,
      isActive: branch.isActive,
    );
  }

  Branch toDomain() {
    return Branch(
      id: id,
      name: name,
      location: location,
      phoneNumber: phoneNumber,
      isActive: isActive,
    );
  }
}