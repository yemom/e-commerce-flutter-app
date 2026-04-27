import 'package:flutter/material.dart';

import 'package:e_commerce_app_with_django/features/admin/presentation/models/admin_dashboard_view_data.dart';
import 'package:e_commerce_app_with_django/features/admin/presentation/providers/admin_settings_provider.dart';
import 'package:e_commerce_app_with_django/features/admin/presentation/services/admin_dashboard_view_data_service.dart';
import 'package:e_commerce_app_with_django/features/admin/presentation/widgets/dashboard/admin_dashboard_analytics_board.dart';
import 'package:e_commerce_app_with_django/features/admin/presentation/widgets/dashboard/admin_dashboard_content_layouts.dart';
import 'package:e_commerce_app_with_django/features/admin/presentation/widgets/dashboard/admin_dashboard_hero_card.dart';
import 'package:e_commerce_app_with_django/features/branches/domain/models/branch.dart';
import 'package:e_commerce_app_with_django/features/categories/domain/models/category.dart';
import 'package:e_commerce_app_with_django/features/orders/domain/models/order.dart';
import 'package:e_commerce_app_with_django/features/payment/domain/models/payment.dart';
import 'package:e_commerce_app_with_django/features/products/domain/models/product.dart';

class AdminDashboardBody extends StatelessWidget {
  const AdminDashboardBody({
    super.key,
    required this.dashboardTitle,
    required this.roleSections,
    required this.showBranchesSection,
    required this.branches,
    required this.orders,
    required this.products,
    required this.adminCategories,
    required this.adminPaymentOptions,
    required this.adminAccounts,
    required this.onAddProduct,
    required this.onOpenOrdersPage,
    required this.onOpenInventoryPage,
    required this.onOpenBranchesPage,
    required this.onOpenCategoriesPage,
    required this.onOpenAdminRequestsPage,
    required this.onOpenPaymentOptionsPage,
    required this.canManageAdmins,
    this.viewDataService = const AdminDashboardViewDataService(),
  });

  final String dashboardTitle;
  final List<String> roleSections;
  final bool showBranchesSection;
  final List<Branch> branches;
  final List<Order> orders;
  final List<Product> products;
  final List<Category> adminCategories;
  final List<PaymentOption> adminPaymentOptions;
  final List<AdminAccount> adminAccounts;
  final VoidCallback onAddProduct;
  final VoidCallback? onOpenOrdersPage;
  final VoidCallback? onOpenInventoryPage;
  final VoidCallback? onOpenBranchesPage;
  final VoidCallback? onOpenCategoriesPage;
  final VoidCallback? onOpenAdminRequestsPage;
  final VoidCallback? onOpenPaymentOptionsPage;
  final bool canManageAdmins;
  final AdminDashboardViewDataService viewDataService;

  @override
  Widget build(BuildContext context) {
    final viewData = viewDataService.build(
      branches: branches,
      orders: orders,
      products: products,
      categories: adminCategories,
      adminAccounts: adminAccounts,
    );

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFFF3EBDD), Color(0xFFF8F6F1)],
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          // Keep the dashboard centered and readable on very large screens.
          final maxWidth = constraints.maxWidth > 1280
              ? 1280.0
              : constraints.maxWidth;
          // Use a stacked layout on narrow screens and a split rail on wide screens.
          final isWide = constraints.maxWidth >= 1000;

          return Center(
            child: SizedBox(
              width: maxWidth,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(12, 12, 12, 20),
                children: [
                  AdminDashboardHeroCard(
                    dashboardTitle: dashboardTitle,
                    branchCount: branches.length,
                    orderCount: orders.length,
                    productCount: products.length,
                    categoryCount: adminCategories.length,
                    paymentCount: adminPaymentOptions.length,
                    pendingAdminCount: viewData.pendingRequests.length,
                    activeAdminCount: viewData.activeAdmins.length,
                    sectionTags: roleSections,
                  ),
                  const SizedBox(height: 14),
                  AdminDashboardAnalyticsBoard(
                    analytics: viewData.analytics,
                    branchCount: branches.length,
                    productCount: products.length,
                    categoryCount: adminCategories.length,
                    paymentCount: adminPaymentOptions.length,
                    pendingAdminCount: viewData.pendingRequests.length,
                    activeAdminCount: viewData.activeAdmins.length,
                  ),
                  const SizedBox(height: 14),
                  if (isWide)
                    AdminDashboardWideBodyLayout(
                      roleSections: roleSections,
                      branches: branches,
                      orders: orders,
                      products: products,
                      adminCategories: adminCategories,
                      adminPaymentOptions: adminPaymentOptions,
                      onAddProduct: onAddProduct,
                      onOpenInventoryPage: onOpenInventoryPage,
                      onOpenOrdersPage: onOpenOrdersPage,
                      onOpenAdminRequestsPage: onOpenAdminRequestsPage,
                      onOpenBranchesPage: onOpenBranchesPage,
                      onOpenCategoriesPage: onOpenCategoriesPage,
                      onOpenPaymentOptionsPage: onOpenPaymentOptionsPage,
                      showBranchesSection: showBranchesSection,
                      canManageAdmins: canManageAdmins,
                      viewData: viewData,
                    )
                  else
                    AdminDashboardStackedBodyLayout(
                      roleSections: roleSections,
                      branches: branches,
                      orders: orders,
                      products: products,
                      adminCategories: adminCategories,
                      adminPaymentOptions: adminPaymentOptions,
                      onAddProduct: onAddProduct,
                      onOpenInventoryPage: onOpenInventoryPage,
                      onOpenOrdersPage: onOpenOrdersPage,
                      onOpenAdminRequestsPage: onOpenAdminRequestsPage,
                      onOpenBranchesPage: onOpenBranchesPage,
                      onOpenCategoriesPage: onOpenCategoriesPage,
                      onOpenPaymentOptionsPage: onOpenPaymentOptionsPage,
                      showBranchesSection: showBranchesSection,
                      canManageAdmins: canManageAdmins,
                      viewData: viewData,
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
