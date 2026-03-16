/// Defines a store branch with contact and availability details.
library;
import 'package:flutter/foundation.dart';

@immutable
class Branch {
  const Branch({
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

  Branch copyWith({
    String? id,
    String? name,
    String? location,
    String? phoneNumber,
    bool? isActive,
  }) {
    return Branch(
      id: id ?? this.id,
      name: name ?? this.name,
      location: location ?? this.location,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      isActive: isActive ?? this.isActive,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'location': location,
      'phoneNumber': phoneNumber,
      'isActive': isActive,
    };
  }

  factory Branch.fromJson(Map<String, dynamic> json) {
    return Branch(
      id: json['id'] as String,
      name: json['name'] as String,
      location: json['location'] as String,
      phoneNumber: json['phoneNumber'] as String,
      isActive: json['isActive'] as bool,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is Branch &&
            runtimeType == other.runtimeType &&
            id == other.id &&
            name == other.name &&
            location == other.location &&
            phoneNumber == other.phoneNumber &&
            isActive == other.isActive;
  }

  @override
  int get hashCode => Object.hash(id, name, location, phoneNumber, isActive);
}