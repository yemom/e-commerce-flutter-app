// Helps admins create a product, upload an image, and choose branches and variants.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' show ClientException;

import 'package:e_commerce_app_with_django/core/data/datasources/commerce_api_data_source.dart';
import 'package:e_commerce_app_with_django/core/presentation/widgets/app_network_image.dart';
import 'package:e_commerce_app_with_django/core/presentation/widgets/product_image_gallery.dart';
import 'package:e_commerce_app_with_django/features/branches/domain/models/branch.dart';
import 'package:e_commerce_app_with_django/features/categories/domain/models/category.dart';
import 'package:e_commerce_app_with_django/features/products/domain/models/product.dart';

/// Screen for Add Product.
class AddProductScreen extends StatefulWidget {
  const AddProductScreen({
    super.key,
    required this.categories,
    required this.branches,
    required this.onUploadImage,
    required this.onSubmit,
  });

  final List<Category> categories;
  final List<Branch> branches;
  final Future<String> Function({
    required List<int> bytes,
    required String fileName,
  })
  onUploadImage;
  final Future<void> Function(Product) onSubmit;

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

/// Lets admins create a new product with image, branches, and variants.

class _AddProductScreenState extends State<AddProductScreen> {
  // Form controllers keep current draft values while admin edits fields.
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final _imageUrlController = TextEditingController(
    text: 'https://images.unsplash.com/photo-1523275335684-37898b6baf30',
  );
  final List<String> _selectedImageUrls = <String>[];
  String? _selectedCategoryId;
  final Set<String> _selectedBranchIds = <String>{};
  final Set<String> _selectedSizes = <String>{'Medium'};
  final Set<ProductColorOption> _selectedColors = <ProductColorOption>{
    const ProductColorOption(name: 'Coral', hexCode: '#F97316'),
  };
  bool _submitted = false;
  bool _isSaving = false;
  // Separate loading state so admins can still edit fields while image upload runs.
  bool _isUploadingImage = false;

