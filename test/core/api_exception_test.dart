import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ls45_mobile/core/network/api_exception.dart';

void main() {
  test('parses errorCode + message from the backend ErrorResponse body', () {
    final err = DioException(
      requestOptions: RequestOptions(path: '/packages'),
      type: DioExceptionType.badResponse,
      response: Response(
        requestOptions: RequestOptions(path: '/packages'),
        statusCode: 400,
        data: {'success': false, 'errorCode': 'VALIDATION', 'message': 'Bad input'},
      ),
    );

    final ex = ApiException.fromDio(err);

    expect(ex.statusCode, 400);
    expect(ex.errorCode, 'VALIDATION');
    expect(ex.message, 'Bad input');
    expect(ex.isUnauthorized, isFalse);
  });

  test('maps a connection timeout to NETWORK_ERROR', () {
    final err = DioException(
      requestOptions: RequestOptions(path: '/x'),
      type: DioExceptionType.connectionTimeout,
    );

    expect(ApiException.fromDio(err).errorCode, 'NETWORK_ERROR');
  });

  test('flags 401 responses as unauthorized', () {
    final err = DioException(
      requestOptions: RequestOptions(path: '/account'),
      type: DioExceptionType.badResponse,
      response: Response(
        requestOptions: RequestOptions(path: '/account'),
        statusCode: 401,
        data: {'message': 'Authentication required'},
      ),
    );

    expect(ApiException.fromDio(err).isUnauthorized, isTrue);
  });
}
