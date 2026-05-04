import 'package:e_commerce_app_with_django/driver_app/services/api_service.dart';

class AdminApiService {
  AdminApiService(this.api);

  final ApiService api;

  Future<String> fetchAdminName() async {
    final profile = await api.fetchAdminProfile();
    return profile['name'] as String? ?? 'Admin';
  }
}
