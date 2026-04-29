/// Renders one or more product images in a horizontally scrollable strip.
library;

import 'package:flutter/material.dart';

import 'package:e_commerce_app_with_django/core/presentation/widgets/app_network_image.dart';

class ProductImageGallery extends StatelessWidget {
  const ProductImageGallery({
    super.key,
    required this.imageUrls,
    required this.fallbackImageUrl,
    this.height = 100,
    this.itemWidth = 120,
    this.spacing = 12,
    this.borderRadius,
    this.placeholderIcon = Icons.shopping_bag_outlined,
  });

  final List<String> imageUrls;
  final String fallbackImageUrl;
  final double height;
  final double itemWidth;
  final double spacing;
  final BorderRadius? borderRadius;
  final IconData placeholderIcon;

  @override
  Widget build(BuildContext context) {
    final displayImages = imageUrls
        .where((url) => url.trim().isNotEmpty)
        .toList(growable: false);
    final urls = displayImages.isEmpty
        ? <String>[fallbackImageUrl]
        : displayImages;

    return ListView.separated(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      itemCount: urls.length,
      separatorBuilder: (_, __) => SizedBox(width: spacing),
      itemBuilder: (context, index) {
        final imageUrl = urls[index];
        return SizedBox(
          key: ValueKey('product-gallery.image.$index'),
          width: itemWidth,
          height: height,
          child: AppNetworkImage(
            imageUrl: imageUrl,
            fit: BoxFit.cover,
            borderRadius: borderRadius ?? BorderRadius.circular(18),
            placeholderIcon: placeholderIcon,
          ),
        );
      },
    );
  }
}
