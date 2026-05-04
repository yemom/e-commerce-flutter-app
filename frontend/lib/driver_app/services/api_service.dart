import 'dart:convert';

import 'package:http/http.dart' as http;

class ApiService {
  ApiService({required this.baseUrl, required this.getToken});

  final String baseUrl;
  final Future<String?> Function() getToken;

  // ── Auth ─────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> registerDriver(Map<String, dynamic> body) async {
    return await _post('auth/register', body);
  }

  /// Driver login → POST /api/auth/driver
  Future<Map<String, dynamic>> loginDriver(Map<String, dynamic> body) async {
    return await _post('auth/driver', body);
  }

  /// User/client login → POST /api/auth/user
  Future<Map<String, dynamic>> loginUser(Map<String, dynamic> body) async {
    return await _post('auth/user', body);
  }

  /// Admin login → POST /api/auth/admin
  Future<Map<String, dynamic>> loginAdmin(Map<String, dynamic> body) async {
    return await _post('auth/admin', body);
  }

  // ── Orders ────────────────────────────────────────────────────────────────

  Future<List<dynamic>> getAssignedOrders() async {
    final token = await getToken();
    final res = await http.get(
      Uri.parse('$baseUrl/drivers/me/orders'),
      headers: _authHeaders(token),
    );
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return jsonDecode(res.body) as List<dynamic>;
    }
    throw Exception('API error ${res.statusCode}: ${res.body}');
  }

  Future<Map<String, dynamic>> updateOrderStatus(
    String orderId,
    Map<String, dynamic> body,
  ) async {
    final token = await getToken();
    final res = await http.post(
      Uri.parse('$baseUrl/orders/$orderId/delivery-status'),
      headers: _authHeaders(token, includeJson: true),
      body: jsonEncode(body),
    );
    return _parse(res);
  }

  // ── Profile ───────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> getDriverProfile() async {
    final token = await getToken();
    final res = await http.get(
      Uri.parse('$baseUrl/drivers/me/profile'),
      headers: _authHeaders(token),
    );
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    }
    throw Exception('API error ${res.statusCode}: ${res.body}');
  }

  Future<Map<String, dynamic>> updateDriverProfile(
    Map<String, dynamic> body,
  ) async {
    final token = await getToken();
    final res = await http.patch(
      Uri.parse('$baseUrl/drivers/me/profile'),
      headers: _authHeaders(token, includeJson: true),
      body: jsonEncode(body),
    );
    return _parse(res);
  }

  /// Driver reports current location → POST /api/drivers/me/location
  Future<Map<String, dynamic>> updateDriverLocation(Map<String, dynamic> body) async {
    final token = await getToken();
    final res = await http.post(
      Uri.parse('$baseUrl/drivers/me/location'),
      headers: _authHeaders(token, includeJson: true),
      body: jsonEncode(body),
    );
    return _parse(res);
  }

  // ── Admin ─────────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> fetchAdminProfile() async {
    final token = await getToken();
    final res = await http.get(
      Uri.parse('$baseUrl/auth/me'),
      headers: _authHeaders(token),
    );
    return _parse(res);
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> _post(
    String relativePath,
    Map<String, dynamic> body,
  ) async {
    final normalizedPath = relativePath.startsWith('/')
        ? relativePath.substring(1)
        : relativePath;
    final sep = baseUrl.endsWith('/') ? '' : '/';
    final url = Uri.parse('$baseUrl$sep$normalizedPath');
    final res = await http.post(
      url,
      headers: _jsonHeaders(),
      body: jsonEncode(body),
    );
    return _parse(res);
  }

  Map<String, String> _jsonHeaders() => const {
    'Content-Type': 'application/json',
  };

  Map<String, String> _authHeaders(String? token, {bool includeJson = false}) {
    final headers = <String, String>{};
    if (token != null && token.trim().isNotEmpty) {
      headers['Authorization'] = 'Bearer $token';
    }
    if (includeJson) {
      headers.addAll(_jsonHeaders());
    }
    return headers;
  }

  Map<String, dynamic> _parse(http.Response res) {
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return jsonDecode(res.body) as Map<String, dynamic>;
    }
    throw Exception('API error ${res.statusCode}: ${res.body}');
  }
}
