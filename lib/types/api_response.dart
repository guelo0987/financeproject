import 'api_exception.dart';

class ApiResponse<T> {
  const ApiResponse({
    required this.statusCode,
    required this.success,
    this.data,
    this.message,
    this.meta,
  });

  final int statusCode;
  final bool success;
  final T? data;
  final String? message;
  final Map<String, dynamic>? meta;

  T requireData([String fallbackMessage = 'Missing response data']) {
    final value = data;
    if (value == null) {
      throw ApiException(message ?? fallbackMessage, statusCode: statusCode);
    }
    return value;
  }
}
