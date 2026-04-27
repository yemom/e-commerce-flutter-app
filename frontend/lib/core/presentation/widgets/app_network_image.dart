/// Reusable network image widget with fallback and placeholder handling.
library;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:e_commerce_app_with_django/core/data/providers.dart';

class AppNetworkImage extends ConsumerWidget {
  const AppNetworkImage({
    super.key,
    required this.imageUrl,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.placeholderIcon = Icons.shopping_bag_outlined,
  });

  final String imageUrl;
  final BoxFit fit;
  final BorderRadius? borderRadius;
  final IconData placeholderIcon;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    String resolvedUrl = imageUrl;

    if (resolvedUrl.isNotEmpty) {
      final baseUrlStr = ref.watch(appApiBaseUrlProvider);
      final baseUrl = Uri.tryParse(baseUrlStr);
      if (baseUrl != null) {
        if (resolvedUrl.startsWith('/')) {
          resolvedUrl = '${baseUrl.scheme}://${baseUrl.host}:${baseUrl.port}$resolvedUrl';
        } else {
          final parsedImage = Uri.tryParse(resolvedUrl);
          if (parsedImage != null && (parsedImage.host == 'localhost' || parsedImage.host == '127.0.0.1' || parsedImage.host == '10.0.2.2')) {
            resolvedUrl = parsedImage.replace(host: baseUrl.host, port: baseUrl.port).toString();
          }
        }
      }
    }

    final image = Image.network(
      resolvedUrl,
      fit: fit,
      errorBuilder: (context, error, stackTrace) => _placeholder(),
      loadingBuilder: (context, child, progress) {
        if (progress == null) {
          return child;
        }
        return _placeholder();
      },
    );

    if (borderRadius == null) {
      return image;
    }

    return ClipRRect(borderRadius: borderRadius!, child: image);
  }

  Widget _placeholder() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF5E56E7), Color(0xFF8B83FF)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Icon(placeholderIcon, color: Colors.white, size: 34),
      ),
    );
  }
}