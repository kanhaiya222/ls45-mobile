import 'package:dio/dio.dart';

/// A normalised API error surfaced to the app/UI layer. Maps both the backend `ErrorResponse`
/// body ({ errorCode, message }) and transport failures into one type the UI can render.
class ApiException implements Exception {
  ApiException({
    required this.statusCode,
    required this.message,
    this.errorCode,
  });

  final int? statusCode;
  final String? errorCode;
  final String message;

  bool get isUnauthorized => statusCode == 401;

  factory ApiException.fromDio(DioException e) {
    final status = e.response?.statusCode;
    final data = e.response?.data;

    if (data is Map) {
      final message = data['message'];
      final code = data['errorCode'];
      return ApiException(
        statusCode: status,
        errorCode: code is String && code.isNotEmpty ? code : null,
        message: message is String && message.isNotEmpty
            ? message
            : 'Request failed (${status ?? 'no status'}).',
      );
    }

    switch (e.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.receiveTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.connectionError:
        return ApiException(
          statusCode: status,
          errorCode: 'NETWORK_ERROR',
          message: 'Network unavailable. Check your connection and try again.',
        );
      default:
        return ApiException(
          statusCode: status,
          message: 'Something went wrong. Please try again.',
        );
    }
  }

  @override
  String toString() => 'ApiException($statusCode, $errorCode): $message';
}
