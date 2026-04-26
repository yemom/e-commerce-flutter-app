/// Talks to a backend API that can persist data in MongoDB.
library;

import 'dart:convert';
import 'dart:io' show Platform;

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

class CommerceApiException implements Exception {
  const CommerceApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() =>
      'CommerceApiException(statusCode: $statusCode, message: $message)';
}

class CommerceApiDataSource {
  CommerceApiDataSource({required String baseUrl, required http.Client client})
    : _baseUrl = _normalizeBaseUrl(baseUrl.trim()),
      _client = client;

  final String _baseUrl;
  final http.Client _client;

  static String _normalizeBaseUrl(String value) {
    if (value.isEmpty) {
      return value;
    }

    if (kIsWeb) {
      return value;
    }

    final uri = Uri.tryParse(value);
    if (uri == null) {
      return value;
    }

    final host = uri.host.toLowerCase();
    final isLocalHost = host == 'localhost' || host == '127.0.0.1' || host == '::1';

    // Android emulators must call the host machine through 10.0.2.2.
    if (Platform.isAndroid && isLocalHost) {
      return uri.replace(host: '10.0.2.2').toString();
    }

    return value;
  }

  bool get isConfigured => _baseUrl.isNotEmpty;

  Future<List<Map<String, dynamic>>> getCollection(
    String path, {
    Map<String, String?> queryParameters = const <String, String?>{},
    Map<String, String> headers = const <String, String>{},
  }) async {
    final payload = await _send(
      method: 'GET',
      path: path,
      queryParameters: queryParameters,
      headers: headers,
    );
    return _asObjectList(_unwrapListEnvelope(payload));
  }

  Future<Map<String, dynamic>> getItem(
    String path, {
    Map<String, String?> queryParameters = const <String, String?>{},
    Map<String, String> headers = const <String, String>{},
  }) async {
    final payload = await _send(
      method: 'GET',
      path: path,
      queryParameters: queryParameters,
      headers: headers,
    );
    return _asObject(_unwrapObjectEnvelope(payload));
  }

  Future<Map<String, dynamic>> postItem(
    String path, {
    Map<String, dynamic> body = const <String, dynamic>{},
    Map<String, String> headers = const <String, String>{},
  }) async {
    final payload = await _send(
      method: 'POST',
      path: path,
      body: body,
      headers: headers,
    );
    return _asObject(_unwrapObjectEnvelope(payload));
  }

  Future<Map<String, dynamic>> patchItem(
    String path, {
    Map<String, dynamic> body = const <String, dynamic>{},
    Map<String, String> headers = const <String, String>{},
  }) async {
    final payload = await _send(
      method: 'PATCH',
      path: path,
      body: body,
      headers: headers,
    );
    return _asObject(_unwrapObjectEnvelope(payload));
  }

  Future<void> deleteItem(
    String path, {
    Map<String, String> headers = const <String, String>{},
  }) async {
    await _send(method: 'DELETE', path: path, headers: headers);
  }

  Future<String> uploadProductImage({
    required List<int> bytes,
    required String fileName,
    Map<String, String> headers = const <String, String>{},
  }) async {
    if (!isConfigured) {
      throw StateError('APP_API_BASE_URL is not configured.');
    }

    // Upload image as multipart/form-data using the backend endpoint.
    final uri = _buildUri('/uploads/products', const <String, String?>{});
    final request = http.MultipartRequest('POST', uri)
      ..headers.addAll(<String, String>{
        'Accept': 'application/json',
        ...headers,
      })
      ..files.add(
        http.MultipartFile.fromBytes(
          'image',
          bytes,
          filename: fileName.trim().isEmpty ? 'product-image.jpg' : fileName.trim(),
        ),
      );

    final streamed = await _client.send(request);
    final response = await http.Response.fromStream(streamed);
    final payload = _decodeResponse(response);

    // Normalize server-side errors to a friendly typed exception.
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw CommerceApiException(
        _extractMessage(payload) ?? 'Unable to upload product image.',
        statusCode: response.statusCode,
      );
    }

    final object = _asObject(_unwrapObjectEnvelope(payload));
    final imageUrl = object['imageUrl'];
    if (imageUrl is! String || imageUrl.trim().isEmpty) {
      throw const CommerceApiException('Upload succeeded but no imageUrl was returned.');
    }

