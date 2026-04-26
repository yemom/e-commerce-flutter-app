/// Admin-only inventory page that lists products and edit actions.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:e_commerce_app_with_django/core/presentation/widgets/app_formatters.dart';
import 'package:e_commerce_app_with_django/core/presentation/widgets/app_network_image.dart';
import 'package:e_commerce_app_with_django/features/products/domain/models/product.dart';
import 'package:e_commerce_app_with_django/features/products/presentation/providers/product_provider.dart';

class AdminInventoryScreen extends ConsumerStatefulWidget {
  const AdminInventoryScreen({
    super.key,
    required this.isSuperAdmin,
    this.branchId,
  });

  final bool isSuperAdmin;
  final String? branchId;

  @override
  ConsumerState<AdminInventoryScreen> createState() => _AdminInventoryScreenState();
}

class _AdminInventoryScreenState extends ConsumerState<AdminInventoryScreen> {
  @override
  void initState() {
    super.initState();
    Future<void>.microtask(_loadProducts);
  }

  Future<void> _loadProducts() async {
    final notifier = ref.read(productProvider.notifier);
    if (widget.isSuperAdmin) {
      await notifier.loadAllProducts();
      return;
    }
    if (widget.branchId != null && widget.branchId!.isNotEmpty) {
      await notifier.loadProducts(branchId: widget.branchId!);
      return;
    }
    await notifier.loadAllProducts();
  }

  Future<void> _updatePrice(Product product) async {
    final controller = TextEditingController(text: product.price.toStringAsFixed(2));
    final shouldSave = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Update Price - ${product.name}'),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(labelText: 'New price'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('Cancel')),
          ElevatedButton(onPressed: () => Navigator.of(dialogContext).pop(true), child: const Text('Save')),
        ],
      ),
    );

    if (shouldSave != true) {
      return;
    }

    final value = double.tryParse(controller.text.trim());
    if (value == null) {
      return;
    }

    await ref.read(productRepositoryProvider).updateProduct(product.copyWith(price: value));
    await _loadProducts();
  }

  Future<void> _deleteProduct(String productId) async {
    await ref.read(productRepositoryProvider).deleteProduct(productId);
    await _loadProducts();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(productProvider);
    final products = state.products;

    return Scaffold(
      appBar: AppBar(title: const Text('Admin Inventory')),
      body: RefreshIndicator(
        onRefresh: _loadProducts,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 20),
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFBFDBFE)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.inventory_2_outlined, color: Color(0xFF1D4ED8)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '${products.length} product(s) in inventory',
                      style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF1E3A8A)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            if (state.isLoading && products.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 80),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (products.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 80),
                child: Center(child: Text('No products found.')),
              )
            else
              ...products.map(
                (product) => Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFE7ECF3)),
                  ),
                  child: Row(
                    children: [
                      SizedBox(
                        width: 54,
                        height: 54,
                        child: AppNetworkImage(
                          imageUrl: product.imageUrl,
                          borderRadius: BorderRadius.circular(12),
                          placeholderIcon: Icons.inventory_2_outlined,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(product.name, style: Theme.of(context).textTheme.titleSmall),
                            const SizedBox(height: 2),
                            Text(formatPrice(product.price), style: const TextStyle(color: Color(0xFF1D4ED8))),
                          ],
                        ),
                      ),
                      IconButton(
                        tooltip: 'Update price',
                        onPressed: () => _updatePrice(product),
                        icon: const Icon(Icons.edit_outlined),
                      ),
                      IconButton(
                        tooltip: 'Delete product',
                        onPressed: () => _deleteProduct(product.id),
                        icon: const Icon(Icons.delete_outline),
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
