import 'package:flutter_riverpod/flutter_riverpod.dart';

class AddProductState {
  final String name;
  final String description;
  final double price;
  final List<String> imageUrls;
  final bool isLoading;

  AddProductState({
    this.name = '',
    this.description = '',
    this.price = 0,
    this.imageUrls = const [],
    this.isLoading = false,
  });

  AddProductState copyWith({
    String? name,
    String? description,
    double? price,
    List<String>? imageUrls,
    bool? isLoading,
  }) {
    return AddProductState(
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      imageUrls: imageUrls ?? this.imageUrls,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

class AddProductNotifier extends StateNotifier<AddProductState> {
  AddProductNotifier() : super(AddProductState());

  void setName(String value) {
    state = state.copyWith(name: value);
  }

  void setDescription(String value) {
    state = state.copyWith(description: value);
  }

  void setPrice(String value) {
    final parsed = double.tryParse(value) ?? 0;
    state = state.copyWith(price: parsed);
  }

  void addImage(String url) {
    state = state.copyWith(imageUrls: [...state.imageUrls, url]);
  }

  void removeImage(String url) {
    state = state.copyWith(
      imageUrls: state.imageUrls.where((e) => e != url).toList(),
    );
  }

  Future<void> submit(Future<void> Function(AddProductState) onSubmit) async {
    state = state.copyWith(isLoading: true);
    await onSubmit(state);
    state = state.copyWith(isLoading: false);
  }
}

final addProductProvider =
    StateNotifierProvider<AddProductNotifier, AddProductState>(
      (ref) => AddProductNotifier(),
    );
