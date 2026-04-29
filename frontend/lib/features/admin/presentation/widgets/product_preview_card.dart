// Small add-product preview card that mirrors the form state for quick review.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:e_commerce_app_with_django/core/presentation/widgets/product_image_gallery.dart';
import '../providers/add_product_provider.dart';

class ProductPreviewCard extends ConsumerWidget {
  const ProductPreviewCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // The preview reflects the same image list the admin is building in the form.
    final state = ref.watch(addProductProvider);

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(
              height: 84,
              child: ProductImageGallery(
                imageUrls: state.imageUrls,
                // Use the same fallback image as the main form so the preview stays visually stable when no custom image is selected.
                fallbackImageUrl: 'https://images.unsplash.com/photo-1523275335684-37898b6baf30',
                height: 84,
                itemWidth: 120,
                spacing: 8,
                borderRadius: BorderRadius.circular(14),
                placeholderIcon: Icons.image,
              ),
            ),
            const SizedBox(height: 12),
            Text(state.name.isEmpty ? 'Preview' : state.name),
            const SizedBox(height: 4),
            Text(
              state.description.isEmpty ? 'No description' : state.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Text('ETB ${state.price.toStringAsFixed(2)}'),
          ],
        ),
      ),
    );
  }
}
