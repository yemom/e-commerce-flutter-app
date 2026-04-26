/// Converts raw category data into the app's category model.
library;

import 'package:e_commerce_app_with_django/features/categories/domain/models/category.dart';

class CategoryDto {
  const CategoryDto({
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

  factory CategoryDto.fromJson(Map<String, dynamic> json) {
    return CategoryDto(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      imageUrl: json['imageUrl'] as String,
      isActive: json['isActive'] as bool,
    );
  }

  factory CategoryDto.fromDomain(Category category) {
    return CategoryDto(
      id: category.id,
      name: category.name,
      description: category.description,
      imageUrl: category.imageUrl,
      isActive: category.isActive,
    );
  }

  Category toDomain() {
    return Category(
      id: id,
      name: name,
      description: description,
      imageUrl: imageUrl,
      isActive: isActive,
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
}
