/// Converts raw product data into the app's product model.
library;
import 'package:e_commerce_app_with_django/features/products/domain/models/product.dart';

class ProductDto {
  const ProductDto({
    required this.id,
    required this.name,
    required this.description,
    required this.imageUrl,
    required this.price,
    required this.categoryId,
    required this.branchIds,
    required this.stockByBranch,
    required this.isAvailable,
    this.availableSizes = const [],
    this.availableColors = const [],
    this.imageUrls = const [],
    this.selectedSize,
    this.selectedColor,
  });

  final String id;
  final String name;
  final String description;
  final String imageUrl;
  final double price;
  final String categoryId;
  final List<String> branchIds;
  final Map<String, int> stockByBranch;
  final bool isAvailable;
  final List<String> availableSizes;
  final List<ProductColorOption> availableColors;
  final List<String> imageUrls;
  final String? selectedSize;
  final ProductColorOption? selectedColor;

  factory ProductDto.fromJson(Map<String, dynamic> json) {
    return ProductDto(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      imageUrl: json['imageUrl'] as String,
      price: (json['price'] as num).toDouble(),
      categoryId: json['categoryId'] as String,
      branchIds: List<String>.from(json['branchIds'] as List<dynamic>),
      stockByBranch: Map<String, int>.from(json['stockByBranch'] as Map),
      isAvailable: json['isAvailable'] as bool,
      availableSizes: List<String>.from(json['availableSizes'] as List<dynamic>? ?? const []),
      availableColors: (json['availableColors'] as List<dynamic>? ?? const [])
          .map((color) => ProductColorOption.fromJson(color as Map<String, dynamic>))
          .toList(),
        imageUrls: List<String>.from(json['imageUrls'] as List<dynamic>? ?? const []),
      selectedSize: json['selectedSize'] as String?,
      selectedColor: json['selectedColor'] == null
          ? null
          : ProductColorOption.fromJson(json['selectedColor'] as Map<String, dynamic>),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'imageUrl': imageUrl,
      'price': price,
      'categoryId': categoryId,
      'branchIds': branchIds,
      'stockByBranch': stockByBranch,
      'isAvailable': isAvailable,
      'availableSizes': availableSizes,
      'availableColors': availableColors.map((color) => color.toJson()).toList(),
      'imageUrls': imageUrls,
      'selectedSize': selectedSize,
      'selectedColor': selectedColor?.toJson(),
    };
  }

  factory ProductDto.fromDomain(Product product) {
    return ProductDto(
      id: product.id,
      name: product.name,
      description: product.description,
      imageUrl: product.imageUrl,
      price: product.price,
      categoryId: product.categoryId,
      branchIds: product.branchIds,
      stockByBranch: product.stockByBranch,
      isAvailable: product.isAvailable,
      availableSizes: product.availableSizes,
      availableColors: product.availableColors,
      imageUrls: product.imageUrls,
      selectedSize: product.selectedSize,
      selectedColor: product.selectedColor,
    );
  }

  Product toDomain() {
    return Product(
      id: id,
      name: name,
      description: description,
      imageUrl: imageUrl,
      price: price,
      categoryId: categoryId,
      branchIds: branchIds,
      stockByBranch: stockByBranch,
      isAvailable: isAvailable,
      availableSizes: availableSizes,
      availableColors: availableColors,
      imageUrls: imageUrls,
      selectedSize: selectedSize,
      selectedColor: selectedColor,
    );
  }
}