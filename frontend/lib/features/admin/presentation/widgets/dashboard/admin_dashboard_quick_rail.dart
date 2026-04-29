import 'package:flutter/material.dart';

import 'package:e_commerce_app_with_django/features/admin/presentation/widgets/dashboard/dashboard_common_widgets.dart';

class AdminDashboardQuickRail extends StatelessWidget {
  const AdminDashboardQuickRail({
    super.key,
    required this.onAddProduct,
    required this.onOpenInventoryPage,
    required this.onOpenOrdersPage,
    required this.onOpenAdminRequestsPage,
    required this.branchCount,
    required this.pendingAdminCount,
    required this.orderCount,
    required this.productCount,
    required this.sections,
    required this.canManageAdmins,
  });

  final VoidCallback onAddProduct;
  final VoidCallback? onOpenInventoryPage;
  final VoidCallback? onOpenOrdersPage;
  final VoidCallback? onOpenAdminRequestsPage;
  final int branchCount;
  final int pendingAdminCount;
  final int orderCount;
  final int productCount;
  final List<String> sections;
  final bool canManageAdmins;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 300,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Quick actions stay at the top so the highest-frequency admin tasks are always one tap away.
          DashboardDataCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Quick actions',
                  style: TextStyle(color: Color(0xFF7B8091), fontSize: 12),
                ),
                const SizedBox(height: 10),
                DashboardSideActionButton(
                  icon: Icons.add_box_outlined,
                  label: 'Add product',
                  onPressed: onAddProduct,
                ),
                const SizedBox(height: 10),
                DashboardSideActionButton(
                  icon: Icons.receipt_long_outlined,
                  label: 'Open orders',
                  onPressed: onOpenOrdersPage,
                ),
                const SizedBox(height: 10),
                DashboardSideActionButton(
                  icon: Icons.inventory_2_outlined,
                  label: 'Open inventory',
                  onPressed: onOpenInventoryPage,
                ),
                const SizedBox(height: 10),
                DashboardSideActionButton(
                  icon: Icons.manage_accounts_outlined,
                  label: 'Open admin requests',
                  onPressed: onOpenAdminRequestsPage,
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // These metrics give the admin a fast read on the current size of the operation.
          DashboardDataCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'At a glance',
                  style: TextStyle(color: Color(0xFF7B8091), fontSize: 12),
                ),
                const SizedBox(height: 12),
                DashboardMiniMetric(label: 'Branches', value: '$branchCount'),
                DashboardMiniMetric(
                  label: 'Pending admins',
                  value: '$pendingAdminCount',
                ),
                DashboardMiniMetric(label: 'Orders', value: '$orderCount'),
                DashboardMiniMetric(label: 'Products', value: '$productCount'),
              ],
            ),
          ),
          const SizedBox(height: 12),
          // The section list mirrors the main dashboard navigation so users can jump back into the right area quickly.
          DashboardDataCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Sections',
                  style: TextStyle(color: Color(0xFF7B8091), fontSize: 12),
                ),
                const SizedBox(height: 10),
                for (final section in sections)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF8F9FE),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Text(
                        section,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (canManageAdmins) ...[
            const SizedBox(height: 12),
            // Super admins see a small pending-access summary so review work does not get buried.
            DashboardDataCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Admin access',
                    style: TextStyle(color: Color(0xFF7B8091), fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '$pendingAdminCount pending',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 4),
                  Text('$pendingAdminCount request(s) waiting for review'),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
