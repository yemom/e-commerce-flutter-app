/// Admin-only inventory page that lists products and edit actions.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:e_commerce_app_with_django/core/presentation/widgets/app_formatters.dart';
import 'package:e_commerce_app_with_django/core/presentation/widgets/product_image_gallery.dart';
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
  ConsumerState<AdminInventoryScreen> createState() =>
      _AdminInventoryScreenState();
}

class _AdminInventoryScreenState extends ConsumerState<AdminInventoryScreen> {
  @override
  void initState() {
    super.initState();
    Future<void>.microtask(_loadProducts);
  }

  Future<void> _loadProducts() async {
    // Super admins can see the full catalog, while branch admins only see the branch-scoped subset.
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

  Future<void> _updateProduct(Product product) async {
    // Keep the inventory edit flow focused on the fields admins change most often.
    final priceController = TextEditingController(
      text: product.price.toStringAsFixed(2),
    );

    final descriptionController = TextEditingController(
      text: product.description,
    );

    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: Text('Update Product - ${product.name}'),

          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Keep the description editable inline so the admin can fix copy without leaving the list.
              TextField(
                controller: descriptionController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Update Description',
                ),
              ),

              const SizedBox(height: 12),

              // Price stays in the same dialog because inventory edits usually update text and pricing together.
              TextField(
                controller: priceController,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(labelText: 'New Price'),
              ),
            ],
          ),

          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Cancel'),
            ),

            ElevatedButton(
              onPressed: () {
                final price = double.tryParse(priceController.text.trim());

                if (price == null) return;

                Navigator.of(dialogContext).pop({
                  "price": price,
                  "description": descriptionController.text.trim(),
                });
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );

    // Stop here if the dialog was dismissed without saving.
    if (result == null) return;

    // Save the updated values, then reload the list so the visible card matches the stored product.
    await ref
        .read(productRepositoryProvider)
        .updateProduct(
          product.copyWith(
            price: result["price"],
            description: result["description"],
          ),
        );

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
                  const Icon(
                    Icons.inventory_2_outlined,
                    color: Color(0xFF1D4ED8),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      '${products.length} product(s) in inventory',
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF1E3A8A),
                      ),
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Show a compact horizontally scrollable strip so inventory users can preview multiple product shots.
                      SizedBox(
                        height: 76,
                        child: ProductImageGallery(
                          imageUrls: product.imageUrls,
                          fallbackImageUrl: product.imageUrl,
                          height: 76,
                          itemWidth: 112,
                          spacing: 8,
                          borderRadius: BorderRadius.circular(14),
                          placeholderIcon: Icons.inventory_2_outlined,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  product.name,
                                  style: Theme.of(context).textTheme.titleSmall,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  formatPrice(product.price),
                                  style: const TextStyle(color: Color(0xFF1D4ED8)),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            tooltip: 'Update product',
                            onPressed: () => _updateProduct(product),
                            icon: const Icon(Icons.edit_outlined),
                          ),
                          IconButton(
                            tooltip: 'Delete product',
                            onPressed: () => _deleteProduct(product.id),
                            icon: const Icon(Icons.delete_outline),
                          ),
                        ],
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
