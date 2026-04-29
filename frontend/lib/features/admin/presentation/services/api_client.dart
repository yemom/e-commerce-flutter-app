import 'package:http/http.dart';
import 'package:http/http.dart' as http;

// A simple API client that wraps the http package and provides a method for making GET requests. This can be expanded in the future to include POST, PUT, DELETE, etc. as needed.

class ApiClient {
  final Dio dio;

  ApiClient(this.dio);

  Future<Response> get(String path) {
    return dio.get(path);
  }
}

class Dio {
  Dio();

  Future<Response> get(String path) {
    return http.get(Uri.parse(path));
  }
}

