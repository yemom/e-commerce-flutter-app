/// Displays the product catalog with search, branch, and category filters.
library;
import 'dart:async';

import 'package:flutter/material.dart';

import 'package:e_commerce_app_with_django/core/presentation/widgets/app_formatters.dart';
import 'package:e_commerce_app_with_django/core/presentation/widgets/app_network_image.dart';
import 'package:e_commerce_app_with_django/features/branches/domain/models/branch.dart';
import 'package:e_commerce_app_with_django/features/categories/domain/models/category.dart';
import 'package:e_commerce_app_with_django/features/products/domain/models/product.dart';

/// Screen for Product List.
class ProductListScreen extends StatefulWidget {
  const ProductListScreen({
    super.key,
    required this.products,
    required this.branches,
    required this.categories,
    required this.selectedBranchId,
    required this.selectedCategoryId,
    required this.searchQuery,
    required this.onSearchChanged,
    required this.onBranchChanged,
    required this.onCategoryChanged,
    required this.onSeeAll,
    required this.onLogout,
    this.userName = 'Shopper',
    this.onOpenProfile,
    this.onOpenCategoryScreen,
    this.onProductSelected,
  });

  final List<Product> products;
  final List<Branch> branches;
  final List<Category> categories;
  final String? selectedBranchId;
  final String? selectedCategoryId;
  final String searchQuery;
  final ValueChanged<String> onSearchChanged;
  final ValueChanged<String?> onBranchChanged;
  final ValueChanged<String?> onCategoryChanged;
  final VoidCallback onSeeAll;
  final Future<void> Function() onLogout;
  final String userName;
  final VoidCallback? onOpenProfile;
  final VoidCallback? onOpenCategoryScreen;
  final ValueChanged<Product>? onProductSelected;

  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  final PageController _bannerController = PageController();
  final TextEditingController _searchController = TextEditingController();
  final FocusNode _searchFocusNode = FocusNode();

  Timer? _bannerTimer;
  int _activeBannerIndex = 0;
  bool _showSearchField = false;

  @override
  void initState() {
    super.initState();
    _searchController.text = widget.searchQuery;
    _startBannerTimer();
  }

