import 'package:e_commerce_app_with_django/features/admin/presentation/models/admin_dashboard_view_data.dart';
import 'package:e_commerce_app_with_django/features/admin/presentation/providers/admin_settings_provider.dart';
import 'package:e_commerce_app_with_django/features/admin/presentation/services/admin_dashboard_analytics_service.dart';
import 'package:e_commerce_app_with_django/features/auth/domain/models/user_role.dart';
import 'package:e_commerce_app_with_django/features/branches/domain/models/branch.dart';
import 'package:e_commerce_app_with_django/features/categories/domain/models/category.dart';
import 'package:e_commerce_app_with_django/features/orders/domain/models/order.dart';
import 'package:e_commerce_app_with_django/features/payment/domain/models/payment.dart';
import 'package:e_commerce_app_with_django/features/products/domain/models/product.dart';

class AdminDashboardViewDataService {
  const AdminDashboardViewDataService({
    this.analyticsService = const AdminDashboardAnalyticsService(),
  });

  final AdminDashboardAnalyticsService analyticsService;

  AdminDashboardViewData build({
    required List<Branch> branches,
    required List<Order> orders,
    required List<Product> products,
    required List<Category> categories,
    required List<AdminAccount> adminAccounts,
  }) {
    final pendingPayments = orders
        .where((order) => order.payment.status == PaymentStatus.pending)
        .length;

    final pendingRequests = adminAccounts
        .where((admin) => admin.role == AppUserRole.admin && !admin.approved)
        .toList(growable: false);
    final activeAdmins = adminAccounts
        .where((admin) => admin.role == AppUserRole.admin && admin.approved)
        .toList(growable: false);
    final superAdmins = adminAccounts
        .where((admin) => admin.role == AppUserRole.superAdmin)
        .toList(growable: false);

    return AdminDashboardViewData(
      pendingPayments: pendingPayments,
      pendingRequests: pendingRequests,
      activeAdmins: activeAdmins,
      superAdmins: superAdmins,
      analytics: analyticsService.build(
        orders: orders,
        products: products,
        branches: branches,
        categories: categories,
      ),
    );
  }
}
