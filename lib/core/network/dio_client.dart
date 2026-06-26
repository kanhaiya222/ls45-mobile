import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../config/app_config.dart';
import '../storage/token_storage.dart';
import 'auth_interceptor.dart';

BaseOptions _baseOptions() => BaseOptions(
      baseUrl: AppConfig.apiBaseUrl,
      connectTimeout: const Duration(seconds: 15),
      receiveTimeout: const Duration(seconds: 20),
      contentType: Headers.jsonContentType,
      responseType: ResponseType.json,
    );

/// Bare client (no auth interceptor). Used by [AuthInterceptor] for the /auth/refresh call and the
/// replayed request, so refresh never recurses through the auth interceptor.
Dio buildBareDio() => Dio(_baseOptions());

/// Authenticated client: attaches the Bearer token and rotates it on 401.
Dio buildDio(TokenStorage tokens, {Dio? bare}) {
  final dio = Dio(_baseOptions());
  dio.interceptors.add(
    AuthInterceptor(tokens: tokens, bareDio: bare ?? buildBareDio()),
  );
  return dio;
}

final bareDioProvider = Provider<Dio>((ref) => buildBareDio());

/// The app-wide authenticated HTTP client. Feature data sources (M.3+) depend on this.
final dioProvider = Provider<Dio>(
  (ref) => buildDio(ref.watch(tokenStorageProvider), bare: ref.watch(bareDioProvider)),
);
