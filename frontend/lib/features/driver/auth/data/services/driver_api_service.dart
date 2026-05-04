import 'package:e_commerce_app_with_django/driver_app/services/api_service.dart';

class DriverApiService extends ApiService {
  DriverApiService({required super.baseUrl, required super.getToken});

  Future<Map<String, dynamic>> login(String identifier, String password) async {
    return await loginDriver({
      'identifier': identifier,
      'password': password,
    });
  }
}