import 'dart:convert';
import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';

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

  SupabaseClient? get _supabaseOrNull {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

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
      response = await _sendWithSilentRetry(
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
          response = await _sendWithSilentRetry(
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
      debugPrint('[api] transport error $method $uri -> $error');
      throw ApiException(
        'No pudimos conectarnos en este momento. Revisa tu conexión e inténtalo otra vez.',
      );
    }

    final decoded = _decodeBody(response.body);
    final message = _extractMessage(decoded);

    if (response.statusCode < 200 || response.statusCode >= 300) {
      if (response.statusCode == 401 || response.statusCode == 403) {
        await _clearAuthSession();
      }
      throw ApiException(
        message ?? 'No pudimos completar la solicitud en este momento.',
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

    if (authenticated) {
      final token =
          _supabaseOrNull?.auth.currentSession?.accessToken ??
          await _storage.read(key: StorageKeys.authToken);
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
        throw ApiException('No se pudo completar la solicitud.');
    }
  }

  Future<http.Response> _sendWithSilentRetry(
    String method,
    Uri uri, {
    required Map<String, String> headers,
    required String? encodedBody,
  }) async {
    final canRetry = method == 'GET';

    try {
      final response = await _sendRequest(
        method,
        uri,
        headers: headers,
        encodedBody: encodedBody,
      );
      if (!canRetry || !_isTransientStatus(response.statusCode)) {
        return response;
      }

      await Future<void>.delayed(const Duration(milliseconds: 260));
      return _sendRequest(
        method,
        uri,
        headers: headers,
        encodedBody: encodedBody,
      );
    } catch (error) {
      if (!canRetry || !_isTransientTransportError(error)) rethrow;
      await Future<void>.delayed(const Duration(milliseconds: 260));
      return _sendRequest(
        method,
        uri,
        headers: headers,
        encodedBody: encodedBody,
      );
    }
  }

  bool _isTransientStatus(int statusCode) {
    return statusCode == 408 || statusCode == 429 || statusCode >= 500;
  }

  bool _isTransientTransportError(Object error) {
    if (error is TimeoutException || error is http.ClientException) {
      return true;
    }
    final lower = error.toString().toLowerCase();
    return lower.contains('socketexception') ||
        lower.contains('connection closed') ||
        lower.contains('connection reset');
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
    try {
      await _supabaseOrNull?.auth.signOut();
    } catch (_) {
      // Local cleanup below is enough to reset the app session.
    }

    await _storage.delete(key: StorageKeys.authToken);
    await _storage.delete(key: StorageKeys.refreshToken);
    await _storage.delete(key: StorageKeys.userId);
    await _storage.delete(key: StorageKeys.userName);
    await _storage.delete(key: StorageKeys.userEmail);
    await _storage.delete(key: StorageKeys.userCurrency);
    await _storage.delete(key: StorageKeys.userDefaultBudgetId);
    await _storage.delete(key: StorageKeys.userFinancialGoal);
    await _storage.delete(key: StorageKeys.userGoalAmount);
    await _storage.delete(key: StorageKeys.userGoalDate);
    await _storage.delete(key: StorageKeys.userCreatedAt);
  }

  Future<bool> _refreshAuthToken() async {
    try {
      final supabase = _supabaseOrNull;
      final currentSession = supabase?.auth.currentSession;
      if (currentSession == null) {
        await _clearAuthSession();
        return false;
      }

      final response = await supabase!.auth.refreshSession();
      final session = response.session ?? supabase.auth.currentSession;
      if (session == null) {
        await _clearAuthSession();
        return false;
      }

      await _storage.write(
        key: StorageKeys.authToken,
        value: session.accessToken,
      );
      if (session.refreshToken != null && session.refreshToken!.isNotEmpty) {
        await _storage.write(
          key: StorageKeys.refreshToken,
          value: session.refreshToken,
        );
      } else {
        await _storage.delete(key: StorageKeys.refreshToken);
      }

      return true;
    } catch (_) {
      await _clearAuthSession();
      return false;
    }
  }
}
