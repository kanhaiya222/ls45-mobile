import 'package:dio/dio.dart';

import '../storage/token_storage.dart';

/// Auth endpoints that must NOT carry a Bearer token, and must not trigger refresh-on-401.
const List<String> publicAuthPaths = <String>[
  '/auth/login',
  '/auth/register',
  '/auth/refresh',
];

bool isPublicAuthPath(String path) => publicAuthPaths.any(path.contains);

/// Pure helper: the Authorization header value for [path], or null when none should be sent
/// (no token, or a public auth endpoint). Unit-tested in isolation.
String? bearerFor(String path, String? accessToken) {
  if (accessToken == null || accessToken.isEmpty) return null;
  if (isPublicAuthPath(path)) return null;
  return 'Bearer $accessToken';
}

/// Attaches the access token to outgoing requests, and on a 401 transparently rotates the refresh
/// token once (via [bareDio], which has no interceptor — avoiding recursion) and replays the request.
class AuthInterceptor extends Interceptor {
  AuthInterceptor({required this.tokens, required this.bareDio});

  final TokenStorage tokens;
  final Dio bareDio;

  static const _retriedFlag = '__ls45_retried__';

  @override
  Future<void> onRequest(
    RequestOptions options,
    RequestInterceptorHandler handler,
  ) async {
    final header = bearerFor(options.path, await tokens.readAccessToken());
    if (header != null) {
      options.headers['Authorization'] = header;
    }
    handler.next(options);
  }

  @override
  Future<void> onError(DioException err, ErrorInterceptorHandler handler) async {
    final isUnauthorized = err.response?.statusCode == 401;
    final alreadyRetried = err.requestOptions.extra[_retriedFlag] == true;

    if (!isUnauthorized || alreadyRetried || isPublicAuthPath(err.requestOptions.path)) {
      return handler.next(err);
    }

    final refreshToken = await tokens.readRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) {
      await tokens.clear();
      return handler.next(err);
    }

    try {
      final res = await bareDio.post<Map<String, dynamic>>(
        '/auth/refresh',
        data: {'refreshToken': refreshToken},
      );
      final data = (res.data?['data'] as Map).cast<String, dynamic>();
      final newAccess = data['accessToken'] as String;
      await tokens.saveTokens(
        accessToken: newAccess,
        refreshToken: data['refreshToken'] as String,
      );

      final options = err.requestOptions
        ..headers['Authorization'] = 'Bearer $newAccess'
        ..extra[_retriedFlag] = true;
      final replayed = await bareDio.fetch<dynamic>(options);
      return handler.resolve(replayed);
    } catch (_) {
      await tokens.clear();
      return handler.next(err);
    }
  }
}
