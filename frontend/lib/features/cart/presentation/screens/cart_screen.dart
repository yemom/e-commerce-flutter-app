/// Shows cart items, quantity controls, and checkout entry.
library;
import 'package:flutter/material.dart';

import 'package:e_commerce_app_with_django/core/presentation/widgets/app_formatters.dart';
import 'package:e_commerce_app_with_django/core/presentation/widgets/app_network_image.dart';
import 'package:e_commerce_app_with_django/features/cart/presentation/providers/cart_provider.dart';
import 'package:e_commerce_app_with_django/features/products/domain/models/product.dart';

/// Screen for Cart.
class CartScreen extends StatelessWidget {
  const CartScreen({
    super.key,
    required this.state,
    required this.onQuantityChanged,
    required this.onRemoveProduct,
    required this.onCheckout,
  });

  final CartState state;
  final void Function({required String productId, required int quantity}) onQuantityChanged;
  final ValueChanged<String> onRemoveProduct;
  final VoidCallback onCheckout;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('My Cart')),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF0EEFF), Color(0xFFF7F8FC), Color(0xFFF7F8FC)],
            stops: [0, .18, .18],
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFF5E56E7), Color(0xFF756DF2)]),
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Order review',
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'My Cart',
                      style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.w800),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '${state.totalItems} items ready for checkout',
                      style: const TextStyle(color: Color(0xFFDCDDFF)),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                // Empty state when nothing has been added to cart yet.
                child: state.items.isEmpty
                    ? const Center(child: Text('Your cart is empty. Add items to continue.'))
                    : ListView.separated(
                        itemCount: state.items.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 14),
                        itemBuilder: (context, index) {
                          final item = state.items[index];
                          final itemKey = _cartItemKey(item.product);
                          return Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(28),
                              border: Border.all(color: const Color(0xFFE7ECF3)),
                            ),
                            child: Row(
                              children: [
                                SizedBox(
                                  width: 72,
                                  height: 72,
                                  child: AppNetworkImage(
                                    imageUrl: item.product.imageUrl,
                                    borderRadius: BorderRadius.circular(22),
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(item.product.name, style: Theme.of(context).textTheme.titleMedium),
                                      const SizedBox(height: 4),
                                      if (_variantLabel(item.product).isNotEmpty)
                                        Padding(
                                          padding: const EdgeInsets.only(bottom: 4),
                                          child: Text(
                                            _variantLabel(item.product),
                                            style: const TextStyle(fontSize: 12, color: Color(0xFF7C8799)),
                                          ),
                                        ),
                                      Text(
                                        formatPrice(item.product.price),
                                        style: const TextStyle(
                                          color: Color(0xFF5E56E7),
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const SizedBox(height: 10),
                                      Container(
                                        decoration: BoxDecoration(
                                          color: const Color(0xFFF2F3F8),
                                          borderRadius: BorderRadius.circular(999),
                                        ),
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            IconButton(
                                              visualDensity: VisualDensity.compact,
                                              onPressed: item.quantity > 1
                                                  ? () => onQuantityChanged(
                                                        productId: itemKey,
                                                        quantity: item.quantity - 1,
                                                      )
                                                  : null,
                                              icon: const Icon(Icons.remove_rounded),
                                            ),
                                            Text('${item.quantity}', style: const TextStyle(fontWeight: FontWeight.w700)),
                                            IconButton(
                                              key: Key('cart.increment.$itemKey'),
                                              visualDensity: VisualDensity.compact,
                                              onPressed: () => onQuantityChanged(
                                                productId: itemKey,
                                                quantity: item.quantity + 1,
                                              ),
                                              icon: const Icon(Icons.add_rounded),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  key: Key('cart.remove.$itemKey'),
                                  onPressed: () => onRemoveProduct(itemKey),
                                  icon: const Icon(Icons.close_rounded),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
              ),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: const Color(0xFFE7ECF3)),
                ),
                child: Column(
                  children: [
                    _SummaryRow(label: 'Subtotal', value: formatPrice(state.totalPrice)),
                    const SizedBox(height: 10),
                    const _SummaryRow(label: 'Delivery Fee', value: 'ETB 50.00'),
                    const Padding(
                      padding: EdgeInsets.symmetric(vertical: 12),
                      child: Divider(height: 1),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Total', style: TextStyle(fontWeight: FontWeight.w700)),
                        Text(
                          formatPrice(state.totalPrice + 50),
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    ElevatedButton(
                      key: const Key('cart.checkout-button'),
                      onPressed: state.items.isEmpty ? null : onCheckout,
                      child: const Text('Checkout'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String _cartItemKey(Product product) {
  final selectedSize = product.selectedSize?.trim();
  final selectedColor = product.selectedColor?.hexCode.trim();

  if ((selectedSize == null || selectedSize.isEmpty) &&
      (selectedColor == null || selectedColor.isEmpty)) {
    return product.id;
  }

  return '${product.id}::${selectedSize ?? ''}::${selectedColor ?? ''}';
}

String _variantLabel(Product product) {
  final parts = <String>[];
  if (product.selectedSize != null && product.selectedSize!.isNotEmpty) {
    parts.add('Size ${product.selectedSize!}');
  }
  if (product.selectedColor != null) {
    parts.add(product.selectedColor!.name);
  }
  return parts.join(' • ');
}

class _SummaryRow extends StatelessWidget {
  const _SummaryRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label),
        Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
      ],
    );
  }
}
