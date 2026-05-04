library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:e_commerce_app_with_django/app/presentation/widgets/app_status_screen.dart';
import 'package:e_commerce_app_with_django/app/providers/app_flow_providers.dart';
import 'package:e_commerce_app_with_django/app/services/app_navigation_service.dart';
import 'package:e_commerce_app_with_django/features/admin/application/admin_portal_service.dart';
import 'package:e_commerce_app_with_django/features/admin/presentation/providers/admin_settings_provider.dart';
import 'package:e_commerce_app_with_django/features/admin/presentation/screens/add_product_screen.dart';
import 'package:e_commerce_app_with_django/features/admin/presentation/screens/admin_branches_screen.dart';
import 'package:e_commerce_app_with_django/features/admin/presentation/screens/admin_categories_screen.dart';
import 'package:e_commerce_app_with_django/features/admin/presentation/screens/admin_dashboard_screen.dart';
import 'package:e_commerce_app_with_django/features/admin/presentation/screens/admin_drivers_screen.dart';
import 'package:e_commerce_app_with_django/features/admin/presentation/screens/admin_inventory_screen.dart';
import 'package:e_commerce_app_with_django/features/admin/presentation/screens/admin_orders_screen.dart';
import 'package:e_commerce_app_with_django/features/admin/presentation/screens/admin_payment_options_screen.dart';
import 'package:e_commerce_app_with_django/features/admin/presentation/screens/admin_requests_screen.dart';
import 'package:e_commerce_app_with_django/features/auth/domain/models/user_role.dart';
import 'package:e_commerce_app_with_django/features/auth/presentation/providers/auth_provider.dart';
import 'package:e_commerce_app_with_django/features/branches/domain/models/branch.dart';
import 'package:e_commerce_app_with_django/features/branches/presentation/providers/branch_provider.dart';
import 'package:e_commerce_app_with_django/features/categories/domain/models/category.dart';
import 'package:e_commerce_app_with_django/features/categories/presentation/providers/category_provider.dart';
import 'package:e_commerce_app_with_django/features/orders/application/order_service.dart';
import 'package:e_commerce_app_with_django/features/orders/presentation/providers/order_provider.dart';
import 'package:e_commerce_app_with_django/features/products/presentation/providers/product_provider.dart';

