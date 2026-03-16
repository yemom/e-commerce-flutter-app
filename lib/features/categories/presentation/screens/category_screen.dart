/// Displays the category list and highlights the current selection.
library;
import 'package:flutter/material.dart';

import 'package:e_commerce_app_with_django/core/presentation/widgets/app_network_image.dart';
import 'package:e_commerce_app_with_django/features/categories/domain/models/category.dart';

class CategoryScreen extends StatelessWidget {
  const CategoryScreen({
    super.key,
    required this.categories,
    required this.selectedCategoryId,
    required this.onCategorySelected,
    this.onBackToHome,
  });

  final List<Category> categories;
  final String? selectedCategoryId;
  final ValueChanged<String> onCategorySelected;
  final VoidCallback? onBackToHome;

  @override
  Widget build(BuildContext context) {
    // First list item is header, remaining items are selectable categories.
    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      body: SafeArea(
        bottom: false,
        child: ListView.separated(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 120),
          itemCount: categories.length + 1,
          separatorBuilder: (_, __) => const SizedBox(height: 14),
          itemBuilder: (context, index) {
            if (index == 0) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: const Color(0xFFECEAF7),
                          borderRadius: BorderRadius.circular(23),
                        ),
                        child: const Icon(Icons.person_rounded, color: Color(0xFF23263B)),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Hi, shopper',
                              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: Color(0xFF23263B)),
                            ),
                            SizedBox(height: 2),
                            Text('Explore by category', style: TextStyle(color: Color(0xFF9197A8), fontSize: 13)),
                          ],
                        ),
                      ),
                      _CategoryHeaderIcon(icon: Icons.search_rounded),
                      const SizedBox(width: 10),
                      const _CategoryHeaderIcon(icon: Icons.notifications_none_rounded, badge: true),
                    ],
                  ),
                  const SizedBox(height: 22),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            borderRadius: BorderRadius.circular(10),
                            onTap: onBackToHome ?? () => Navigator.of(context).pop(),
                            child: const _CategoryTab(label: 'Home', selected: false),
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Expanded(child: _CategoryTab(label: 'Category', selected: true)),
                      ],
                    ),
                  ),
                ],
              );
            }

            final category = categories[index - 1];
            final isSelected = category.id == selectedCategoryId;
            return InkWell(
              key: Key('category.item.${category.id}'),
              borderRadius: BorderRadius.circular(22),
              onTap: () => onCategorySelected(category.id),
              child: Ink(
                height: 124,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x100F172A),
                      blurRadius: 18,
                      offset: Offset(0, 8),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(22),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      AppNetworkImage(imageUrl: category.imageUrl),
                      DecoratedBox(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.centerLeft,
                            end: Alignment.centerRight,
                            colors: [
                              Colors.white.withValues(alpha: 0.94),
                              Colors.white.withValues(alpha: 0.82),
                              Colors.white.withValues(alpha: 0.08),
                            ],
                            stops: const [0.0, 0.45, 1.0],
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(18),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    category.name,
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF181C2E),
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    category.description,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 13,
                                      color: Color(0xFF5F6475),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    isSelected ? 'Selected category' : 'Browse now',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: isSelected ? const Color(0xFF7061FF) : const Color(0xFF8F94A7),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (isSelected)
                              const Icon(Icons.check_circle_rounded, color: Color(0xFF7061FF), size: 28),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _CategoryHeaderIcon extends StatelessWidget {
  const _CategoryHeaderIcon({required this.icon, this.badge = false});

  final IconData icon;
  final bool badge;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
          ),
          child: Icon(icon, color: const Color(0xFF23263B)),
        ),
        if (badge)
          Positioned(
            top: 8,
            right: 9,
            child: Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(color: Color(0xFFFF4C6A), shape: BoxShape.circle),
            ),
          ),
      ],
    );
  }
}

class _CategoryTab extends StatelessWidget {
  const _CategoryTab({required this.label, required this.selected});

  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.only(bottom: 10, top: 8),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: selected ? const Color(0xFF7061FF) : Colors.transparent,
            width: 2,
          ),
        ),
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        style: TextStyle(
          color: selected ? const Color(0xFF23263B) : const Color(0xFFC0C3CF),
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}