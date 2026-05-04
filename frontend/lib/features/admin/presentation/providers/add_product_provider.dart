import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:e_commerce_app_with_django/features/products/domain/models/product.dart';

class AddProductState {
  final String name;
  final String description;
  final double price;
  final List<String> imageUrls;
  final String? categoryId;
  final Set<String> branchIds;
  final Set<String> sizes;
  final Set<ProductColorOption> colors;
  final bool isLoading;
  final bool isUploadingImage;

  const AddProductState({
    this.name = '',
    this.description = '',
    this.price = 0,
    this.imageUrls = const [],
    this.categoryId,
    this.branchIds = const {},
    this.sizes = const {'Medium'},
    this.colors = const {},
    this.isLoading = false,
    this.isUploadingImage = false,
  });

  AddProductState copyWith({
    String? name,
    String? description,
    double? price,
    List<String>? imageUrls,
    String? categoryId,
    Set<String>? branchIds,
    Set<String>? sizes,
    Set<ProductColorOption>? colors,
    bool? isLoading,
    bool? isUploadingImage,
  }) {
    return AddProductState(
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      imageUrls: imageUrls ?? this.imageUrls,
      categoryId: categoryId ?? this.categoryId,
      branchIds: branchIds ?? this.branchIds,
      sizes: sizes ?? this.sizes,
      colors: colors ?? this.colors,
      isLoading: isLoading ?? this.isLoading,
      isUploadingImage: isUploadingImage ?? this.isUploadingImage,
    );
  }

  /// Converts state into a [Product] ready to persist or pass to ProductDetailScreen.
  Product toProduct() {
    final slugId = name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-');
    final primaryImage = imageUrls.isNotEmpty
        ? imageUrls.first
        : 'https://images.unsplash.com/photo-1523275335684-37898b6baf30';

    return Product(
      id: 'prod-$slugId',
      name: name,
      description: description,
      imageUrl: primaryImage,
      // All images are forwarded so ProductDetailScreen can scroll through them.
      imageUrls: imageUrls,
      price: price,
      categoryId: categoryId ?? '',
      branchIds: branchIds.toList(),
      stockByBranch: {for (final id in branchIds) id: 1},
      isAvailable: true,
      availableSizes: sizes.toList(),
      availableColors: colors.toList(),
    );
  }
}

class AddProductNotifier extends StateNotifier<AddProductState> {
  AddProductNotifier() : super(const AddProductState());

  void setName(String value) => state = state.copyWith(name: value);

  void setDescription(String value) =>
      state = state.copyWith(description: value);

  void setPrice(String value) =>
      state = state.copyWith(price: double.tryParse(value) ?? 0);

  void setCategoryId(String? id) => state = state.copyWith(categoryId: id);

  // ── Images ────────────────────────────────────────────────────────────────

  void addImageUrl(String url) {
    final trimmed = url.trim();
    if (trimmed.isEmpty || state.imageUrls.contains(trimmed)) return;
    state = state.copyWith(imageUrls: [...state.imageUrls, trimmed]);
  }

  void addImageUrls(List<String> urls) {
    final incoming = urls.map((u) => u.trim()).where((u) => u.isNotEmpty);
    final merged = {...state.imageUrls, ...incoming}.toList();
    state = state.copyWith(imageUrls: merged);
  }

  void removeImageUrl(String url) {
    state = state.copyWith(
      imageUrls: state.imageUrls.where((e) => e != url).toList(),
    );
  }

  void setUploadingImage(bool value) =>
      state = state.copyWith(isUploadingImage: value);

  // ── Variants ──────────────────────────────────────────────────────────────

  void toggleSize(String size, {required bool selected}) {
    final updated = {...state.sizes};
    selected ? updated.add(size) : updated.remove(size);
    state = state.copyWith(sizes: updated);
  }

  void toggleColor(ProductColorOption color, {required bool selected}) {
    final updated = {...state.colors};
    selected ? updated.add(color) : updated.remove(color);
    state = state.copyWith(colors: updated);
  }

  // ── Branches ──────────────────────────────────────────────────────────────

  void toggleBranch(String branchId, {required bool selected}) {
    final updated = {...state.branchIds};
    selected ? updated.add(branchId) : updated.remove(branchId);
    state = state.copyWith(branchIds: updated);
  }

  // ── Submit ────────────────────────────────────────────────────────────────

  Future<void> submit(Future<void> Function(Product) onSubmit) async {
    state = state.copyWith(isLoading: true);
    try {
      await onSubmit(state.toProduct());
    } finally {
      state = state.copyWith(isLoading: false);
    }
  }

  void removeImage(String url) {}

  void addImage(String url) {}
}

final addProductProvider =
    StateNotifierProvider<AddProductNotifier, AddProductState>(
      (ref) => AddProductNotifier(),
    );
