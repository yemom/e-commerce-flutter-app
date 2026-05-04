import 'package:flutter/material.dart';

import 'package:e_commerce_app_with_django/features/admin/presentation/models/admin_dashboard_view_data.dart';
import 'package:e_commerce_app_with_django/features/admin/presentation/widgets/dashboard/admin_dashboard_quick_rail.dart';
import 'package:e_commerce_app_with_django/features/admin/presentation/widgets/dashboard/admin_dashboard_sections_column.dart';
import 'package:e_commerce_app_with_django/features/branches/domain/models/branch.dart';
import 'package:e_commerce_app_with_django/features/categories/domain/models/category.dart';
import 'package:e_commerce_app_with_django/features/orders/domain/models/order.dart';
import 'package:e_commerce_app_with_django/features/payment/domain/models/payment.dart';
import 'package:e_commerce_app_with_django/features/products/domain/models/product.dart';

class AdminDashboardWideBodyLayout extends StatelessWidget {
  const AdminDashboardWideBodyLayout({
    super.key,
    required this.roleSections,
    required this.branches,
    required this.orders,
    required this.products,
    required this.adminCategories,
    required this.adminPaymentOptions,
    required this.onAddProduct,
    required this.onOpenInventoryPage,
    this.onOpenDriversPage,
    required this.onOpenOrdersPage,
    required this.onOpenAdminRequestsPage,
    required this.onOpenBranchesPage,
    required this.onOpenCategoriesPage,
    required this.onOpenPaymentOptionsPage,
    required this.showBranchesSection,
    required this.canManageAdmins,
    required this.viewData,
  });

  final List<String> roleSections;
  final List<Branch> branches;
  final List<Order> orders;
  final List<Product> products;
  final List<Category> adminCategories;
  final List<PaymentOption> adminPaymentOptions;
  final VoidCallback onAddProduct;
  final VoidCallback? onOpenInventoryPage;
  // The driver shortcut is optional so the layout stays reusable in non-driver admin views.
  final VoidCallback? onOpenDriversPage;
  final VoidCallback? onOpenOrdersPage;
  final VoidCallback? onOpenAdminRequestsPage;
  final VoidCallback? onOpenBranchesPage;
  final VoidCallback? onOpenCategoriesPage;
  final VoidCallback? onOpenPaymentOptionsPage;
  final bool showBranchesSection;
  final bool canManageAdmins;
  final AdminDashboardViewData viewData;

  @override
  Widget build(BuildContext context) {
    // Wide screens use a side rail plus a content column so the dashboard feels dense without becoming cramped.
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AdminDashboardQuickRail(
          onAddProduct: onAddProduct,
          onOpenInventoryPage: onOpenInventoryPage,
          onOpenOrdersPage: onOpenOrdersPage,
          onOpenAdminRequestsPage: onOpenAdminRequestsPage,
          branchCount: branches.length,
          pendingAdminCount: viewData.pendingRequests.length,
          orderCount: orders.length,
          productCount: products.length,
          sections: roleSections,
          canManageAdmins: canManageAdmins,
        ),
        const SizedBox(width: 14),
        Expanded(
          child: AdminDashboardSectionsColumn(
            showBranchesSection: showBranchesSection,
            branches: branches,
            orders: orders,
            products: products,
            adminCategories: adminCategories,
            adminPaymentOptions: adminPaymentOptions,
            activeAdmins: viewData.activeAdmins,
            superAdmins: viewData.superAdmins,
            pendingRequests: viewData.pendingRequests,
            onOpenBranchesPage: onOpenBranchesPage,
            onOpenDriversPage: onOpenDriversPage,
            onOpenCategoriesPage: onOpenCategoriesPage,
            onOpenAdminRequestsPage: onOpenAdminRequestsPage,
            onOpenPaymentOptionsPage: onOpenPaymentOptionsPage,
            onOpenOrdersPage: onOpenOrdersPage,
            onOpenInventoryPage: onOpenInventoryPage,
          ),
        ),
      ],
    );
  }
}

class AdminDashboardStackedBodyLayout extends StatelessWidget {
  const AdminDashboardStackedBodyLayout({
    super.key,
    required this.roleSections,
    required this.branches,
    required this.orders,
    required this.products,
    required this.adminCategories,
    required this.adminPaymentOptions,
    required this.onAddProduct,
    required this.onOpenInventoryPage,
    this.onOpenDriversPage,
    required this.onOpenOrdersPage,
    required this.onOpenAdminRequestsPage,
    required this.onOpenBranchesPage,
    required this.onOpenCategoriesPage,
    required this.onOpenPaymentOptionsPage,
    required this.showBranchesSection,
    required this.canManageAdmins,
    required this.viewData,
  });

  final List<String> roleSections;
  final List<Branch> branches;
  final List<Order> orders;
  final List<Product> products;
  final List<Category> adminCategories;
  final List<PaymentOption> adminPaymentOptions;
  final VoidCallback onAddProduct;
  final VoidCallback? onOpenInventoryPage;
  // The driver shortcut is optional so the stacked layout can stay generic.
  final VoidCallback? onOpenDriversPage;
  final VoidCallback? onOpenOrdersPage;
  final VoidCallback? onOpenAdminRequestsPage;
  final VoidCallback? onOpenBranchesPage;
  final VoidCallback? onOpenCategoriesPage;
  final VoidCallback? onOpenPaymentOptionsPage;
  final bool showBranchesSection;
  final bool canManageAdmins;
  final AdminDashboardViewData viewData;

  @override
  Widget build(BuildContext context) {
    // Narrow screens stack the same content vertically so the most important actions remain reachable on phones and small tablets.
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AdminDashboardQuickRail(
          onAddProduct: onAddProduct,
          onOpenInventoryPage: onOpenInventoryPage,
          onOpenOrdersPage: onOpenOrdersPage,
          onOpenAdminRequestsPage: onOpenAdminRequestsPage,
          branchCount: branches.length,
          pendingAdminCount: viewData.pendingRequests.length,
          orderCount: orders.length,
          productCount: products.length,
          sections: roleSections,
          canManageAdmins: canManageAdmins,
        ),
        const SizedBox(height: 14),
        AdminDashboardSectionsColumn(
          showBranchesSection: showBranchesSection,
          branches: branches,
          orders: orders,
          products: products,
          adminCategories: adminCategories,
          adminPaymentOptions: adminPaymentOptions,
          activeAdmins: viewData.activeAdmins,
          superAdmins: viewData.superAdmins,
          pendingRequests: viewData.pendingRequests,
          onOpenBranchesPage: onOpenBranchesPage,
          onOpenDriversPage: onOpenDriversPage,
          onOpenCategoriesPage: onOpenCategoriesPage,
          onOpenAdminRequestsPage: onOpenAdminRequestsPage,
          onOpenPaymentOptionsPage: onOpenPaymentOptionsPage,
          onOpenOrdersPage: onOpenOrdersPage,
          onOpenInventoryPage: onOpenInventoryPage,
        ),
      ],
    );
  }
}
