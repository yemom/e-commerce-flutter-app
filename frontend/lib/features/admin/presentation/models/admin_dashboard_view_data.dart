import 'package:e_commerce_app_with_django/features/admin/presentation/models/admin_dashboard_analytics.dart';
import 'package:e_commerce_app_with_django/features/admin/presentation/providers/admin_settings_provider.dart';

class AdminDashboardViewData {
  const AdminDashboardViewData({
    required this.pendingPayments,
    required this.pendingRequests,
    required this.activeAdmins,
    required this.superAdmins,
    required this.analytics,
  });

  final int pendingPayments;
  final List<AdminAccount> pendingRequests;
  final List<AdminAccount> activeAdmins;
  final List<AdminAccount> superAdmins;
  final AdminDashboardAnalytics analytics;
}
