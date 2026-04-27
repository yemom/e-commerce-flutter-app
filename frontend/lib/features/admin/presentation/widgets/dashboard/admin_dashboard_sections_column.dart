import 'package:flutter/material.dart';

import 'package:e_commerce_app_with_django/features/admin/presentation/providers/admin_settings_provider.dart';
import 'package:e_commerce_app_with_django/features/admin/presentation/widgets/dashboard/dashboard_badge_widgets.dart';
import 'package:e_commerce_app_with_django/features/admin/presentation/widgets/dashboard/dashboard_common_widgets.dart';
import 'package:e_commerce_app_with_django/features/branches/domain/models/branch.dart';
import 'package:e_commerce_app_with_django/features/categories/domain/models/category.dart';
import 'package:e_commerce_app_with_django/features/orders/domain/models/order.dart';
import 'package:e_commerce_app_with_django/features/payment/domain/models/payment.dart';
import 'package:e_commerce_app_with_django/features/products/domain/models/product.dart';

class AdminDashboardSectionsColumn extends StatelessWidget {
  const AdminDashboardSectionsColumn({
    super.key,
    required this.showBranchesSection,
    required this.branches,
    required this.orders,
    required this.products,
    required this.adminCategories,
    required this.adminPaymentOptions,
    required this.activeAdmins,
    required this.superAdmins,
    required this.pendingRequests,
    required this.onOpenBranchesPage,
    required this.onOpenCategoriesPage,
    required this.onOpenAdminRequestsPage,
    required this.onOpenPaymentOptionsPage,
    required this.onOpenOrdersPage,
    required this.onOpenInventoryPage,
  });

  final bool showBranchesSection;
  final List<Branch> branches;
  final List<Order> orders;
  final List<Product> products;
  final List<Category> adminCategories;
  final List<PaymentOption> adminPaymentOptions;
  final List<AdminAccount> activeAdmins;
  final List<AdminAccount> superAdmins;
  final List<AdminAccount> pendingRequests;
  final VoidCallback? onOpenBranchesPage;
  final VoidCallback? onOpenCategoriesPage;
  final VoidCallback? onOpenAdminRequestsPage;
  final VoidCallback? onOpenPaymentOptionsPage;
  final VoidCallback? onOpenOrdersPage;
  final VoidCallback? onOpenInventoryPage;

  @override
  Widget build(BuildContext context) {
    final pendingPayments = orders
        .where((order) => order.payment.status == PaymentStatus.pending)
        .length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (showBranchesSection) ...[
          DashboardSectionCard(
            title: 'Branches',
            onOpenPage: onOpenBranchesPage,
            summary: branches.isEmpty
                ? 'No branches found.'
                : '${branches.length} branch(s) available',
            actionLabel: 'Open Branches Page',
            actionIcon: Icons.storefront_outlined,
          ),
          const SizedBox(height: 14),
        ],
        DashboardSectionCard(
          title: 'Admin Requests',
          onOpenPage: onOpenAdminRequestsPage,
          summary: pendingRequests.isEmpty
              ? 'No pending admin requests.'
              : '${pendingRequests.length} pending admin request(s) need review.',
          actionLabel: 'Open Admin Requests',
          actionIcon: Icons.manage_accounts_outlined,
        ),
        const SizedBox(height: 14),
        DashboardSectionCard(
          title: 'Categories',
          onOpenPage: onOpenCategoriesPage,
          summary: adminCategories.isEmpty
              ? 'No categories found.'
              : '${adminCategories.length} category(s) available',
          actionLabel: 'Open Categories Page',
          actionIcon: Icons.category_outlined,
        ),
        const SizedBox(height: 14),
        DashboardSectionCard(
          title: 'Payment Options',
          onOpenPage: onOpenPaymentOptionsPage,
          summary: adminPaymentOptions.isEmpty
              ? 'No payment options found.'
              : '${adminPaymentOptions.where((item) => item.isEnabled).length} enabled payment option(s).',
          actionLabel: 'Open Payment Options',
          actionIcon: Icons.payments_outlined,
        ),
        const SizedBox(height: 14),
        DashboardSectionCard(
          title: 'Orders',
          onOpenPage: onOpenOrdersPage,
          summary:
              '${orders.where((order) => order.status == OrderStatus.pending).length} pending order(s), '
              '$pendingPayments pending payment(s) for admin approval.',
          actionLabel: 'Open Orders Page',
          actionIcon: Icons.receipt_long_outlined,
          entryBadgeCount: pendingPayments,
        ),
        const SizedBox(height: 14),
        DashboardSectionCard(
          title: 'Inventory',
          onOpenPage: onOpenInventoryPage,
          summary: products.isEmpty
              ? 'No products loaded yet.'
              : '${products.length} product(s) available.',
          actionLabel: 'Open Inventory Page',
          actionIcon: Icons.inventory_2_outlined,
        ),
        if (activeAdmins.isNotEmpty || superAdmins.isNotEmpty) ...[
          const SizedBox(height: 14),
          DashboardSectionCard(
            title: 'Admin Accounts',
            onOpenPage: onOpenAdminRequestsPage,
            summary:
                '${activeAdmins.length + superAdmins.length} active admin account(s).',
            actionLabel: 'Open Admin Requests Page',
            actionIcon: Icons.manage_accounts_outlined,
          ),
        ],
      ],
    );
  }
}

class DashboardSectionCard extends StatelessWidget {
  const DashboardSectionCard({
    super.key,
    required this.title,
    required this.summary,
    this.onOpenPage,
    this.actionLabel,
    this.actionIcon,
    this.entryBadgeCount = 0,
  });

  final String title;
  final String summary;
  final VoidCallback? onOpenPage;
  final String? actionLabel;
  final IconData? actionIcon;
  final int entryBadgeCount;

  @override
  Widget build(BuildContext context) {
    return DashboardDataCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 8),
          Text(summary, style: const TextStyle(color: Color(0xFF6B7280))),
          if (onOpenPage != null && actionLabel != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                FilledButton.icon(
                  onPressed: onOpenPage,
                  icon: DashboardIconWithBadge(
                    icon: actionIcon ?? Icons.open_in_new_rounded,
                    badgeCount: entryBadgeCount,
                  ),
                  label: Text(actionLabel!),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