    return imageUrl.trim();
  }

  Future<dynamic> _send({
    required String method,
    required String path,
    Map<String, String?> queryParameters = const <String, String?>{},
    Map<String, dynamic>? body,
    Map<String, String> headers = const <String, String>{},
  }) async {
    if (!isConfigured) {
      throw StateError('APP_API_BASE_URL is not configured.');
    }

    // Shared request pipeline used by all JSON endpoints.
    final uri = _buildUri(path, queryParameters);
    final response = await _performRequest(
      method: method,
      uri: uri,
      body: body,
      headers: headers,
    );
    final payload = _decodeResponse(response);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw CommerceApiException(
        _extractMessage(payload) ?? 'The server rejected the request.',
        statusCode: response.statusCode,
      );
    }

    return payload;
  }

  Future<http.Response> _performRequest({
    required String method,
    required Uri uri,
    Map<String, dynamic>? body,
    Map<String, String> headers = const <String, String>{},
  }) {
    // Standard headers for all requests. JSON content type is added only when body is present.
    final requestHeaders = <String, String>{
      'Accept': 'application/json',
      ...headers,
    };

    if (body != null) {
      requestHeaders['Content-Type'] = 'application/json';
    }

    switch (method) {
      case 'GET':
        return _client.get(uri, headers: requestHeaders);
      case 'POST':
        return _client.post(
          uri,
          headers: requestHeaders,
          body: jsonEncode(body ?? const <String, dynamic>{}),
        );
      case 'PATCH':
        return _client.patch(
          uri,
          headers: requestHeaders,
          body: jsonEncode(body ?? const <String, dynamic>{}),
        );
      case 'DELETE':
        return _client.delete(uri, headers: requestHeaders);
    }

    throw UnsupportedError('Unsupported HTTP method: $method');
  }

  Uri _buildUri(String path, Map<String, String?> queryParameters) {
    final normalizedPath = path.startsWith('/') ? path : '/$path';
    final baseUri = Uri.parse(_baseUrl);
    // Remove null/empty query params so generated URLs stay clean.
    final cleanQuery = <String, String>{
      for (final entry in queryParameters.entries)
        if (entry.value != null && entry.value!.trim().isNotEmpty)
          entry.key: entry.value!.trim(),
    };

    return baseUri.replace(
      path: _joinPaths(baseUri.path, normalizedPath),
      queryParameters: cleanQuery.isEmpty ? null : cleanQuery,
    );
  }

  String _joinPaths(String left, String right) {
    final normalizedLeft = left.endsWith('/')
        ? left.substring(0, left.length - 1)
        : left;
    final normalizedRight = right.startsWith('/') ? right.substring(1) : right;

    if (normalizedLeft.isEmpty) {
      return '/$normalizedRight';
    }

    return '$normalizedLeft/$normalizedRight';
  }

  dynamic _decodeResponse(http.Response response) {
    // Some endpoints (e.g., DELETE) return empty bodies.
    if (response.body.trim().isEmpty) {
      return null;
    }

    try {
      // Prefer structured JSON, but gracefully fall back to plain text.
      return jsonDecode(response.body);
    } on FormatException {
      return response.body;
    }
  }

  String? _extractMessage(dynamic payload) {
    if (payload is String && payload.trim().isNotEmpty) {
      return payload.trim();
    }

    if (payload is Map<String, dynamic>) {
      for (final key in ['message', 'error', 'detail']) {
        final value = payload[key];
        if (value is String && value.trim().isNotEmpty) {
          return value.trim();
        }
      }
    }

    return null;
  }

  dynamic _unwrapListEnvelope(dynamic payload) {
    if (payload is List<dynamic>) {
      return payload;
    }

    if (payload is Map<String, dynamic>) {
      for (final key in ['data', 'items', 'results']) {
        final value = payload[key];
        if (value is List<dynamic>) {
          return value;
        }
      }
    }

    throw const CommerceApiException(
      'Expected a list response from the server.',
    );
  }

  dynamic _unwrapObjectEnvelope(dynamic payload) {
    if (payload is Map<String, dynamic>) {
      for (final key in ['data', 'item', 'result']) {
        final value = payload[key];
        if (value is Map<String, dynamic>) {
          return value;
        }
      }
      return payload;
    }

    throw const CommerceApiException(
      'Expected an object response from the server.',
    );
  }

  List<Map<String, dynamic>> _asObjectList(dynamic payload) {
    if (payload is! List<dynamic>) {
      throw const CommerceApiException(
        'Expected a list response from the server.',
      );
    }

    return payload.map(_asObject).toList();
  }

  Map<String, dynamic> _asObject(dynamic payload) {
    if (payload is Map<String, dynamic>) {
      return payload;
    }

    if (payload is Map) {
      return payload.map((key, value) => MapEntry(key.toString(), value));
    }

    throw const CommerceApiException('Expected a JSON object from the server.');
  }
}
