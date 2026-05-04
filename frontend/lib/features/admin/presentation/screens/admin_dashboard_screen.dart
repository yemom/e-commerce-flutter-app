/// Shows admin controls for branches, orders, categories, payments, and admins.
library;

import 'package:flutter/material.dart';

import 'package:e_commerce_app_with_django/features/admin/presentation/providers/admin_settings_provider.dart';
import 'package:e_commerce_app_with_django/features/admin/presentation/widgets/dashboard/dashboard.dart';
import 'package:e_commerce_app_with_django/features/branches/domain/models/branch.dart';
import 'package:e_commerce_app_with_django/features/categories/domain/models/category.dart';
import 'package:e_commerce_app_with_django/features/orders/domain/models/order.dart';
import 'package:e_commerce_app_with_django/features/payment/domain/models/payment.dart';
import 'package:e_commerce_app_with_django/features/products/domain/models/product.dart';

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
    this.onDeleteBranch,
    this.onOpenOrdersPage,
    this.onOpenInventoryPage,
    this.onOpenDriversPage,
    this.onOpenBranchesPage,
    this.onOpenCategoriesPage,
    this.onOpenAdminRequestsPage,
    this.onOpenPaymentOptionsPage,
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
  })?
  onAddCategory;
  final Future<void> Function(String categoryId, bool isActive)?
  onToggleCategory;
  final Future<Category?> Function(String categoryId)? onFetchCategory;
  final Future<void> Function({
    required String categoryId,
    required String name,
    required String description,
    required String imageUrl,
  })?
  onUpdateCategory;
  final Future<void> Function(String categoryId)? onDeleteCategory;
  final Future<void> Function({required String label, String? iconUrl})?
  onAddPaymentOption;
  final Future<PaymentOption?> Function(String optionId)? onFetchPaymentOption;
  final Future<void> Function({
    required String optionId,
    required String label,
    String? iconUrl,
  })?
  onUpdatePaymentOption;
  final Future<void> Function(String optionId)? onDeletePaymentOption;
  final Future<void> Function(String optionId, bool isEnabled)?
  onTogglePaymentOption;
  final Future<void> Function(Product product, double newPrice)?
  onUpdateProductPrice;
  final Future<void> Function(String productId)? onDeleteProduct;
  final Future<void> Function({
    required String name,
    required String email,
    required String password,
  })?
  onCreateAdminAccount;
  final Future<AdminAccount?> Function(String userId)? onFetchAdminAccount;
  final Future<void> Function({
    required String userId,
    required String name,
    required String email,
  })?
  onUpdateAdminAccount;
  final Future<void> Function({required String userId, required bool approved})?
  onApproveAdmin;
  final Future<void> Function(String userId)? onRemoveAdmin;
  final Future<Branch?> Function(String branchId)? onFetchBranch;
  final Future<void> Function({
    required String branchId,
    required String name,
    required String location,
    required String phoneNumber,
    required bool isActive,
  })?
  onUpdateBranch;
  final Future<void> Function(String branchId)? onDeleteBranch;
  final VoidCallback? onOpenOrdersPage;
  final VoidCallback? onOpenInventoryPage;
  final VoidCallback? onOpenDriversPage;
  final VoidCallback? onOpenBranchesPage;
  final VoidCallback? onOpenCategoriesPage;
  final VoidCallback? onOpenAdminRequestsPage;
  final VoidCallback? onOpenPaymentOptionsPage;

  @override
  Widget build(BuildContext context) {
    // The top-level dashboard shell stays thin and delegates the actual content rendering to the reusable body widgets below.
    final pendingPayments = orders
        .where((order) => order.payment.status == PaymentStatus.pending)
        .length;

    return Scaffold(
      appBar: AppBar(
        title: Text(dashboardTitle),
        actions: [
          // Fast actions stay in the app bar because they are the most frequent admin entry points.
          IconButton(
            tooltip: 'Add product',
            onPressed: onAddProduct,
            icon: const Icon(Icons.add_box_outlined),
          ),
          DashboardActionIconButton(
            icon: Icons.receipt_long_outlined,
            tooltip: 'Open orders (pending payments: $pendingPayments)',
            badgeCount: pendingPayments,
            onPressed: onOpenOrdersPage,
          ),
          IconButton(
            tooltip: 'Open inventory',
            onPressed: onOpenInventoryPage,
            icon: const Icon(Icons.inventory_2_outlined),
          ),
          IconButton(
            tooltip: 'Open drivers',
            onPressed: onOpenDriversPage,
            icon: const Icon(Icons.local_shipping_outlined),
          ),
          IconButton(
            tooltip: 'Log out',
            onPressed: () => onLogout(),
            icon: const Icon(Icons.logout_rounded),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: AdminDashboardBody(
        // The body receives data and callbacks only, which keeps this screen easy to test and reuse.
        dashboardTitle: dashboardTitle,
        roleSections: roleSections,
        showBranchesSection: showBranchesSection,
        branches: branches,
        orders: orders,
        products: products,
        adminCategories: adminCategories,
        adminPaymentOptions: adminPaymentOptions,
        adminAccounts: adminAccounts,
        onAddProduct: onAddProduct,
        onOpenOrdersPage: onOpenOrdersPage,
        onOpenInventoryPage: onOpenInventoryPage,
        onOpenBranchesPage: onOpenBranchesPage,
        onOpenDriversPage: onOpenDriversPage,
        onOpenCategoriesPage: onOpenCategoriesPage,
        onOpenAdminRequestsPage: onOpenAdminRequestsPage,
        onOpenPaymentOptionsPage: onOpenPaymentOptionsPage,
        canManageAdmins: onCreateAdminAccount != null,
      ),
    );
  }
}
