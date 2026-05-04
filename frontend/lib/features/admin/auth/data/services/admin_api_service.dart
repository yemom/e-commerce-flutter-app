import 'package:e_commerce_app_with_django/driver_app/services/api_service.dart';

class AdminApiService extends ApiService {
  AdminApiService({required super.baseUrl, required super.getToken});

  Future<Map<String, dynamic>> login(String identifier, String password) async {
    return await loginAdmin({
      'identifier': identifier,
      'password': password,
    });
  }
}