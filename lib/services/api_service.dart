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
    final encodedBody = body == null ? null : jsonEncode(body);
    var headers = await _buildHeaders(authenticated: authenticated);

    late http.Response response;
    try {
      response = await _sendRequest(
        method,
        uri,
        headers: headers,
        encodedBody: encodedBody,
      );

      if (authenticated &&
          (response.statusCode == 401 || response.statusCode == 403)) {
        final refreshed = await _refreshAuthToken();
        if (refreshed) {
          headers = await _buildHeaders(authenticated: authenticated);
          response = await _sendRequest(
            method,
            uri,
            headers: headers,
            encodedBody: encodedBody,
          );
        }
      }
    } on ApiException {
      rethrow;
    } catch (error) {
      throw ApiException(
        'No se pudo conectar al API en ${AppEnv.apiBaseUrl}. Verifica la URL en .env y que el backend esté encendido.',
      );
    }

    final decoded = _decodeBody(response.body);
    final message = _extractMessage(decoded);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      if (response.statusCode == 401 || response.statusCode == 403) {
        await _clearAuthSession();
      }
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

  Future<http.Response> _sendRequest(
    String method,
    Uri uri, {
    required Map<String, String> headers,
    required String? encodedBody,
  }) async {
    switch (method) {
      case 'GET':
        return _client.get(uri, headers: headers).timeout(AppEnv.timeout);
      case 'POST':
        return _client
            .post(uri, headers: headers, body: encodedBody)
            .timeout(AppEnv.timeout);
      case 'PUT':
        return _client
            .put(uri, headers: headers, body: encodedBody)
            .timeout(AppEnv.timeout);
      case 'PATCH':
        return _client
            .patch(uri, headers: headers, body: encodedBody)
            .timeout(AppEnv.timeout);
      case 'DELETE':
        return _client
            .delete(uri, headers: headers, body: encodedBody)
            .timeout(AppEnv.timeout);
      default:
        throw ApiException('Unsupported HTTP method: $method');
    }
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

  Future<void> _clearAuthSession() async {
    await _storage.delete(key: StorageKeys.authToken);
    await _storage.delete(key: StorageKeys.refreshToken);
    await _storage.delete(key: StorageKeys.userId);
    await _storage.delete(key: StorageKeys.userName);
    await _storage.delete(key: StorageKeys.userEmail);
    await _storage.delete(key: StorageKeys.userCurrency);
  }

  Future<bool> _refreshAuthToken() async {
    final refreshToken = await _storage.read(key: StorageKeys.refreshToken);
    if (refreshToken == null || refreshToken.isEmpty) {
      await _clearAuthSession();
      return false;
    }

    final headers = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };
    final apiKey = AppEnv.apiKey;
    if (apiKey != null) {
      headers['x-api-key'] = apiKey;
    }

    try {
      final response = await _sendRequest(
        'POST',
        AppEnv.uri(ApiPaths.authRefresh),
        headers: headers,
        encodedBody: jsonEncode({'refreshToken': refreshToken}),
      );

      if (response.statusCode < 200 || response.statusCode >= 300) {
        await _clearAuthSession();
        return false;
      }

      final decoded = _decodeBody(response.body);
      final payload = _unwrapPayload(decoded);
      if (payload is! Map<String, dynamic>) {
        await _clearAuthSession();
        return false;
      }

      final accessToken = payload['accessToken']?.toString();
      final nextRefreshToken =
          payload['refreshToken']?.toString() ??
          payload['refresh_token']?.toString() ??
          refreshToken;

      if (accessToken == null || accessToken.isEmpty) {
        await _clearAuthSession();
        return false;
      }

      await _storage.write(key: StorageKeys.authToken, value: accessToken);
      await _storage.write(
        key: StorageKeys.refreshToken,
        value: nextRefreshToken,
      );
      return true;
    } catch (_) {
      await _clearAuthSession();
      return false;
    }
  }
}
