import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/app_config.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/storage/token_storage.dart';
import '../models/auth_models.dart';

/// Auth API + session persistence. Methods throw [ApiException] on failure.
abstract interface class AuthRepository {
  Future<AuthUser> login(String email, String password);

  Future<AuthUser> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    String? phoneNumber,
  });

  Future<void> logout();

  /// Restores a persisted session (token + user) on app start, or null when there is none.
  Future<AuthUser?> restoreSession();
}

class HttpAuthRepository implements AuthRepository {
  HttpAuthRepository(this._dio, this._tokens);

  final Dio _dio;
  final TokenStorage _tokens;

  @override
  Future<AuthUser> login(String email, String password) => _authenticate('/auth/login', {
        'email': email,
        'password': password,
        'deviceType': AppConfig.deviceType,
      });

  @override
  Future<AuthUser> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    String? phoneNumber,
  }) =>
      _authenticate('/auth/register', {
        'email': email,
        'password': password,
        'firstName': firstName,
        'lastName': lastName,
        if (phoneNumber != null && phoneNumber.isNotEmpty) 'phoneNumber': phoneNumber,
      });

  Future<AuthUser> _authenticate(String path, Map<String, dynamic> body) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(path, data: body);
      final data = (res.data!['data'] as Map).cast<String, dynamic>();
      final auth = AuthResponse.fromJson(data);
      await _tokens.saveSession(
        accessToken: auth.accessToken,
        refreshToken: auth.refreshToken,
        userJson: jsonEncode(data['user']),
      );
      return auth.user;
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  @override
  Future<void> logout() async {
    final refresh = await _tokens.readRefreshToken();
    try {
      if (refresh != null && refresh.isNotEmpty) {
        // The backend logout revokes the REFRESH token carried in the Authorization header.
        await _dio.post<void>(
          '/auth/logout',
          options: Options(headers: {'Authorization': 'Bearer $refresh'}),
        );
      }
    } on DioException {
      // Best-effort server revocation; always clear locally.
    } finally {
      await _tokens.clear();
    }
  }

  @override
  Future<AuthUser?> restoreSession() async {
    final token = await _tokens.readAccessToken();
    final userJson = await _tokens.readUserJson();
    if (token == null || token.isEmpty || userJson == null) return null;
    try {
      return AuthUser.fromJson((jsonDecode(userJson) as Map).cast<String, dynamic>());
    } catch (_) {
      await _tokens.clear();
      return null;
    }
  }
}

final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => HttpAuthRepository(ref.watch(dioProvider), ref.watch(tokenStorageProvider)),
);
