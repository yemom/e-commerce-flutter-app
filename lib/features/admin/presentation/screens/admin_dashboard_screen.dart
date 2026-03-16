
/// Shows branch stats, order actions, and admin tools in one dashboard.
library;
import 'dart:async';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import 'package:e_commerce_app_with_django/core/presentation/widgets/app_formatters.dart';
import 'package:e_commerce_app_with_django/core/presentation/widgets/app_network_image.dart';
import 'package:e_commerce_app_with_django/features/admin/presentation/providers/admin_settings_provider.dart';
import 'package:e_commerce_app_with_django/features/auth/domain/models/user_role.dart';
import 'package:e_commerce_app_with_django/features/branches/domain/models/branch.dart';
import 'package:e_commerce_app_with_django/features/categories/domain/models/category.dart';
import 'package:e_commerce_app_with_django/features/orders/domain/models/order.dart';
import 'package:e_commerce_app_with_django/features/payment/domain/models/payment.dart';
import 'package:e_commerce_app_with_django/features/products/domain/models/product.dart';
import 'package:e_commerce_app_with_django/firebase_options.dart';

class _AdminStatCard extends StatelessWidget {
  const _AdminStatCard({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.16),
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: Color(0xFFDCDDFF))),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(child: Text(title, style: Theme.of(context).textTheme.titleLarge)),
        if (trailing != null) Flexible(child: Align(alignment: Alignment.centerRight, child: trailing!)),
      ],
    );
  }
}

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({
    super.key,
    required this.branches,
    required this.orders,
    required this.onAddProduct,
    required this.onVerifyPayment,
    required this.onMarkOrderShipped,
    required this.onMarkOrderDelivered,
    required this.onLogout,
    this.dashboardTitle = 'Admin dashboard',
    this.roleSections = const ['Products', 'Orders', 'Payments', 'Categories'],
    this.showBranchesSection = true,
    this.products = const [],
    this.adminCategories = const [],
    this.adminPaymentOptions = const [],
    this.adminAccounts = const [],
    this.onAddCategory,
    this.onToggleCategory,
    this.onFetchCategory,
    this.onUpdateCategory,
    this.onDeleteCategory,
    this.onAddPaymentOption,
    this.onFetchPaymentOption,
    this.onUpdatePaymentOption,
    this.onDeletePaymentOption,
    this.onTogglePaymentOption,
    this.onUpdateProductPrice,
    this.onDeleteProduct,
    this.onCreateAdminAccount,
    this.onFetchAdminAccount,
    this.onUpdateAdminAccount,
    this.onApproveAdmin,
    this.onRemoveAdmin,
    this.onFetchBranch,
    this.onUpdateBranch,
  });

  final List<Branch> branches;
  final List<Order> orders;
  final VoidCallback onAddProduct;
  final ValueChanged<String> onVerifyPayment;
  final ValueChanged<String> onMarkOrderShipped;
  final ValueChanged<String> onMarkOrderDelivered;
  final Future<void> Function() onLogout;
  final String dashboardTitle;
  final List<String> roleSections;
  final bool showBranchesSection;
  final List<Product> products;
  final List<Category> adminCategories;
  final List<PaymentOption> adminPaymentOptions;
  final List<AdminAccount> adminAccounts;
  final Future<void> Function({
    required String name,
    required String description,
    required String imageUrl,
  })? onAddCategory;
  final Future<void> Function(String categoryId, bool isActive)? onToggleCategory;
  final Future<Category?> Function(String categoryId)? onFetchCategory;
  final Future<void> Function({
    required String categoryId,
    required String name,
    required String description,
    required String imageUrl,
  })? onUpdateCategory;
  final Future<void> Function(String categoryId)? onDeleteCategory;
  final Future<void> Function({required String label, String? iconUrl})? onAddPaymentOption;
  final Future<PaymentOption?> Function(String optionId)? onFetchPaymentOption;
  final Future<void> Function({required String optionId, required String label, String? iconUrl})? onUpdatePaymentOption;
  final Future<void> Function(String optionId)? onDeletePaymentOption;
  final Future<void> Function(String optionId, bool isEnabled)? onTogglePaymentOption;
  final Future<void> Function(Product product, double newPrice)? onUpdateProductPrice;
  final Future<void> Function(String productId)? onDeleteProduct;
  final Future<void> Function({required String name, required String email, required String password})? onCreateAdminAccount;
  final Future<AdminAccount?> Function(String userId)? onFetchAdminAccount;
  final Future<void> Function({required String userId, required String name, required String email})? onUpdateAdminAccount;
  final Future<void> Function({required String userId, required bool approved})? onApproveAdmin;
  final Future<void> Function(String userId)? onRemoveAdmin;
  final Future<Branch?> Function(String branchId)? onFetchBranch;
  final Future<void> Function({
    required String branchId,
    required String name,
    required String location,
    required String phoneNumber,
    required bool isActive,
  })? onUpdateBranch;

  FirebaseStorage get _storage =>
      FirebaseStorage.instanceFor(bucket: DefaultFirebaseOptions.currentPlatform.storageBucket);

  @override
  Widget build(BuildContext context) {
    final isVerySmallPhone = MediaQuery.sizeOf(context).width < 360;
    final branchCardWidth = isVerySmallPhone ? 188.0 : 220.0;
    final compactActionStyle = OutlinedButton.styleFrom(
      minimumSize: Size.zero,
      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      padding: EdgeInsets.symmetric(
        horizontal: isVerySmallPhone ? 8 : 12,
        vertical: isVerySmallPhone ? 6 : 8,
      ),
      visualDensity: isVerySmallPhone ? VisualDensity.compact : VisualDensity.standard,
    );

    return Scaffold(
      appBar: AppBar(
        title: Text(dashboardTitle),
        actions: [
          IconButton(
            key: const Key('admin.add-product-button'),
            tooltip: 'Add product',
            onPressed: onAddProduct,
            icon: const Icon(Icons.add_box_outlined),
          ),
          IconButton(
            tooltip: 'Log out',
            onPressed: () {
              onLogout();
            },
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFF0EEFF), Color(0xFFF7F8FC), Color(0xFFF7F8FC)],
            stops: [0, .18, .18],
          ),
        ),
        child: ListView(
          key: const Key('admin.dashboard-scroll'),
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
          children: [
            Container(
              padding: EdgeInsets.all(isVerySmallPhone ? 16 : 20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF5E56E7), Color(0xFF756DF2)]),
                borderRadius: BorderRadius.circular(isVerySmallPhone ? 24 : 30),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Operations overview', style: TextStyle(color: Color(0xFFDCDDFF), fontSize: 13)),
                  const SizedBox(height: 6),
                  Text(
                    'Manage branches, orders and shipping',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: isVerySmallPhone ? 18 : 24,
                      fontWeight: FontWeight.w800,
                      height: 1.1,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(child: _AdminStatCard(label: 'Branches', value: '${branches.length}')),
                      const SizedBox(width: 10),
                      Expanded(child: _AdminStatCard(label: 'Orders', value: '${orders.length}')),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: roleSections
                        .map(
                          (section) => Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.16),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              section,
                              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
                            ),
                          ),
                        )
                        .toList(),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 22),
            if (showBranchesSection) ...[
              _SectionHeader(title: 'Branches'),
              const SizedBox(height: 12),
              SizedBox(
                height: isVerySmallPhone ? 208 : 240,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: branches.length,
                  separatorBuilder: (_, __) => SizedBox(width: isVerySmallPhone ? 8 : 12),
                  itemBuilder: (context, index) {
                    final branch = branches[index];
                    return SizedBox(
                      width: branchCardWidth,
                      child: Container(
                        key: Key('admin.branch-card.${branch.id}'),
                        padding: EdgeInsets.all(isVerySmallPhone ? 12 : 18),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(isVerySmallPhone ? 20 : 28),
                          border: Border.all(color: const Color(0xFFE7ECF3)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: isVerySmallPhone ? 40 : 48,
                              height: isVerySmallPhone ? 40 : 48,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF0EEFF),
                                borderRadius: BorderRadius.circular(isVerySmallPhone ? 12 : 16),
                              ),
                              child: Icon(
                                Icons.storefront_outlined,
                                color: const Color(0xFF5E56E7),
                                size: isVerySmallPhone ? 20 : 24,
                              ),
                            ),
                            SizedBox(height: isVerySmallPhone ? 10 : 14),
                            Text(
                              branch.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontSize: isVerySmallPhone ? 18 : null,
                                  ),
                            ),
                            SizedBox(height: isVerySmallPhone ? 4 : 6),
                            Text(
                              branch.location,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: isVerySmallPhone ? 13 : null),
                            ),
                            SizedBox(height: isVerySmallPhone ? 6 : 8),
                            Text(
                              branch.phoneNumber,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(fontSize: isVerySmallPhone ? 13 : null),
                            ),
                            const Spacer(),
                            if (onUpdateBranch != null)
                              Align(
                                alignment: Alignment.centerRight,
                                child: OutlinedButton.icon(
                                  style: compactActionStyle,
                                  onPressed: () async {
                                    final latestBranch = await onFetchBranch?.call(branch.id);
                                    if (!context.mounted) {
                                      return;
                                    }
                                    await _showEditBranchDialog(context, latestBranch ?? branch);
                                  },
                                  icon: Icon(Icons.edit_outlined, size: isVerySmallPhone ? 14 : 16),
                                  label: Text(
                                    'Edit',
                                    style: TextStyle(fontSize: isVerySmallPhone ? 12 : null),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 22),
            ],
            _SectionHeader(
              title: 'Inventory',
              trailing: Text('${products.length} items', style: const TextStyle(color: Color(0xFF7C8799))),
            ),
            const SizedBox(height: 12),
            SizedBox(
              height: 250,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: products.take(6).length,
                separatorBuilder: (_, __) => SizedBox(width: isVerySmallPhone ? 8 : 12),
                itemBuilder: (context, index) {
                  final product = products[index];
                  return SizedBox(
                    width: isVerySmallPhone ? 168 : 184,
                    child: Container(
                      padding: EdgeInsets.all(isVerySmallPhone ? 10 : 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(isVerySmallPhone ? 20 : 28),
                        border: Border.all(color: const Color(0xFFE7ECF3)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(
                            height: isVerySmallPhone ? 104 : 120,
                            width: double.infinity,
                            child: AppNetworkImage(
                              imageUrl: product.imageUrl,
                              borderRadius: BorderRadius.circular(isVerySmallPhone ? 18 : 22),
                              placeholderIcon: Icons.inventory_2_outlined,
                            ),
                          ),
                          SizedBox(height: isVerySmallPhone ? 10 : 12),
                          Text(
                            product.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                  fontSize: isVerySmallPhone ? 14 : null,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  formatPrice(product.price),
                                  style: const TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF5E56E7)),
                                ),
                              ),
                              if (onUpdateProductPrice != null)
                                IconButton(
                                  visualDensity: VisualDensity.compact,
                                  icon: const Icon(Icons.edit_outlined, size: 18),
                                  onPressed: () => _showUpdatePriceDialog(context, product),
                                ),
                              if (onDeleteProduct != null)
                                IconButton(
                                  visualDensity: VisualDensity.compact,
                                  icon: const Icon(Icons.delete_outline, size: 18),
                                  onPressed: () => onDeleteProduct!(product.id),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 22),
            if (onAddCategory != null || onToggleCategory != null || onUpdateCategory != null || onDeleteCategory != null) ...[
              _SectionHeader(
                title: 'Category Settings',
                trailing: TextButton.icon(
                  onPressed: onAddCategory == null ? null : () => _showAddCategoryDialog(context),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Add Category'),
                ),
              ),
              const SizedBox(height: 8),
              ...adminCategories.map(
                (category) => Container(
                  margin: EdgeInsets.only(bottom: isVerySmallPhone ? 6 : 10),
                  padding: EdgeInsets.fromLTRB(
                    isVerySmallPhone ? 8 : 14,
                    isVerySmallPhone ? 6 : 10,
                    isVerySmallPhone ? 6 : 10,
                    isVerySmallPhone ? 6 : 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(isVerySmallPhone ? 12 : 18),
                    border: Border.all(color: const Color(0xFFE7ECF3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  category.name,
                                  style: Theme.of(context).textTheme.titleSmall?.copyWith(fontSize: isVerySmallPhone ? 14 : null),
                                ),
                                SizedBox(height: isVerySmallPhone ? 1 : 2),
                                Text(
                                  category.description,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(fontSize: isVerySmallPhone ? 11 : 13, color: Colors.grey[700]),
                                ),
                              ],
                            ),
                          ),
                          Switch(
                            value: category.isActive,
                            onChanged: onToggleCategory == null ? null : (value) => onToggleCategory!(category.id, value),
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ],
                      ),
                      SizedBox(height: isVerySmallPhone ? 2 : 4),
                      Wrap(
                        spacing: isVerySmallPhone ? 2 : 4,
                        runSpacing: isVerySmallPhone ? 2 : 4,
                        children: [
                          IconButton(
                            tooltip: 'Edit category',
                            visualDensity: isVerySmallPhone ? VisualDensity.compact : VisualDensity.standard,
                            iconSize: isVerySmallPhone ? 18 : 22,
                            onPressed: onUpdateCategory == null
                                ? null
                                : () async {
                                    final latestCategory = await onFetchCategory?.call(category.id);
                                    if (!context.mounted) {
                                      return;
                                    }
                                    await _showEditCategoryDialog(context, latestCategory ?? category);
                                  },
                            icon: const Icon(Icons.edit_outlined),
                          ),
                          IconButton(
                            tooltip: 'Delete category',
                            visualDensity: isVerySmallPhone ? VisualDensity.compact : VisualDensity.standard,
                            iconSize: isVerySmallPhone ? 18 : 22,
                            onPressed: onDeleteCategory == null ? null : () => _showDeleteCategoryDialog(context, category),
                            icon: const Icon(Icons.delete_outline),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
            ],
            if (onTogglePaymentOption != null || onAddPaymentOption != null || onUpdatePaymentOption != null || onDeletePaymentOption != null) ...[
              _SectionHeader(
                title: 'Payment Settings',
                trailing: TextButton.icon(
                  onPressed: onAddPaymentOption == null ? null : () => _showAddPaymentMethodDialog(context),
                  icon: const Icon(Icons.add_rounded),
                  label: const Text('Add Payment'),
                ),
              ),
              const SizedBox(height: 8),
              ...adminPaymentOptions.map(
                (option) => Container(
                  margin: EdgeInsets.only(bottom: isVerySmallPhone ? 6 : 10),
                  padding: EdgeInsets.fromLTRB(
                    isVerySmallPhone ? 8 : 14,
                    isVerySmallPhone ? 6 : 10,
                    isVerySmallPhone ? 6 : 10,
                    isVerySmallPhone ? 6 : 10,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(isVerySmallPhone ? 12 : 18),
                    border: Border.all(color: const Color(0xFFE7ECF3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  option.label,
                                  style: Theme.of(context).textTheme.titleSmall?.copyWith(fontSize: isVerySmallPhone ? 14 : null),
                                ),
                                SizedBox(height: isVerySmallPhone ? 1 : 2),
                                Text(
                                  option.method.id,
                                  style: TextStyle(fontSize: isVerySmallPhone ? 11 : 13, color: Colors.grey[700]),
                                ),
                              ],
                            ),
                          ),
                          if (onTogglePaymentOption != null)
                            Switch(
                              value: option.isEnabled,
                              onChanged: (value) => onTogglePaymentOption!(option.id, value),
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                        ],
                      ),
                      if (onUpdatePaymentOption != null || onDeletePaymentOption != null) ...[
                        SizedBox(height: isVerySmallPhone ? 2 : 4),
                        Wrap(
                          spacing: isVerySmallPhone ? 2 : 4,
                          runSpacing: isVerySmallPhone ? 2 : 4,
                          children: [
                            if (onUpdatePaymentOption != null)
                              IconButton(
                                tooltip: 'Edit payment method',
                                visualDensity: isVerySmallPhone ? VisualDensity.compact : VisualDensity.standard,
                                iconSize: isVerySmallPhone ? 18 : 22,
                                onPressed: () async {
                                  final latestOption = await onFetchPaymentOption?.call(option.id);
                                  if (!context.mounted) {
                                    return;
                                  }
                                  await _showEditPaymentMethodDialog(context, latestOption ?? option);
                                },
                                icon: const Icon(Icons.edit_outlined),
                              ),
                            if (onDeletePaymentOption != null)
                              IconButton(
                                tooltip: 'Delete payment method',
                                visualDensity: isVerySmallPhone ? VisualDensity.compact : VisualDensity.standard,
                                iconSize: isVerySmallPhone ? 18 : 22,
                                onPressed: () => _showDeletePaymentMethodDialog(context, option),
                                icon: const Icon(Icons.delete_outline),
                              ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
            ],
            if (onCreateAdminAccount != null || onUpdateAdminAccount != null || onApproveAdmin != null || onRemoveAdmin != null) ...[
              _SectionHeader(
                title: 'Admins',
                trailing: TextButton.icon(
                  onPressed: onCreateAdminAccount == null ? null : () => _showCreateAdminDialog(context),
                  icon: const Icon(Icons.person_add_alt_1_outlined),
                  label: const Text('Create Admin'),
                ),
              ),
              const SizedBox(height: 8),
              if (adminAccounts.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 10),
                  child: Text('No admin accounts found.'),
                ),
              ...adminAccounts.map(
                (admin) => Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: EdgeInsets.all(isVerySmallPhone ? 10 : 14),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(color: const Color(0xFFE7ECF3)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(admin.name, style: Theme.of(context).textTheme.titleSmall),
                      SizedBox(height: isVerySmallPhone ? 1 : 2),
                      Text(
                        admin.email,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: isVerySmallPhone ? 6 : 8),
                      Wrap(
                        spacing: isVerySmallPhone ? 6 : 8,
                        runSpacing: isVerySmallPhone ? 6 : 8,
                        children: [
                          Chip(
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            visualDensity: isVerySmallPhone ? VisualDensity.compact : VisualDensity.standard,
                            labelPadding: EdgeInsets.symmetric(horizontal: isVerySmallPhone ? 6 : 8),
                            label: Text(admin.role.value),
                          ),
                          Chip(
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            visualDensity: isVerySmallPhone ? VisualDensity.compact : VisualDensity.standard,
                            labelPadding: EdgeInsets.symmetric(horizontal: isVerySmallPhone ? 6 : 8),
                            label: Text(admin.approved ? 'approved' : 'pending'),
                          ),
                          if (onApproveAdmin != null && admin.role == AppUserRole.admin)
                            OutlinedButton(
                              style: compactActionStyle,
                              onPressed: () => _showApproveAdminDialog(context, admin),
                              child: Text(admin.approved ? 'Set pending' : 'Approve'),
                            ),
                          if (onUpdateAdminAccount != null &&
                              (admin.role == AppUserRole.admin || admin.role == AppUserRole.superAdmin))
                            OutlinedButton(
                              style: compactActionStyle,
                              onPressed: () async {
                                final latestAdmin = await onFetchAdminAccount?.call(admin.userId);
                                if (!context.mounted) {
                                  return;
                                }
                                await _showEditAdminDialog(context, latestAdmin ?? admin);
                              },
                              child: const Text('Edit'),
                            ),
                          if (onRemoveAdmin != null && admin.role == AppUserRole.admin)
                            OutlinedButton(
                              style: compactActionStyle,
                              onPressed: () => _showDeleteAdminDialog(context, admin),
                              child: const Text('Delete admin'),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
            ],
            _SectionHeader(title: 'Orders'),
            const SizedBox(height: 12),
            ...orders.map(
              (order) => Container(
                margin: EdgeInsets.only(bottom: isVerySmallPhone ? 10 : 14),
                padding: EdgeInsets.all(isVerySmallPhone ? 14 : 18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(isVerySmallPhone ? 20 : 28),
                  border: Border.all(color: const Color(0xFFE7ECF3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                order.id,
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                      fontSize: isVerySmallPhone ? 18 : null,
                                    ),
                              ),
                              const SizedBox(height: 4),
                              Text('Status: ${order.status.name}'),
                            ],
                          ),
                        ),
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: isVerySmallPhone ? 10 : 12,
                            vertical: isVerySmallPhone ? 6 : 8,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF0EEFF),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text(
                            formatPrice(order.total),
                            style: TextStyle(fontSize: isVerySmallPhone ? 12 : null),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: isVerySmallPhone ? 8 : 10),
                    Text('Payment: ${order.payment.status.name}'),
                    SizedBox(height: isVerySmallPhone ? 10 : 14),
                    Wrap(
                      spacing: isVerySmallPhone ? 8 : 10,
                      runSpacing: isVerySmallPhone ? 8 : 10,
                      children: [
                        OutlinedButton(
                          key: Key('admin.verify-payment.${order.id}'),
                          style: compactActionStyle,
                          onPressed: () => onVerifyPayment(order.id),
                          child: const Text('Verify payment'),
                        ),
                        OutlinedButton(
                          key: Key('admin.ship-order.${order.id}'),
                          style: compactActionStyle,
                          onPressed: () => onMarkOrderShipped(order.id),
                          child: const Text('Mark shipped'),
                        ),
                        OutlinedButton(
                          key: Key('admin.deliver-order.${order.id}'),
                          style: compactActionStyle,
                          onPressed: () => onMarkOrderDelivered(order.id),
                          child: const Text('Mark delivered'),
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

  Future<void> _showAddCategoryDialog(BuildContext context) async {
    final nameController = TextEditingController();
    final descriptionController = TextEditingController();
    final imageController = TextEditingController(text: 'https://images.unsplash.com/photo-1472851294608-062f824d29cc');
    final imagePicker = ImagePicker();
    bool isPickingImage = false;
    String? selectedImageName;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (statefulContext, setDialogState) => AlertDialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          title: const Text('Add Category'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Name')),
                const SizedBox(height: 10),
                TextField(controller: descriptionController, decoration: const InputDecoration(labelText: 'Description')),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerLeft,
                  child: OutlinedButton.icon(
                    key: const Key('admin.category.pick-image-button'),
                    onPressed: isPickingImage
                        ? null
                        : () async {
                            final source = await _showImageSourcePicker(statefulContext);
                            if (source == null) {
                              return;
                            }

                            setDialogState(() => isPickingImage = true);
                            try {
                              final imageFile = await imagePicker.pickImage(
                                source: source,
                                imageQuality: 85,
                                maxWidth: 1600,
                              );

                              if (imageFile == null) {
                                return;
                              }

                              final uploadedUrl = await _uploadCategoryImage(imageFile);
                              imageController.text = uploadedUrl;
                              setDialogState(() {
                                selectedImageName = imageFile.name;
                              });
                            } on MissingPluginException {
                              _showAdminMessage(
                                statefulContext,
                                'Image picker is not ready yet. Please restart the app and try again.',
                              );
                            } catch (error) {
                              _showAdminMessage(statefulContext, 'We could not upload the image. Please try again.');
                            } finally {
                              setDialogState(() => isPickingImage = false);
                            }
                          },
                    icon: isPickingImage
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.add_photo_alternate_outlined),
                    label: Text(
                      isPickingImage ? 'Uploading image...' : 'Choose image (camera or gallery)',
                    ),
                  ),
                ),
                if (selectedImageName != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        'Selected: $selectedImageName',
                        style: const TextStyle(color: Color(0xFF475569)),
                      ),
                    ),
                  ),
                const SizedBox(height: 10),
                TextField(controller: imageController, decoration: const InputDecoration(labelText: 'Image URL')),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: isPickingImage
                  ? null
                  : () async {
                      await _runDialogAction(
                        context: dialogContext,
                        action: () async {
                          if (onAddCategory != null) {
                            await onAddCategory!(
                              name: nameController.text,
                              description: descriptionController.text,
                              imageUrl: imageController.text,
                            );
                          }
                        },
                      );
                    },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showEditCategoryDialog(BuildContext context, Category category) async {
    final nameController = TextEditingController(text: category.name);
    final descriptionController = TextEditingController(text: category.description);
    final imageController = TextEditingController(text: category.imageUrl);

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        title: const Text('Edit Category'),
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
              final updatedName = nameController.text.trim();
              await _runDialogAction(
                context: dialogContext,
                action: () async {
                  if (onUpdateCategory != null) {
                    await onUpdateCategory!(
                      categoryId: category.id,
                      name: updatedName,
                      description: descriptionController.text.trim(),
                      imageUrl: imageController.text.trim(),
                    );
                  }
                },
              );
              if (!context.mounted || updatedName.isEmpty) {
                return;
              }
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('$updatedName was updated successfully.')),
              );
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  Future<void> _showDeleteCategoryDialog(BuildContext context, Category category) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Category'),
        content: Text('Delete ${category.name}?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              await _runDialogAction(
                context: dialogContext,
                action: () async {
                  if (onDeleteCategory != null) {
                    await onDeleteCategory!(category.id);
                  }
                },
              );
              if (!context.mounted) {
                return;
              }
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${category.name} was deleted from category settings.')),
              );
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<ImageSource?> _showImageSourcePicker(BuildContext context) {
    return showModalBottomSheet<ImageSource>(
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
  }

  Future<String> _uploadCategoryImage(XFile imageFile) async {
    // Upload to Storage and then resolve a public download URL.
    final bytes = await imageFile.readAsBytes();
    final extension = _fileExtension(imageFile.name);
    final safeName = _safeFileName(imageFile.name);
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final storageRef = _storage
        .ref()
        .child('categories')
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

  Future<void> _showAddPaymentMethodDialog(BuildContext context) async {
    final labelController = TextEditingController();
    final iconController = TextEditingController();

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        title: const Text('Add Payment Method'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: labelController,
              decoration: const InputDecoration(labelText: 'Payment method name'),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: iconController,
              decoration: const InputDecoration(labelText: 'Icon URL (optional)'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final methodName = labelController.text.trim();
              await _runDialogAction(
                context: dialogContext,
                action: () async {
                  if (onAddPaymentOption != null) {
                    await onAddPaymentOption!(
                      label: methodName,
                      iconUrl: iconController.text.trim(),
                    );
                  }
                },
              );
              if (!context.mounted || methodName.isEmpty) {
                return;
              }
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('$methodName was added to payment settings.')),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _showEditPaymentMethodDialog(BuildContext context, PaymentOption option) async {
    final labelController = TextEditingController(text: option.label);
    final iconController = TextEditingController(text: option.iconUrl ?? '');

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Edit Payment Method'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: labelController, decoration: const InputDecoration(labelText: 'Name')),
            const SizedBox(height: 10),
            TextField(controller: iconController, decoration: const InputDecoration(labelText: 'Icon URL')),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final updatedName = labelController.text.trim();
              await _runDialogAction(
                context: dialogContext,
                action: () async {
                  if (onUpdatePaymentOption != null) {
                    await onUpdatePaymentOption!(
                      optionId: option.id,
                      label: updatedName,
                      iconUrl: iconController.text.trim(),
                    );
                  }
                },
              );
              if (!context.mounted || updatedName.isEmpty) {
                return;
              }
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('$updatedName was updated successfully.')),
              );
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  Future<void> _showDeletePaymentMethodDialog(BuildContext context, PaymentOption option) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Payment Method'),
        content: Text('Delete ${option.label}?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Cancel')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              await _runDialogAction(
                context: dialogContext,
                action: () async {
                  if (onDeletePaymentOption != null) {
                    await onDeletePaymentOption!(option.id);
                  }
                },
              );
              if (!context.mounted) {
                return;
              }
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${option.label} was deleted from payment settings.')),
              );
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _showCreateAdminDialog(BuildContext context) async {
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final passwordController = TextEditingController();
    var obscurePassword = true;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (statefulContext, setDialogState) => AlertDialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          title: const Text('Create Admin'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Admin name')),
                const SizedBox(height: 10),
                TextField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'Admin email'),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: passwordController,
                  obscureText: obscurePassword,
                  decoration: InputDecoration(
                    labelText: 'Admin password',
                    suffixIcon: IconButton(
                      tooltip: obscurePassword ? 'Show password' : 'Hide password',
                      onPressed: () {
                        setDialogState(() => obscurePassword = !obscurePassword);
                      },
                      icon: Icon(obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                await _runDialogAction(
                  context: dialogContext,
                  action: () async {
                    if (onCreateAdminAccount != null) {
                      await onCreateAdminAccount!(
                        name: nameController.text.trim(),
                        email: emailController.text.trim(),
                        password: passwordController.text,
                      );
                    }
                  },
                );
              },
              child: const Text('Save'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showEditAdminDialog(BuildContext context, AdminAccount admin) async {
    final nameController = TextEditingController(text: admin.name);
    final emailController = TextEditingController(text: admin.email);

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        title: const Text('Edit Admin'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Admin name')),
              const SizedBox(height: 10),
              TextField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Admin email'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final updatedName = nameController.text.trim();
              await _runDialogAction(
                context: dialogContext,
                action: () async {
                  if (onUpdateAdminAccount != null) {
                    await onUpdateAdminAccount!(
                      userId: admin.userId,
                      name: updatedName,
                      email: emailController.text.trim(),
                    );
                  }
                },
              );
              if (!context.mounted || updatedName.isEmpty) {
                return;
              }
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('$updatedName was updated successfully.')),
              );
            },
            child: const Text('Update'),
          ),
        ],
      ),
    );
  }

  Future<void> _showDeleteAdminDialog(BuildContext context, AdminAccount admin) async {
    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Delete Admin'),
        content: Text('Delete ${admin.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFDC2626),
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              await _runDialogAction(
                context: dialogContext,
                action: () async {
                  if (onRemoveAdmin != null) {
                    await onRemoveAdmin!(admin.userId);
                  }
                },
              );
              if (!context.mounted) {
                return;
              }
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${admin.name} was deleted successfully.')),
              );
            },
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  Future<void> _showApproveAdminDialog(BuildContext context, AdminAccount admin) async {
    final nextApproved = !admin.approved;
    final actionLabel = nextApproved ? 'Approve' : 'Set pending';
    final resultMessage = nextApproved
        ? '${admin.name} was approved successfully.'
        : '${admin.name} was moved to pending successfully.';

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(actionLabel),
        content: Text('$actionLabel ${admin.name}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF5E56E7),
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              await _runDialogAction(
                context: dialogContext,
                action: () async {
                  if (onApproveAdmin != null) {
                    await onApproveAdmin!(userId: admin.userId, approved: nextApproved);
                  }
                },
              );
              if (!context.mounted) {
                return;
              }
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text(resultMessage)),
              );
            },
            child: Text(actionLabel),
          ),
        ],
      ),
    );
  }

  Future<void> _showEditBranchDialog(BuildContext context, Branch branch) async {
    final nameController = TextEditingController(text: branch.name);
    final locationController = TextEditingController(text: branch.location);
    final phoneController = TextEditingController(text: branch.phoneNumber);
    var isActive = branch.isActive;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (statefulContext, setDialogState) => AlertDialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          title: const Text('Edit Branch'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: nameController, decoration: const InputDecoration(labelText: 'Branch name')),
                const SizedBox(height: 10),
                TextField(controller: locationController, decoration: const InputDecoration(labelText: 'Location')),
                const SizedBox(height: 10),
                TextField(
                  controller: phoneController,
                  keyboardType: TextInputType.phone,
                  decoration: const InputDecoration(labelText: 'Phone number'),
                ),
                const SizedBox(height: 8),
                SwitchListTile(
                  value: isActive,
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Active branch'),
                  onChanged: (value) => setDialogState(() => isActive = value),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                final updatedName = nameController.text.trim();
                await _runDialogAction(
                  context: dialogContext,
                  action: () async {
                    if (onUpdateBranch != null) {
                      await onUpdateBranch!(
                        branchId: branch.id,
                        name: updatedName,
                        location: locationController.text.trim(),
                        phoneNumber: phoneController.text.trim(),
                        isActive: isActive,
                      );
                    }
                  },
                );
                if (!context.mounted || updatedName.isEmpty) {
                  return;
                }
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('$updatedName branch was updated successfully.')),
                );
              },
              child: const Text('Update'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showUpdatePriceDialog(BuildContext context, Product product) async {
    final controller = TextEditingController(text: product.price.toStringAsFixed(2));

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text('Update Price - ${product.name}'),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(labelText: 'New price'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              await _runDialogAction(
                context: dialogContext,
                action: () async {
                  final value = double.tryParse(controller.text.trim());
                  if (value != null && onUpdateProductPrice != null) {
                    await onUpdateProductPrice!(product, value);
                  }
                },
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  Future<void> _runDialogAction({
    required BuildContext context,
    required Future<void> Function() action,
  }) async {
    // Reusable dialog action runner with friendly feedback on failures.
    try {
      await action();
      if (context.mounted) {
        Navigator.of(context).pop();
      }
    } on StateError catch (error) {
      _showAdminMessage(context, error.message);
    } catch (error) {
      _showAdminMessage(context, 'We could not complete that action. Please try again.');
    }
  }

  void _showAdminMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

}

