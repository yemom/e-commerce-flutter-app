/// Defines products, color options, and product availability details.
library;
import 'package:flutter/foundation.dart';

@immutable
class ProductColorOption {
  const ProductColorOption({required this.name, required this.hexCode});

  final String name;
  final String hexCode;

  ProductColorOption copyWith({String? name, String? hexCode}) {
    return ProductColorOption(
      name: name ?? this.name,
      hexCode: hexCode ?? this.hexCode,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'hexCode': hexCode,
    };
  }

  factory ProductColorOption.fromJson(Map<String, dynamic> json) {
    return ProductColorOption(
      name: json['name'] as String,
      hexCode: json['hexCode'] as String,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is ProductColorOption &&
            runtimeType == other.runtimeType &&
            name == other.name &&
            hexCode == other.hexCode;
  }

  @override
  int get hashCode => Object.hash(name, hexCode);
}

@immutable
class Product {
  const Product({
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
  final String? selectedSize;
  final ProductColorOption? selectedColor;

  Product copyWith({
    String? id,
    String? name,
    String? description,
    String? imageUrl,
    double? price,
    String? categoryId,
    List<String>? branchIds,
    Map<String, int>? stockByBranch,
    bool? isAvailable,
    List<String>? availableSizes,
    List<ProductColorOption>? availableColors,
    String? selectedSize,
    bool clearSelectedSize = false,
    ProductColorOption? selectedColor,
    bool clearSelectedColor = false,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      price: price ?? this.price,
      categoryId: categoryId ?? this.categoryId,
      branchIds: branchIds ?? this.branchIds,
      stockByBranch: stockByBranch ?? this.stockByBranch,
      isAvailable: isAvailable ?? this.isAvailable,
      availableSizes: availableSizes ?? this.availableSizes,
      availableColors: availableColors ?? this.availableColors,
      selectedSize: clearSelectedSize ? null : selectedSize ?? this.selectedSize,
      selectedColor: clearSelectedColor ? null : selectedColor ?? this.selectedColor,
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
      'selectedSize': selectedSize,
      'selectedColor': selectedColor?.toJson(),
    };
  }

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
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
      selectedSize: json['selectedSize'] as String?,
      selectedColor: json['selectedColor'] == null
          ? null
          : ProductColorOption.fromJson(json['selectedColor'] as Map<String, dynamic>),
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is Product &&
            runtimeType == other.runtimeType &&
            id == other.id &&
            name == other.name &&
            description == other.description &&
            imageUrl == other.imageUrl &&
            price == other.price &&
            categoryId == other.categoryId &&
            listEquals(branchIds, other.branchIds) &&
            mapEquals(stockByBranch, other.stockByBranch) &&
            isAvailable == other.isAvailable &&
            listEquals(availableSizes, other.availableSizes) &&
            listEquals(availableColors, other.availableColors) &&
            selectedSize == other.selectedSize &&
            selectedColor == other.selectedColor;
  }

  @override
  int get hashCode => Object.hash(
        id,
        name,
        description,
        imageUrl,
        price,
        categoryId,
        Object.hashAll(branchIds),
        Object.hashAll(
          stockByBranch.entries.map((entry) => Object.hash(entry.key, entry.value)),
        ),
        isAvailable,
        Object.hashAll(availableSizes),
        Object.hashAll(availableColors),
        selectedSize,
        selectedColor,
      );
}