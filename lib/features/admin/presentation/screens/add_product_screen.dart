
import 'dart:async';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import 'package:e_commerce_app_with_django/core/presentation/widgets/app_network_image.dart';
import 'package:e_commerce_app_with_django/features/branches/domain/models/branch.dart';
import 'package:e_commerce_app_with_django/features/categories/domain/models/category.dart';
import 'package:e_commerce_app_with_django/features/products/domain/models/product.dart';
import 'package:e_commerce_app_with_django/firebase_options.dart';

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({
    super.key,
    required this.categories,
    required this.branches,
    required this.onSubmit,
  });

  final List<Category> categories;
  final List<Branch> branches;
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
  final _imagePicker = ImagePicker();
  String? _selectedCategoryId;
  String? _selectedImageName;
  final Set<String> _selectedBranchIds = <String>{};
  final Set<String> _selectedSizes = <String>{'Medium'};
  final Set<ProductColorOption> _selectedColors = <ProductColorOption>{
    const ProductColorOption(name: 'Coral', hexCode: '#F97316'),
  };
  bool _submitted = false;
  bool _isSaving = false;
  bool _isPickingImage = false;

  FirebaseStorage get _storage =>
      FirebaseStorage.instanceFor(bucket: DefaultFirebaseOptions.currentPlatform.storageBucket);

  static const List<String> _sizePresets = ['Small', 'Medium', 'Large', '1kg', '2L'];
  static const List<ProductColorOption> _colorPresets = [
    ProductColorOption(name: 'Coral', hexCode: '#F97316'),
    ProductColorOption(name: 'Graphite', hexCode: '#1F2937'),
    ProductColorOption(name: 'Cream', hexCode: '#DCC7A1'),
    ProductColorOption(name: 'Olive', hexCode: '#61764B'),
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
                gradient: const LinearGradient(colors: [Color(0xFF5E56E7), Color(0xFF756DF2)]),
                borderRadius: BorderRadius.circular(30),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Catalog editor', style: TextStyle(color: Color(0xFFDCDDFF), fontSize: 13)),
                  SizedBox(height: 6),
                  Text(
                    'Create a polished product entry',
                    style: TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w800, height: 1.1),
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
                    child: Row(
                      children: [
                        SizedBox(
                          width: 96,
                          height: 96,
                          child: AppNetworkImage(
                            imageUrl: _imageUrlController.text,
                            borderRadius: BorderRadius.circular(22),
                            placeholderIcon: Icons.inventory_2_outlined,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _nameController.text.trim().isEmpty ? 'Product preview' : _nameController.text.trim(),
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
                                _priceController.text.trim().isEmpty ? 'ETB 0.00' : 'ETB ${_priceController.text.trim()}.00',
                                style: const TextStyle(
                                  color: Color(0xFF5E56E7),
                                  fontWeight: FontWeight.w800,
                                  fontSize: 16,
                                ),
                              ),
                            ],
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
                    decoration: const InputDecoration(labelText: 'Product name'),
                  ),
                  if (showNameError)
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text('Please enter a product name.', style: TextStyle(color: Colors.red)),
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
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Price'),
                  ),
                  if (showPriceError)
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text('Please enter a product price.', style: TextStyle(color: Colors.red)),
                      ),
                    ),
                  const SizedBox(height: 16),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: OutlinedButton.icon(
                      key: const Key('add-product.pick-image-button'),
                      onPressed: _isSaving || _isPickingImage ? null : _showImageSourcePicker,
                      icon: _isPickingImage
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.add_a_photo_outlined),
                      label: Text(_isPickingImage ? 'Selecting image...' : 'Choose image (camera or gallery)'),
                    ),
                  ),
                  if (_selectedImageName != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          'Selected: $_selectedImageName',
                          style: const TextStyle(color: Color(0xFF475569)),
                        ),
                      ),
                    ),
                  const SizedBox(height: 12),
                  TextField(
                    key: const Key('add-product.image-field'),
                    controller: _imageUrlController,
                    onChanged: (_) => setState(() {}),
                    decoration: const InputDecoration(labelText: 'Image URL (optional)'),
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
                    onChanged: (value) => setState(() => _selectedCategoryId = value),
                    decoration: const InputDecoration(labelText: 'Category'),
                  ),
                  const SizedBox(height: 18),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text('Sizes', style: Theme.of(context).textTheme.titleMedium),
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
                    child: Text('Colors', style: Theme.of(context).textTheme.titleMedium),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      for (final color in _colorPresets)
                        FilterChip(
                          label: Text(color.name),
                          avatar: CircleAvatar(backgroundColor: _hexToColor(color.hexCode), radius: 8),
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
                    child: Text('Branches', style: Theme.of(context).textTheme.titleMedium),
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
                            color: _selectedBranchIds.contains(branch.id) ? Colors.white : const Color(0xFF0F172A),
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
                        child: Text('Please select at least one branch.', style: TextStyle(color: Colors.red)),
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

  Future<void> _showImageSourcePicker() async {
    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library_outlined),
              title: const Text('Choose from gallery'),
              onTap: () => Navigator.of(sheetContext).pop(ImageSource.gallery),
            ),
            ListTile(
              leading: const Icon(Icons.photo_camera_outlined),
              title: const Text('Take a photo'),
              onTap: () => Navigator.of(sheetContext).pop(ImageSource.camera),
            ),
          ],
        ),
      ),
    );

    if (source == null || !mounted) {
      return;
    }

    await _pickImageFromDevice(source);
  }

  Future<void> _pickImageFromDevice(ImageSource source) async {
    // Lock image picker UI while upload is in progress.
    setState(() => _isPickingImage = true);

    try {
      final imageFile = await _imagePicker.pickImage(
        source: source,
        imageQuality: 85,
        maxWidth: 1600,
      );

      if (imageFile == null) {
        return;
      }

      final uploadedUrl = await _uploadProductImage(imageFile);
      if (!mounted) {
        return;
      }

      setState(() {
        _selectedImageName = imageFile.name;
        _imageUrlController.text = uploadedUrl;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            source == ImageSource.camera
                ? 'Photo captured and uploaded successfully'
                : 'Image selected and uploaded successfully',
          ),
        ),
      );
    } on MissingPluginException {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Image picker is not ready yet. Please restart the app and try again.'),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('We could not upload the image. Please try again.')),
      );
    } finally {
      if (mounted) {
        setState(() => _isPickingImage = false);
      }
    }
  }

  Future<String> _uploadProductImage(XFile imageFile) async {
    final bytes = await imageFile.readAsBytes();
    final extension = _fileExtension(imageFile.name);
    final safeName = _safeFileName(imageFile.name);
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final storageRef = _storage
        .ref()
      .child('products')
      .child('images')
        .child('${timestamp}_$safeName');

    final snapshot = await storageRef.putData(
      bytes,
      SettableMetadata(contentType: _contentTypeForExtension(extension, bytes)),
    );

    if (snapshot.state != TaskState.success) {
      throw StateError('Image upload did not finish. Please try again.');
    }

    return _getDownloadUrlWithRetry(snapshot.ref);
  }

  Future<String> _getDownloadUrlWithRetry(Reference ref) async {
    FirebaseException? lastError;

    for (var attempt = 0; attempt < 8; attempt++) {
      try {
        await ref.getMetadata();
        return await ref.getDownloadURL();
      } on FirebaseException catch (error) {
        if (error.code != 'object-not-found' && error.code != 'unknown') {
          rethrow;
        }

        lastError = error;
        await Future<void>.delayed(Duration(milliseconds: 400 * (attempt + 1)));
      }
    }

    throw lastError ?? StateError('Image upload was completed, but the file could not be opened. Please try again.');
  }

  String _safeFileName(String name) {
    final sanitized = name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9._-]'), '-');
    if (sanitized.isEmpty) {
      return 'image';
    }
    return sanitized;
  }

  String _fileExtension(String name) {
    final index = name.lastIndexOf('.');
    if (index == -1 || index == name.length - 1) {
      return '';
    }
    return name.substring(index + 1).toLowerCase();
  }

  String _contentTypeForExtension(String extension, Uint8List bytes) {
    switch (extension) {
      case 'png':
        return 'image/png';
      case 'gif':
        return 'image/gif';
      case 'webp':
        return 'image/webp';
      case 'heic':
        return 'image/heic';
      case 'heif':
        return 'image/heif';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      default:
        if (bytes.length > 3 && bytes[0] == 0x89 && bytes[1] == 0x50 && bytes[2] == 0x4E) {
          return 'image/png';
        }
        return 'image/jpeg';
    }
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
    final generatedId = name.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '-');

    // Disable submit button while save request runs.
    setState(() => _isSaving = true);
    try {
      await widget.onSubmit(
        Product(
          id: 'prod-$generatedId',
          name: name,
          description: _descriptionController.text.trim(),
          imageUrl: _imageUrlController.text.trim().isEmpty
              ? 'https://images.unsplash.com/photo-1523275335684-37898b6baf30'
              : _imageUrlController.text.trim(),
          price: price,
          categoryId: _selectedCategoryId ?? widget.categories.first.id,
          branchIds: _selectedBranchIds.toList(),
          stockByBranch: {
            for (final branchId in _selectedBranchIds) branchId: 1,
          },
          isAvailable: true,
          availableSizes: _selectedSizes.toList(),
          availableColors: _selectedColors.toList(),
        ),
      );
    } catch (error) {
      if (!mounted) {
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('We could not save this product. Please try again.')),
      );
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
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