  @override
  void didUpdateWidget(covariant ProductListScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.searchQuery != _searchController.text) {
      _searchController.value = TextEditingValue(
        text: widget.searchQuery,
        selection: TextSelection.collapsed(offset: widget.searchQuery.length),
      );
    }
  }

  @override
  void dispose() {
    _bannerTimer?.cancel();
    _bannerController.dispose();
    _searchController.dispose();
    _searchFocusNode.dispose();
    super.dispose();
  }

  void _startBannerTimer() {
    // Auto-rotate promo banners so the hero section feels alive.
    _bannerTimer?.cancel();
    _bannerTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted) {
        return;
      }
      final bannerCount = _bannerItems.length;
      if (bannerCount <= 1 || !_bannerController.hasClients) {
        return;
      }
      final next = (_activeBannerIndex + 1) % bannerCount;
      _bannerController.animateToPage(
        next,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOut,
      );
    });
  }

  void _toggleSearchField() {
    setState(() => _showSearchField = !_showSearchField);
    if (_showSearchField) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _searchFocusNode.requestFocus();
        }
      });
    } else {
      _searchFocusNode.unfocus();
      _searchController.clear();
      widget.onSearchChanged('');
    }
  }

  static const List<_BannerItem> _bannerItems = [
    _BannerItem(
      title: '24% off shipping today\non bag purchases',
      subtitle: 'By Kutuku Store',
    ),
    _BannerItem(
      title: 'Buy 2 bags and get\nfree express delivery',
      subtitle: 'Weekly promo',
    ),
    _BannerItem(
      title: 'Weekend fashion deal\nwith fresh arrivals',
      subtitle: 'Trending now',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    // Responsive grid and spacing to keep cards readable on all screen widths.
    final currentBranch = widget.branches.where((branch) => branch.id == widget.selectedBranchId).firstOrNull;
    final screenWidth = MediaQuery.sizeOf(context).width;
    final horizontalPadding = screenWidth < 380 ? 16.0 : 20.0;
    final crossAxisCount = screenWidth >= 920 ? 4 : screenWidth >= 640 ? 3 : 2;
    final mainAxisExtent = screenWidth >= 640 ? 292.0 : 274.0;
    final greetingName = widget.userName.split(' ').first;

    return Scaffold(
      backgroundColor: const Color(0xFFF6F7FB),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(horizontalPadding, 16, horizontalPadding, 120),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: widget.onOpenProfile,
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: const Color(0xFFECEAF7),
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: const Icon(Icons.person_rounded, color: Color(0xFF23263B)),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hi, $greetingName',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF23263B),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          currentBranch?.name ?? 'Let\'s go shopping',
                          style: const TextStyle(color: Color(0xFF9197A8), fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                  _HeaderIconButton(
                    key: const Key('product-list.search-toggle'),
                    icon: _showSearchField ? Icons.close_rounded : Icons.search_rounded,
                    onTap: _toggleSearchField,
                  ),
                  const SizedBox(width: 10),
                  _HeaderIconButton(
                    icon: Icons.logout_rounded,
                    onTap: widget.onLogout,
                    badge: true,
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const Expanded(child: _TopTabChip(label: 'Home', selected: true)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: widget.onOpenCategoryScreen,
                        child: const _TopTabChip(label: 'Category', selected: false),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 148,
                child: PageView.builder(
                  controller: _bannerController,
                  onPageChanged: (index) => setState(() => _activeBannerIndex = index),
                  itemCount: _bannerItems.length,
                  itemBuilder: (context, index) {
                    final item = _bannerItems[index];
                    final promoImage = widget.products.isEmpty
                        ? ''
                        : widget.products[index % widget.products.length].imageUrl;
                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 2),
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F0F3),
                        borderRadius: BorderRadius.circular(22),
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  item.title,
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    height: 1.1,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF23263B),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  item.subtitle,
                                  style: const TextStyle(color: Color(0xFF9197A8), fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            width: 110,
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(18),
                              child: AppNetworkImage(imageUrl: promoImage),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              Center(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List.generate(
                    _bannerItems.length,
                    (index) => Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3),
                      child: _PagerDot(active: index == _activeBannerIndex),
                    ),
                  ),
                ),
              ),
              if (_showSearchField)
                Padding(
                  padding: const EdgeInsets.only(top: 14),
                  child: TextField(
                    key: const Key('product-list.search-field'),
                    focusNode: _searchFocusNode,
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search products',
                      prefixIcon: const Icon(Icons.search_rounded),
                      fillColor: Colors.white,
                      filled: true,
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(20),
                        borderSide: const BorderSide(color: Color(0xFF7061FF)),
                      ),
                    ),
                    onChanged: widget.onSearchChanged,
                  ),
                ),
              const SizedBox(height: 14),
              DropdownButtonFormField<String?>(
                key: const Key('product-list.branch-filter'),
                initialValue: widget.selectedBranchId,
                items: [
                  const DropdownMenuItem<String?>(
                    value: null,
                    child: Text('All branches'),
                  ),
                  ...widget.branches.map(
                    (branch) => DropdownMenuItem<String?>(
                      value: branch.id,
                      child: Text(branch.name),
                    ),
                  ),
                ],
                onChanged: widget.onBranchChanged,
                decoration: const InputDecoration(
                  labelText: 'Active branch',
                  prefixIcon: Icon(Icons.storefront_outlined),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 42,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return ChoiceChip(
                        key: const Key('product-list.category.__all__'),
                        label: const Text('All'),
                        selectedColor: const Color(0xFF7061FF),
                        labelStyle: TextStyle(
                          color: widget.selectedCategoryId == null ? Colors.white : const Color(0xFF23263B),
                          fontWeight: FontWeight.w700,
                        ),
                        backgroundColor: Colors.white,
                        selected: widget.selectedCategoryId == null,
                        onSelected: (_) => widget.onCategoryChanged(null),
                      );
                    }

                    final category = widget.categories[index - 1];
                    return ChoiceChip(
                      key: Key('product-list.category.${category.id}'),
                      label: Text(category.name),
                      selectedColor: const Color(0xFF7061FF),
                      labelStyle: TextStyle(
                        color: category.id == widget.selectedCategoryId ? Colors.white : const Color(0xFF23263B),
                        fontWeight: FontWeight.w700,
                      ),
                      backgroundColor: Colors.white,
                      selected: category.id == widget.selectedCategoryId,
                      onSelected: (_) => widget.onCategoryChanged(category.id),
                    );
                  },
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemCount: widget.categories.length + 1,
                ),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Text('New Arrivals', style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(width: 6),
                  const Text('🔥', style: TextStyle(fontSize: 18)),
                  const Spacer(),
                  TextButton(onPressed: widget.onSeeAll, child: const Text('See All')),
                ],
              ),
              const SizedBox(height: 10),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: widget.products.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  mainAxisExtent: mainAxisExtent,
                ),
                itemBuilder: (context, index) {
                  final product = widget.products[index];
                  return InkWell(
                    borderRadius: BorderRadius.circular(28),
                    onTap: () => widget.onProductSelected?.call(product),
                    child: Ink(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(28),
                        boxShadow: const [
                          BoxShadow(
                            color: Color(0x120F172A),
                            blurRadius: 18,
                            offset: Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Stack(
                                children: [
                                  Hero(
                                    tag: 'product-image-${product.id}',
                                    child: SizedBox(
                                      height: double.infinity,
                                      width: double.infinity,
                                      child: AppNetworkImage(
                                        imageUrl: product.imageUrl,
                                        borderRadius: BorderRadius.circular(22),
                                      ),
                                    ),
                                  ),
                                  Positioned(
                                    top: 10,
                                    right: 10,
                                    child: Container(
                                      width: 34,
                                      height: 34,
                                      decoration: BoxDecoration(
                                        color: Colors.white.withValues(alpha: 0.92),
                                        borderRadius: BorderRadius.circular(17),
                                      ),
                                      child: const Icon(
                                        Icons.favorite_border_rounded,
                                        size: 17,
                                        color: Color(0xFF8D92A3),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 14),
                            Text(
                              product.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 4),
                            Text(
                              product.description,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 13, color: Color(0xFF9197A8)),
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    formatPrice(product.price),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      color: Color(0xFF0F172A),
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeaderIconButton extends StatelessWidget {
  const _HeaderIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.badge = false,
  });

  final IconData icon;
  final VoidCallback? onTap;
  final bool badge;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(18),
          child: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(icon, color: const Color(0xFF23263B)),
          ),
        ),
        if (badge)
          Positioned(
            top: 8,
            right: 9,
            child: Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Color(0xFFFF4C6A),
                shape: BoxShape.circle,
              ),
            ),
          ),
      ],
    );
  }
}

class _TopTabChip extends StatelessWidget {
  const _TopTabChip({required this.label, required this.selected});

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

class _PagerDot extends StatelessWidget {
  const _PagerDot({this.active = false});

  final bool active;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: active ? 8 : 6,
      height: active ? 8 : 6,
      decoration: BoxDecoration(
        color: active ? const Color(0xFF7061FF) : const Color(0xFFD2D5DF),
        shape: BoxShape.circle,
      ),
    );
  }
}

class _BannerItem {
  const _BannerItem({required this.title, required this.subtitle});

  final String title;
  final String subtitle;
}
