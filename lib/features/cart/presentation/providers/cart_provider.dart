/// Holds cart items, quantities, totals, and cart actions.
library;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:e_commerce_app_with_django/features/products/domain/models/product.dart';

@immutable
class CartItem {
  const CartItem({required this.product, required this.quantity});

  final Product product;
  final int quantity;

  CartItem copyWith({Product? product, int? quantity}) {
    return CartItem(
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
    );
  }
}

@immutable
class CartState {
  const CartState({
    required this.items,
    required this.totalItems,
    required this.totalPrice,
  });

  const CartState.empty()
      : items = const [],
        totalItems = 0,
        totalPrice = 0;

  final List<CartItem> items;
  final int totalItems;
  final double totalPrice;

  CartState copyWith({List<CartItem>? items, int? totalItems, double? totalPrice}) {
    return CartState(
      items: items ?? this.items,
      totalItems: totalItems ?? this.totalItems,
      totalPrice: totalPrice ?? this.totalPrice,
    );
  }
}

class CartNotifier extends StateNotifier<CartState> {
  CartNotifier() : super(const CartState.empty());

  void addProduct(Product product) {
    // Variant-aware key keeps different size/color selections as separate cart lines.
    final index = state.items.indexWhere((item) => _itemKey(item.product) == _itemKey(product));
    final updatedItems = List<CartItem>.from(state.items);

    if (index == -1) {
      updatedItems.add(CartItem(product: product, quantity: 1));
    } else {
      updatedItems[index] = updatedItems[index].copyWith(
        quantity: updatedItems[index].quantity + 1,
      );
    }

    _setItems(updatedItems);
  }

  void updateQuantity({required String productId, required int quantity}) {
    final updatedItems = state.items
        .map(
          (item) => _itemKey(item.product) == productId
              ? item.copyWith(quantity: quantity)
              : item,
        )
        .where((item) => item.quantity > 0)
        .toList();
    _setItems(updatedItems);
  }

  void removeProduct(String productId) {
    _setItems(state.items.where((item) => _itemKey(item.product) != productId).toList());
  }

  void clear() {
    state = const CartState.empty();
  }

  void _setItems(List<CartItem> items) {
    // Recompute totals from source-of-truth items to avoid stale counters.
    final totalItems = items.fold<int>(0, (sum, item) => sum + item.quantity);
    final totalPrice = items.fold<double>(
      0,
      (sum, item) => sum + (item.product.price * item.quantity),
    );
    state = CartState(items: items, totalItems: totalItems, totalPrice: totalPrice);
  }

  String _itemKey(Product product) {
    final selectedSize = product.selectedSize?.trim();
    final selectedColor = product.selectedColor?.hexCode.trim();

    if ((selectedSize == null || selectedSize.isEmpty) &&
        (selectedColor == null || selectedColor.isEmpty)) {
      return product.id;
    }

    return '${product.id}::${selectedSize ?? ''}::${selectedColor ?? ''}';
  }
}

final cartProvider = StateNotifierProvider<CartNotifier, CartState>(
  (ref) => CartNotifier(),
);

ProviderContainer createCartTestContainer() {
  return ProviderContainer();
}