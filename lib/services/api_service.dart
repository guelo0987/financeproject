import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;

import '../types/types.dart';
import '../utils/utils.dart';

final apiServiceProvider = Provider<ApiService>((ref) {
  final service = ApiService();
  ref.onDispose(service.dispose);
  return service;
});

class ApiService {
  ApiService({http.Client? client, FlutterSecureStorage? storage})
    : _client = client ?? http.Client(),
      _storage = storage ?? const FlutterSecureStorage();

  final http.Client _client;
  final FlutterSecureStorage _storage;

  Future<ApiResponse<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    bool authenticated = true,
    T Function(Object? payload)? parser,
  }) {
    return _request<T>(
      'GET',
      path,
      queryParameters: queryParameters,
      authenticated: authenticated,
      parser: parser,
    );
  }

  Future<ApiResponse<T>> post<T>(
    String path, {
    Object? body,
    Map<String, dynamic>? queryParameters,
    bool authenticated = true,
    T Function(Object? payload)? parser,
  }) {
    return _request<T>(
      'POST',
      path,
      body: body,
      queryParameters: queryParameters,
      authenticated: authenticated,
      parser: parser,
    );
  }

  Future<ApiResponse<T>> put<T>(
    String path, {
    Object? body,
    Map<String, dynamic>? queryParameters,
    bool authenticated = true,
    T Function(Object? payload)? parser,
  }) {
    return _request<T>(
      'PUT',
      path,
      body: body,
      queryParameters: queryParameters,
      authenticated: authenticated,
      parser: parser,
    );
  }

  Future<ApiResponse<T>> patch<T>(
    String path, {
    Object? body,
    Map<String, dynamic>? queryParameters,
    bool authenticated = true,
    T Function(Object? payload)? parser,
  }) {
    return _request<T>(
      'PATCH',
      path,
      body: body,
      queryParameters: queryParameters,
      authenticated: authenticated,
      parser: parser,
    );
  }

  Future<ApiResponse<T>> delete<T>(
    String path, {
    Object? body,
    Map<String, dynamic>? queryParameters,
    bool authenticated = true,
    T Function(Object? payload)? parser,
  }) {
    return _request<T>(
      'DELETE',
      path,
      body: body,
      queryParameters: queryParameters,
      authenticated: authenticated,
      parser: parser,
    );
  }

  Future<ApiResponse<T>> _request<T>(
    String method,
    String path, {
    Object? body,
    Map<String, dynamic>? queryParameters,
    required bool authenticated,
    T Function(Object? payload)? parser,
  }) async {
    final uri = AppEnv.uri(path, queryParameters: queryParameters);
    final headers = await _buildHeaders(authenticated: authenticated);
    final encodedBody = body == null ? null : jsonEncode(body);

    late final http.Response response;
    try {
      switch (method) {
        case 'GET':
          response = await _client
              .get(uri, headers: headers)
              .timeout(AppEnv.timeout);
          break;
        case 'POST':
          response = await _client
              .post(uri, headers: headers, body: encodedBody)
              .timeout(AppEnv.timeout);
          break;
        case 'PUT':
          response = await _client
              .put(uri, headers: headers, body: encodedBody)
              .timeout(AppEnv.timeout);
          break;
        case 'PATCH':
          response = await _client
              .patch(uri, headers: headers, body: encodedBody)
              .timeout(AppEnv.timeout);
          break;
        case 'DELETE':
          response = await _client
              .delete(uri, headers: headers, body: encodedBody)
              .timeout(AppEnv.timeout);
          break;
        default:
          throw ApiException('Unsupported HTTP method: $method');
      }
    } on ApiException {
      rethrow;
    } catch (error) {
      throw ApiException(error.toString());
    }

    final decoded = _decodeBody(response.body);
    final message = _extractMessage(decoded);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(
        message ?? 'Request failed',
        statusCode: response.statusCode,
      );
    }

    final payload = _unwrapPayload(decoded);
    T? typedData;
    if (payload != null) {
      typedData = parser != null ? parser(payload) : payload as T;
    }

    final meta = decoded is Map<String, dynamic> && decoded['meta'] is Map
        ? asJsonMap(decoded['meta'])
        : null;

    return ApiResponse<T>(
      statusCode: response.statusCode,
      success: true,
      data: typedData,
      message: message,
      meta: meta,
    );
  }

  Future<Map<String, String>> _buildHeaders({
    required bool authenticated,
  }) async {
    final headers = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };

    final apiKey = AppEnv.apiKey;
    if (apiKey != null) {
      headers['x-api-key'] = apiKey;
    }

    if (authenticated) {
      final token = await _storage.read(key: StorageKeys.authToken);
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    return headers;
  }

  Object? _decodeBody(String rawBody) {
    if (rawBody.trim().isEmpty) return null;
    return jsonDecode(rawBody);
  }

  Object? _unwrapPayload(Object? decoded) {
    if (decoded is Map<String, dynamic> && decoded.containsKey('data')) {
      return decoded['data'];
    }
    return decoded;
  }

  String? _extractMessage(Object? decoded) {
    if (decoded is! Map<String, dynamic>) return null;

    final directMessage = decoded['message'];
    if (directMessage is String && directMessage.isNotEmpty) {
      return directMessage;
    }

    final data = decoded['data'];
    if (data is Map<String, dynamic>) {
      final nestedMessage = data['mensaje'] ?? data['message'];
      if (nestedMessage is String && nestedMessage.isNotEmpty) {
        return nestedMessage;
      }
    }

    final error = decoded['error'];
    if (error is Map<String, dynamic>) {
      final errorMessage = error['mensaje'] ?? error['message'];
      if (errorMessage is String && errorMessage.isNotEmpty) {
        return errorMessage;
      }
    }

    return null;
  }

  void dispose() {
    _client.close();
  }
}
