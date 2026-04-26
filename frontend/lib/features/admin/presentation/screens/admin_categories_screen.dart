/// Dedicated admin page for category management.
library;

import 'package:flutter/material.dart';

import 'package:e_commerce_app_with_django/features/categories/domain/models/category.dart';

class AdminCategoriesScreen extends StatefulWidget {
  const AdminCategoriesScreen({
    super.key,
    required this.categories,
    this.onAddCategory,
    this.onToggleCategory,
    this.onFetchCategory,
    this.onUpdateCategory,
    this.onDeleteCategory,
  });

  final List<Category> categories;
  final Future<void> Function({required String name, required String description, required String imageUrl})? onAddCategory;
  final Future<void> Function(String categoryId, bool isActive)? onToggleCategory;
  final Future<Category?> Function(String categoryId)? onFetchCategory;
  final Future<void> Function({required String categoryId, required String name, required String description, required String imageUrl})? onUpdateCategory;
  final Future<void> Function(String categoryId)? onDeleteCategory;

  @override
  State<AdminCategoriesScreen> createState() => _AdminCategoriesScreenState();
}

class _AdminCategoriesScreenState extends State<AdminCategoriesScreen> {
  late List<Category> _categories;

  @override
  void initState() {
    super.initState();
    _categories = List<Category>.from(widget.categories);
  }

  Future<void> _showCategoryDialog({Category? category, required bool isNew}) async {
    final nameController = TextEditingController(text: category?.name ?? '');
    final descriptionController = TextEditingController(text: category?.description ?? '');
    final imageController = TextEditingController(
      text: category?.imageUrl.isNotEmpty == true ? category!.imageUrl : 'https://images.unsplash.com/photo-1472851294608-062f824d29cc',
    );

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(isNew ? 'Add Category' : 'Edit Category'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Name')),
              const SizedBox(height: 10),
              TextField(controller: descriptionController, decoration: const InputDecoration(labelText: 'Description')),
              const SizedBox(height: 10),
              TextField(controller: imageController, decoration: const InputDecoration(labelText: 'Image URL')),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final name = nameController.text.trim();
              if (name.isEmpty) {
                return;
              }

              if (isNew) {
                await widget.onAddCategory?.call(
                  name: name,
                  description: descriptionController.text.trim(),
                  imageUrl: imageController.text.trim(),
                );
              } else {
                await widget.onUpdateCategory?.call(
                  categoryId: category!.id,
                  name: name,
                  description: descriptionController.text.trim(),
                  imageUrl: imageController.text.trim(),
                );
              }

              if (!mounted) {
                return;
              }

              setState(() {
                if (isNew) {
                  _categories = [
                    Category(
                      id: _slugify(name),
                      name: name,
                      description: descriptionController.text.trim(),
                      imageUrl: imageController.text.trim(),
                      isActive: true,
                    ),
                    ..._categories,
                  ];
                } else {
                  final index = _categories.indexWhere((item) => item.id == category!.id);
                  if (index != -1) {
                    _categories[index] = _categories[index].copyWith(
                      name: name,
                      description: descriptionController.text.trim(),
                      imageUrl: imageController.text.trim(),
                    );
                  }
                }
              });
              Navigator.of(dialogContext).pop();
            },
            child: Text(isNew ? 'Save' : 'Update'),
          ),
        ],
      ),
    );
  }

  Future<void> _showDeleteDialog(Category category) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Category'),
        content: Text('Delete ${category.name}?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFDC2626), foregroundColor: Colors.white),
            onPressed: () async {
              await widget.onDeleteCategory?.call(category.id);
              if (!mounted) {
                return;
              }
              setState(() {
                _categories.removeWhere((item) => item.id == category.id);
              });
              Navigator.of(dialogContext).pop();
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Category Management'),
        actions: [
          IconButton(
            tooltip: 'Add Category',
            onPressed: widget.onAddCategory == null ? null : () => _showCategoryDialog(isNew: true),
            icon: const Icon(Icons.category_outlined),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(color: const Color(0xFFBFDBFE)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.category_outlined, color: Color(0xFF1D4ED8)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _categories.isEmpty
                          ? 'No categories found.'
                          : '${_categories.where((item) => item.isActive).length} of ${_categories.length} category(ies) active.',
                      style: const TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF1E3A8A)),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Expanded(
            child: _categories.isEmpty
                ? const Center(child: Text('No categories found.'))
                : ListView.separated(
                    padding: const EdgeInsets.all(16),
                    itemCount: _categories.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 12),
                    itemBuilder: (context, index) {
                      final category = _categories[index];
                      return Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFE7ECF3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(category.name, style: Theme.of(context).textTheme.titleMedium),
                            const SizedBox(height: 6),
                            Text(category.description),
                            Text('Status: ${category.isActive ? 'active' : 'inactive'}'),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    category.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF5E56E7),
                                    ),
                                  ),
                                ),
                                Chip(
                                  backgroundColor: const Color(0xFFF3F4F6),
                                  label: Text(
                                    category.isActive ? 'active' : 'inactive',
                                    style: const TextStyle(color: Color(0xFF374151)),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                if (widget.onToggleCategory != null)
                                  OutlinedButton(
                                    onPressed: () async {
                                      final value = !category.isActive;
                                      await widget.onToggleCategory?.call(category.id, value);
                                      if (!mounted) {
                                        return;
                                      }
                                      setState(() {
                                        _categories[index] = _categories[index].copyWith(isActive: value);
                                      });
                                    },
                                    child: Text(category.isActive ? 'Disable' : 'Enable'),
                                  ),
                                if (widget.onUpdateCategory != null)
                                  OutlinedButton(
                                    onPressed: () async {
                                      final latest = await widget.onFetchCategory?.call(category.id);
                                      if (!mounted) {
                                        return;
                                      }
                                      await _showCategoryDialog(category: latest ?? category, isNew: false);
                                    },
                                    child: const Text('Edit'),
                                  ),
                                if (widget.onDeleteCategory != null)
                                  OutlinedButton(
                                    style: OutlinedButton.styleFrom(foregroundColor: const Color(0xFFDC2626)),
                                    onPressed: () => _showDeleteDialog(category),
                                    child: const Text('Delete'),
                                  ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  String _slugify(String value) {
    return value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9]+'), '-')
        .replaceAll(RegExp(r'^-|-$'), '');
  }
}
