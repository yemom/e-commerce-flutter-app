import 'package:e_commerce_app_with_django/features/admin/presentation/providers/add_product_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class ProductImagePicker extends ConsumerWidget {
  final Future<String> Function() onPickImage;

  const ProductImagePicker({super.key, required this.onPickImage});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final images = ref.watch(addProductProvider).imageUrls;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("Images", style: TextStyle(fontSize: 18)),

        const SizedBox(height: 10),

        Wrap(
          spacing: 10,
          children: [
            ...images.map(
              (url) => Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(
                      url,
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                    ),
                  ),
                  Positioned(
                    right: 0,
                    child: GestureDetector(
                      onTap: () {
                        ref.read(addProductProvider.notifier).removeImage(url);
                      },
                      child: const CircleAvatar(
                        radius: 10,
                        backgroundColor: Colors.red,
                        child: Icon(Icons.close, size: 12, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            GestureDetector(
              onTap: () async {
                final url = await onPickImage();
                ref.read(addProductProvider.notifier).addImage(url);
              },
              child: Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  border: Border.all(),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.add),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