class AdminPortalShell extends ConsumerWidget {
  const AdminPortalShell({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bootstrap = ref.watch(adminPortalBootstrapProvider);
    final authState = ref.watch(authProvider);
    final branchState = ref.watch(branchProvider);
    final categoryState = ref.watch(categoryProvider);
    final productState = ref.watch(productProvider);
    final orderState = ref.watch(orderProvider);
    final adminSettingsState = ref.watch(adminSettingsProvider);

    if (bootstrap.isLoading) {
      return const AppLoadingScreen();
    }

    if (bootstrap.hasError) {
      return const AppMessageScreen(
        message: 'We could not load the admin portal. Please try again.',
      );
    }

    final session = authState.session;
    if (session == null) {
      return const AppLoadingScreen();
    }

    final isSuperAdmin = session.isSuperAdmin;
    final canAddCategory = session.role == AppUserRole.admin || isSuperAdmin;
    final canAddPaymentOption =
        session.role == AppUserRole.admin || isSuperAdmin;
    final sections = isSuperAdmin
        ? const [
            'Products',
            'Categories',
            'Orders',
            'Payments',
            'Drivers',
            'Admins',
            'Branches',
          ]
        : const ['Products', 'Orders', 'Payments', 'Drivers', 'Categories'];
    final adminCategories = adminSettingsState.categories.isNotEmpty
        ? adminSettingsState.categories
        : categoryState.categories;

    final navigation = ref.read(appNavigationServiceProvider);
    final adminService = ref.read(adminPortalServiceProvider);
    final orderService = ref.read(orderServiceProvider);

    final addCategory = canAddCategory ? adminService.addCategory : null;
    final toggleCategory = isSuperAdmin ? adminService.toggleCategory : null;
    final fetchCategory = isSuperAdmin ? adminService.fetchCategory : null;
    final updateCategory = isSuperAdmin ? adminService.updateCategory : null;
    final deleteCategory = isSuperAdmin ? adminService.deleteCategory : null;
    final addPaymentOption = canAddPaymentOption
        ? adminService.addPaymentOption
        : null;
    final fetchPaymentOption = isSuperAdmin
        ? adminService.fetchPaymentOption
        : null;
    final updatePaymentOption = isSuperAdmin
        ? adminService.updatePaymentOption
        : null;
    final deletePaymentOption = isSuperAdmin
        ? adminService.deletePaymentOption
        : null;
    final togglePaymentOption = isSuperAdmin
        ? adminService.togglePaymentOption
        : null;
    final createAdminAccount = isSuperAdmin
        ? adminService.createAdminAccount
        : null;
    final fetchAdminAccount = isSuperAdmin
        ? adminService.fetchAdminAccount
        : null;
    final updateAdminAccount = isSuperAdmin
        ? adminService.updateAdminAccount
        : null;
    final approveAdmin = isSuperAdmin ? adminService.approveAdmin : null;
    final removeAdmin = isSuperAdmin ? adminService.removeAdmin : null;
    final fetchBranch = isSuperAdmin ? adminService.fetchBranch : null;
    final updateBranch = isSuperAdmin ? adminService.updateBranch : null;
    final deleteBranch = isSuperAdmin ? adminService.deleteBranch : null;

    return AdminDashboardScreen(
      dashboardTitle: isSuperAdmin
          ? 'Super Admin Dashboard'
          : 'Admin Dashboard',
      roleSections: sections,
      showBranchesSection: isSuperAdmin,
      onLogout: () => ref.read(authProvider.notifier).logout(),
      branches: branchState.branches,
      orders: orderState.orders,
      products: productState.products,
      adminCategories: adminCategories,
      adminPaymentOptions: adminSettingsState.paymentOptions,
      adminAccounts: adminSettingsState.adminAccounts,
      onAddCategory: addCategory,
      onToggleCategory: toggleCategory,
      onFetchCategory: fetchCategory,
      onUpdateCategory: updateCategory,
      onDeleteCategory: deleteCategory,
      onAddPaymentOption: addPaymentOption,
      onFetchPaymentOption: fetchPaymentOption,
      onUpdatePaymentOption: updatePaymentOption,
      onDeletePaymentOption: deletePaymentOption,
      onTogglePaymentOption: togglePaymentOption,
      onUpdateProductPrice: adminService.updateProductPrice,
      onDeleteProduct: adminService.deleteProduct,
      onCreateAdminAccount: createAdminAccount,
      onFetchAdminAccount: fetchAdminAccount,
      onUpdateAdminAccount: updateAdminAccount,
      onApproveAdmin: approveAdmin,
      onRemoveAdmin: removeAdmin,
      onFetchBranch: fetchBranch,
      onUpdateBranch: updateBranch,
      onDeleteBranch: deleteBranch,
      onAddProduct: () {
        _openAddProduct(
          ref,
          categories: adminCategories,
          branches: branchState.branches,
        );
      },
      onVerifyPayment: orderService.verifyPayment,
      onMarkOrderShipped: orderService.markOrderShipped,
      onMarkOrderDelivered: orderService.markOrderDelivered,
      onOpenOrdersPage: () {
        navigation.push(const AdminOrdersPage());
      },
      onOpenInventoryPage: () {
        navigation.push(
          AdminInventoryScreen(
            isSuperAdmin: isSuperAdmin,
            branchId: branchState.selectedBranchId,
          ),
        );
      },
      onOpenDriversPage: () {
        navigation.push(const AdminDriversScreen());
      },
      onOpenBranchesPage: isSuperAdmin
          ? () {
              navigation.push(
                AdminBranchesScreen(
                  branches: ref.read(branchProvider).branches,
                  onFetchBranch: fetchBranch!,
                  onUpdateBranch: updateBranch!,
                  onDeleteBranch: deleteBranch!,
                ),
              );
            }
          : null,
      onOpenCategoriesPage: () {
        navigation.push(
          AdminCategoriesScreen(
            categories: adminCategories,
            onAddCategory: addCategory,
            onToggleCategory: toggleCategory,
            onFetchCategory: fetchCategory,
            onUpdateCategory: updateCategory,
            onDeleteCategory: deleteCategory,
          ),
        );
      },
      onOpenAdminRequestsPage: isSuperAdmin
          ? () {
              navigation.push(
                AdminRequestsScreen(
                  adminAccounts: adminSettingsState.adminAccounts,
                  onCreateAdminAccount: createAdminAccount!,
                  onFetchAdminAccount: fetchAdminAccount!,
                  onUpdateAdminAccount: updateAdminAccount!,
                  onApproveAdmin: approveAdmin!,
                  onRemoveAdmin: removeAdmin!,
                ),
              );
            }
          : null,
      onOpenPaymentOptionsPage: () {
        navigation.push(
          AdminPaymentOptionsScreen(
            paymentOptions: adminSettingsState.paymentOptions,
            onAddPaymentOption: addPaymentOption,
            onFetchPaymentOption: fetchPaymentOption,
            onUpdatePaymentOption: updatePaymentOption,
            onDeletePaymentOption: deletePaymentOption,
            onTogglePaymentOption: togglePaymentOption,
          ),
        );
      },
    );
  }

  Future<void> _openAddProduct(
    WidgetRef ref, {
    required List<Category> categories,
    required List<Branch> branches,
  }) async {
    final navigation = ref.read(appNavigationServiceProvider);
    final adminService = ref.read(adminPortalServiceProvider);

    await navigation.push(
      AddProductScreen(
        categories: categories,
        branches: branches,

        /// ✅ FIXED WRAPPER
        onUploadImage:
            ({required List<int> bytes, required String fileName}) async {
              return await adminService.uploadProductImage(
                bytes: bytes,
                fileName: fileName,
              );
            },

        /// ✅ SUBMIT PRODUCT
        onSubmit: (product) async {
          await adminService.addProduct(product);
          navigation.pop();
        },
      ),
    );
  }
}
