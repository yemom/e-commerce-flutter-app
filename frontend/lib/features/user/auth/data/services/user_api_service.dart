import 'package:e_commerce_app_with_django/driver_app/services/api_service.dart';

class UserApiService extends ApiService {
  UserApiService({required super.baseUrl, required super.getToken});

  Future<Map<String, dynamic>> login(String identifier, String password) async {
    return await loginUser({
      'identifier': identifier,
      'password': password,
    });
  }
}