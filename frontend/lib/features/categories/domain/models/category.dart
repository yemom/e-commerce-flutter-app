/// Defines a product category shown in browsing and admin tools.
library;
import 'package:flutter/foundation.dart';

@immutable
class Category {
  const Category({
    required this.id,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.isActive,
  });

  final String id;
  final String name;
  final String description;
  final String imageUrl;
  final bool isActive;

  Category copyWith({
    String? id,
    String? name,
    String? description,
    String? imageUrl,
    bool? isActive,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      isActive: isActive ?? this.isActive,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'imageUrl': imageUrl,
      'isActive': isActive,
    };
  }

  factory Category.fromJson(Map<String, dynamic> json) {
    return Category(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      imageUrl: json['imageUrl'] as String,
      isActive: json['isActive'] as bool,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is Category &&
            runtimeType == other.runtimeType &&
            id == other.id &&
            name == other.name &&
            description == other.description &&
            imageUrl == other.imageUrl &&
            isActive == other.isActive;
  }

  @override
  int get hashCode => Object.hash(id, name, description, imageUrl, isActive);
}