  static const List<String> _sizePresets = [
    'Small',
    'Medium',
    'Large',
    '1kg',
    '2L',
    '13"',
    '14.1"',
    '15.6"',
    '33"',
    '42"',
    '55"',
  ];
  static const List<ProductColorOption> _colorPresets = [
    ProductColorOption(name: 'Coral', hexCode: '#F97316'),
    ProductColorOption(name: 'Graphite', hexCode: '#1F2937'),
    ProductColorOption(name: 'Cream', hexCode: '#DCC7A1'),
    ProductColorOption(name: 'Olive', hexCode: '#61764B'),
    ProductColorOption(name: 'White', hexCode: '#F8FAFC'),
    ProductColorOption(name: 'Black', hexCode: '#000000'),
    ProductColorOption(name: 'Gray', hexCode: '#6B7280'),
    ProductColorOption(name: 'Silver', hexCode: '#C0C0C0'),
    ProductColorOption(name: 'Navy', hexCode: '#000080'),
    ProductColorOption(name: 'Maroon', hexCode: '#800000'),
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _imageUrlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Show required-field hints only after first submit attempt.
    final showNameError = _submitted && _nameController.text.trim().isEmpty;
    final showPriceError = _submitted && _priceController.text.trim().isEmpty;
    final showBranchError = _submitted && _selectedBranchIds.isEmpty;
    final previewImageUrls = _previewImageUrls();

    return Scaffold(
      appBar: AppBar(title: const Text('Add product')),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF0EEFF), Color(0xFFF7F8FC), Color(0xFFF7F8FC)],
            stops: [0, .16, .16],
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF5E56E7), Color(0xFF756DF2)],
                ),
                borderRadius: BorderRadius.circular(30),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Catalog editor',
                    style: TextStyle(color: Color(0xFFDCDDFF), fontSize: 13),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Create a polished product entry',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      height: 1.1,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(28),
                border: Border.all(color: const Color(0xFFE7ECF3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF8F8FC),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          height: 118,
                          child: ProductImageGallery(
                            imageUrls: previewImageUrls,
                            fallbackImageUrl:
                                'https://images.unsplash.com/photo-1523275335684-37898b6baf30',
                            height: 118,
                            itemWidth: 154,
                            borderRadius: BorderRadius.circular(22),
                            placeholderIcon: Icons.inventory_2_outlined,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _nameController.text.trim().isEmpty
                              ? 'Product preview'
                              : _nameController.text.trim(),
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          _descriptionController.text.trim().isEmpty
                              ? 'Image, variants, branches, and pricing all in one place.'
                              : _descriptionController.text.trim(),
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Color(0xFF7C8799)),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          _priceController.text.trim().isEmpty
                              ? 'ETB 0.00'
                              : 'ETB ${_priceController.text.trim()}.00',
                          style: const TextStyle(
                            color: Color(0xFF5E56E7),
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    key: const Key('add-product.name-field'),
                    controller: _nameController,
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(
                      labelText: 'Product name',
                    ),
                  ),
                  if (showNameError)
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Please enter a product name.',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
                  TextField(
                    key: const Key('add-product.description-field'),
                    controller: _descriptionController,
                    onChanged: (_) => setState(() {}),
                    maxLines: 3,
                    decoration: const InputDecoration(labelText: 'Description'),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    key: const Key('add-product.price-field'),
                    controller: _priceController,
                    onChanged: (_) => setState(() {}),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    decoration: const InputDecoration(labelText: 'Price'),
                  ),
                  if (showPriceError)
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Please enter a product price.',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ),
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: OutlinedButton.icon(
                      key: const Key('add-product.pick-image-button'),
                      onPressed: _isSaving || _isUploadingImage
                          ? null
                          : _pickImagesFromDevice,
                      icon: const Icon(Icons.photo_library_outlined),
                      label: Text(
                        _isUploadingImage
                            ? 'Uploading images...'
                            : 'Select from device',
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: TextField(
                          key: const Key('add-product.image-field'),
                          controller: _imageUrlController,
                          onChanged: (_) => setState(() {}),
                          decoration: const InputDecoration(
                            labelText: 'Image URL (optional)',
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: OutlinedButton.icon(
                          onPressed: _isSaving || _isUploadingImage
                              ? null
                              : _addImageUrl,
                          icon: const Icon(Icons.add_photo_alternate_outlined),
                          label: const Text('Add URL'),
                        ),
                      ),
                    ],
                  ),
                  if (previewImageUrls.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    SizedBox(
                      height: 92,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: previewImageUrls.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 10),
                        itemBuilder: (context, index) {
                          final imageUrl = previewImageUrls[index];
                          return Stack(
                            clipBehavior: Clip.none,
                            children: [
                              SizedBox(
                                width: 92,
                                height: 92,
                                child: AppNetworkImage(
                                  imageUrl: imageUrl,
                                  borderRadius: BorderRadius.circular(18),
                                  placeholderIcon: Icons.image_outlined,
                                ),
                              ),
                              Positioned(
                                right: -6,
                                top: -6,
                                child: Material(
                                  color: Colors.white,
                                  shape: const CircleBorder(),
                                  child: InkWell(
                                    customBorder: const CircleBorder(),
                                    onTap: _isSaving || _isUploadingImage
                                        ? null
                                        : () => _removeImageUrl(imageUrl),
                                    child: const Padding(
                                      padding: EdgeInsets.all(4),
                                      child: Icon(
                                        Icons.close,
                                        size: 16,
                                        color: Colors.red,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                  ],
                  if (_isUploadingImage)
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: LinearProgressIndicator(minHeight: 3),
                    ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<String>(
                    key: const Key('add-product.category-field'),
                    initialValue: _selectedCategoryId,
                    items: widget.categories
                        .map(
                          (category) => DropdownMenuItem<String>(
                            value: category.id,
                            child: Text(category.name),
                          ),
                        )
                        .toList(),
                    onChanged: (value) =>
                        setState(() => _selectedCategoryId = value),
                    decoration: const InputDecoration(labelText: 'Category'),
                  ),
                  const SizedBox(height: 18),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Sizes',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      for (final size in _sizePresets)
                        FilterChip(
                          label: Text(size),
                          selected: _selectedSizes.contains(size),
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _selectedSizes.add(size);
                              } else {
                                _selectedSizes.remove(size);
                              }
                            });
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Colors',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      for (final color in _colorPresets)
                        FilterChip(
                          label: Text(color.name),
                          avatar: CircleAvatar(
                            backgroundColor: _hexToColor(color.hexCode),
                            radius: 8,
                          ),
                          selected: _selectedColors.contains(color),
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _selectedColors.add(color);
                              } else {
                                _selectedColors.remove(color);
                              }
                            });
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Branches',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      for (final branch in widget.branches)
                        FilterChip(
                          key: Key('add-product.branch.${branch.id}'),
                          label: Text(branch.name),
                          selectedColor: const Color(0xFF5E56E7),
                          labelStyle: TextStyle(
                            color: _selectedBranchIds.contains(branch.id)
                                ? Colors.white
                                : const Color(0xFF0F172A),
                            fontWeight: FontWeight.w700,
                          ),
                          selected: _selectedBranchIds.contains(branch.id),
                          onSelected: (selected) {
                            setState(() {
                              if (selected) {
                                _selectedBranchIds.add(branch.id);
                              } else {
                                _selectedBranchIds.remove(branch.id);
                              }
                            });
                          },
                        ),
                    ],
                  ),
                  if (showBranchError)
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Please select at least one branch.',
                          style: TextStyle(color: Colors.red),
                        ),
                      ),
                    ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    key: const Key('add-product.submit-button'),
                    onPressed: _isSaving ? null : _handleSubmit,
                    child: _isSaving
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Save product'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _handleSubmit() async {
    if (_isSaving) {
      return;
    }

    setState(() => _submitted = true);

    if (_nameController.text.trim().isEmpty ||
        _priceController.text.trim().isEmpty ||
        _selectedBranchIds.isEmpty) {
      return;
    }

    final price = double.tryParse(_priceController.text.trim());
    if (price == null) {
      return;
    }

    final name = _nameController.text.trim();
    // Product IDs are slugified from name for stable readable identifiers.
    final generatedId = name.toLowerCase().replaceAll(
      RegExp(r'[^a-z0-9]+'),
      '-',
    );
    final imageUrls = _previewImageUrls();
    final primaryImageUrl = imageUrls.isNotEmpty
        ? imageUrls.first
        : 'https://images.unsplash.com/photo-1523275335684-37898b6baf30';

    // Disable submit button while save request runs.
    setState(() => _isSaving = true);
    try {
      await widget.onSubmit(
        Product(
          id: 'prod-$generatedId',
          name: name,
          description: _descriptionController.text.trim(),
          imageUrl: primaryImageUrl,
          price: price,
          categoryId: _selectedCategoryId ?? widget.categories.first.id,
          branchIds: _selectedBranchIds.toList(),
          stockByBranch: {
            for (final branchId in _selectedBranchIds) branchId: 1,
          },
          isAvailable: true,
          availableSizes: _selectedSizes.toList(),
          availableColors: _selectedColors.toList(),
          imageUrls: imageUrls,
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('We could not save this product. Please try again.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _pickImagesFromDevice() async {
    try {
      // Open system file picker.
      final result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['jpg', 'jpeg', 'png', 'webp', 'gif'],
        allowMultiple: true,
        withData: true,
      );

      if (result == null || result.files.isEmpty) {
        return;
      }

      if (!mounted) {
        return;
      }

      // Upload selected files immediately and store only the URLs in product data.
      setState(() => _isUploadingImage = true);
      final uploadedUrls = <String>[];

      for (final file in result.files) {
        final bytes = file.bytes;
        final extension = _fileExtension(
          file.name.isNotEmpty ? file.name : file.path ?? '',
        );

        if (!_isSupportedImageExtension(extension)) {
          throw const FormatException(
            'Only JPG, JPEG, PNG, WEBP, and GIF images are supported for device selection.',
          );
        }

        if (bytes == null) {
          throw const FormatException(
            'Could not read file bytes. Ensure file is not empty or corrupted.',
          );
        }

        final safeFileName = _normalizeImageFileName(
          preferredName: file.name,
          fallbackPath: file.path ?? '',
        );

        final uploadedUrl = await widget.onUploadImage(
          bytes: bytes,
          fileName: safeFileName,
        );
        uploadedUrls.add(uploadedUrl);
      }

      if (!mounted) {
        return;
      }

      setState(() {
        _selectedImageUrls.addAll(uploadedUrls);
        _imageUrlController.clear();
      });
    } on MissingPluginException {
      // Usually happens after adding a plugin without restarting the app process.
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'File picker plugin is not loaded. Stop and re-run the app after flutter pub get.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_friendlyUploadErrorMessage(error))),
      );
    } finally {
      if (mounted) {
        setState(() => _isUploadingImage = false);
      }
    }
  }

  List<String> _previewImageUrls() {
    final urls = <String>[
      ..._selectedImageUrls,
      _imageUrlController.text.trim(),
    ];

    return urls
        .map((url) => url.trim())
        .where((url) => url.isNotEmpty)
        .toSet()
        .toList();
  }

  void _addImageUrl() {
    final imageUrl = _imageUrlController.text.trim();
    if (imageUrl.isEmpty) {
      return;
    }

    setState(() {
      if (!_selectedImageUrls.contains(imageUrl)) {
        _selectedImageUrls.add(imageUrl);
      }
      _imageUrlController.clear();
    });
  }

  void _removeImageUrl(String imageUrl) {
    setState(() {
      _selectedImageUrls.remove(imageUrl);
      if (_imageUrlController.text.trim() == imageUrl) {
        _imageUrlController.clear();
      }
    });
  }
}

String _friendlyUploadErrorMessage(Object error) {
  if (error is ClientException) {
    return 'Could not reach the upload server. On a real Android device, set APP_API_BASE_URL to your computer\'s LAN IP instead of localhost or 10.0.2.2.';
  }

  if (error is StateError &&
      error.message.toString().contains('APP_API_BASE_URL')) {
    return 'Backend API is not configured. Start the server and set APP_API_BASE_URL before uploading images.';
  }

  if (error is CommerceApiException) {
    final message = error.message.trim().toLowerCase();
    if (error.statusCode == 413 ||
        message.contains('too large') ||
        message.contains('file size')) {
      return 'Image too large, choose one under 10MB.';
    }
    if (error.statusCode == 400 && message.contains('only image uploads')) {
      return 'Please select a valid image file.';
    }
    if (error.statusCode != null && error.statusCode! >= 500) {
      return 'Server error during upload. Please try again.';
    }
    if (error.message.trim().isNotEmpty) {
      return error.message.trim();
    }
  }

  if (error is FormatException && error.message.isNotEmpty) {
    return error.message;
  }

  return 'Unable to upload image. Please try again.';
}

String _safeFileNameFromPath(String path) {
  // Use a stable fallback filename if platform picker returns an empty path segment.
  final normalized = path.replaceAll('\\', '/');
  final segments = normalized
      .split('/')
      .where((segment) => segment.isNotEmpty)
      .toList();
  if (segments.isEmpty) {
    return 'product-image.jpg';
  }

  final candidate = segments.last.trim();
  return candidate.isEmpty ? 'product-image.jpg' : candidate;
}

String _normalizeImageFileName({
  required String preferredName,
  required String fallbackPath,
}) {
  final raw = preferredName.trim().isNotEmpty
      ? preferredName.trim()
      : _safeFileNameFromPath(fallbackPath);

  final normalized = raw.replaceAll('\\', '/');
  final baseName = normalized.split('/').last.trim();
  final lower = baseName.toLowerCase();

  if (lower.endsWith('.jpg') ||
      lower.endsWith('.jpeg') ||
      lower.endsWith('.png') ||
      lower.endsWith('.webp') ||
      lower.endsWith('.gif') ||
      lower.endsWith('.heic') ||
      lower.endsWith('.heif')) {
    return baseName;
  }

  return '${baseName.isEmpty ? 'product-image' : baseName}.jpg';
}

String _fileExtension(String value) {
  final normalized = value.replaceAll('\\', '/');
  final fileName = normalized.split('/').last.trim().toLowerCase();
  final dotIndex = fileName.lastIndexOf('.');
  if (dotIndex < 0 || dotIndex == fileName.length - 1) {
    return '';
  }
  return fileName.substring(dotIndex);
}

bool _isSupportedImageExtension(String extension) {
  return const {
    '.jpg',
    '.jpeg',
    '.png',
    '.webp',
    '.gif',
  }.contains(extension.toLowerCase());
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
