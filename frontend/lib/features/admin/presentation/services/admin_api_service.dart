import 'package:e_commerce_app_with_django/features/admin/presentation/services/api_client.dart';
import 'package:http/src/response.dart';


//display the current admin name in the hero card title if available, otherwise default to "Admin".
class AdminApiService {
  final ApiClient api;

  AdminApiService(this.api);

  Future<String> fetchAdminName() async {
    final response = await api.get('/admin/profile');
    return response.data['name'];
  }
}

extension on Response {
  get data => null;
}