/// Shows one product in detail with variant and add-to-cart actions.
library;
import 'package:flutter/material.dart';

import 'package:e_commerce_app_with_django/core/presentation/widgets/app_formatters.dart';
import 'package:e_commerce_app_with_django/core/presentation/widgets/app_network_image.dart';
import 'package:e_commerce_app_with_django/features/products/domain/models/product.dart';

class ProductDetailScreen extends StatefulWidget {
  const ProductDetailScreen({
    super.key,
    required this.product,
    required this.onAddToCart,
  });

  final Product product;
  final ValueChanged<Product> onAddToCart;

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  late String? _selectedSize;
  late ProductColorOption? _selectedColor;
  int _quantity = 1;

  @override
  void initState() {
    super.initState();
    // Preselect first available variant values to reduce taps for the user.
    _selectedSize = widget.product.selectedSize ??
        (widget.product.availableSizes.isEmpty ? null : widget.product.availableSizes.first);
    _selectedColor = widget.product.selectedColor ??
        (widget.product.availableColors.isEmpty ? null : widget.product.availableColors.first);
  }

  @override
  Widget build(BuildContext context) {
    final product = widget.product;
    final screenHeight = MediaQuery.sizeOf(context).height;
    final topSectionHeight = screenHeight * 0.52;

    return Scaffold(
      backgroundColor: const Color(0xFFF3F4F8),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
          decoration: const BoxDecoration(color: Colors.white),
          child: ElevatedButton.icon(
            onPressed: () => _addSelectedProductToCart(product),
            style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(54)),
            icon: const Icon(Icons.shopping_bag_outlined),
            label: Text('Add to Cart • ${formatPrice(product.price)}'),
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(
              height: topSectionHeight,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: Column(
                  children: [
                    Row(
                      children: [
                        _CircleAction(
                          icon: Icons.arrow_back_ios_new_rounded,
                          onTap: () => Navigator.of(context).pop(),
                        ),
                        const Spacer(),
                        const Text(
                          'Detail Product',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: Color(0xFF23263B)),
                        ),
                        const Spacer(),
                        const _CircleAction(icon: Icons.shopping_bag_outlined),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: Hero(
                        tag: 'product-image-${product.id}',
                        child: AppNetworkImage(
                          imageUrl: product.imageUrl,
                          fit: BoxFit.contain,
                          borderRadius: BorderRadius.circular(24),
                          placeholderIcon: Icons.shopping_bag_outlined,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(top: Radius.circular(34)),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              product.name,
                              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                            ),
                          ),
                          Container(
                            decoration: BoxDecoration(
                              color: const Color(0xFFF3F4F8),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                            child: Row(
                              children: [
                                _QtyButton(
                                  icon: Icons.remove,
                                  onTap: () {
                                    if (_quantity > 1) {
                                      setState(() => _quantity--);
                                    }
                                  },
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(horizontal: 10),
                                  child: Text('$_quantity', style: const TextStyle(fontWeight: FontWeight.w700)),
                                ),
                                _QtyButton(
                                  icon: Icons.add,
                                  onTap: () => setState(() => _quantity++),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: const [
                          Icon(Icons.star_rounded, size: 18, color: Color(0xFFF6B60A)),
                          SizedBox(width: 4),
                          Text('4.8', style: TextStyle(fontWeight: FontWeight.w700)),
                          SizedBox(width: 6),
                          Text('(320 Review)', style: TextStyle(color: Color(0xFF9AA1B2))),
                          Spacer(),
                          Text('Available in stok', style: TextStyle(fontWeight: FontWeight.w600)),
                        ],
                      ),
                      if (product.availableColors.isNotEmpty) ...[
                        const SizedBox(height: 18),
                        Text('Color', style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 14,
                          runSpacing: 10,
                          children: [
                            for (final color in product.availableColors)
                              InkWell(
                                borderRadius: BorderRadius.circular(999),
                                onTap: () => setState(() => _selectedColor = color),
                                child: Stack(
                                  alignment: Alignment.center,
                                  children: [
                                    Container(
                                      width: 42,
                                      height: 42,
                                      decoration: BoxDecoration(
                                        color: _hexToColor(color.hexCode),
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    if (_selectedColor == color)
                                      const Icon(Icons.check_rounded, color: Colors.white),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ],
                      if (product.availableSizes.isNotEmpty) ...[
                        const SizedBox(height: 18),
                        Text('Size', style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 10,
                          runSpacing: 10,
                          children: [
                            for (final size in product.availableSizes)
                              ChoiceChip(
                                label: Text(size),
                                selected: _selectedSize == size,
                                onSelected: (_) => setState(() => _selectedSize = size),
                              ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 18),
                      Text('Description', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 8),
                      Text(
                        product.description,
                        style: const TextStyle(height: 1.6, color: Color(0xFF6E7486)),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        formatPrice(product.price),
                        style: const TextStyle(fontSize: 26, fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _addSelectedProductToCart(Product product) {
    // Add one cart item per selected quantity while preserving chosen variants.
    for (var i = 0; i < _quantity; i++) {
      widget.onAddToCart(
        product.copyWith(
          selectedSize: _selectedSize,
          selectedColor: _selectedColor,
        ),
      );
    }

    if (mounted) {
      final navigator = Navigator.of(context);
      if (navigator.canPop()) {
        navigator.pop();
      }
    }
  }
}

Color _hexToColor(String hexCode) {
  final normalized = hexCode.replaceAll('#', '');
  final buffer = StringBuffer();
  if (normalized.length == 6) {
    buffer.write('ff');
  }
  buffer.write(normalized);
  return Color(int.parse(buffer.toString(), radix: 16));
}

class _CircleAction extends StatelessWidget {
  const _CircleAction({required this.icon, this.onTap});

  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Ink(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(999),
        ),
        child: Icon(icon, color: const Color(0xFF23263B)),
      ),
    );
  }
}

class _QtyButton extends StatelessWidget {
  const _QtyButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(20),
      onTap: onTap,
      child: Ink(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Icon(icon, size: 16, color: const Color(0xFF23263B)),
      ),
    );
  }
}

