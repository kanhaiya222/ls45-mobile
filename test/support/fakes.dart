import 'package:ls45_mobile/core/network/api_exception.dart';
import 'package:ls45_mobile/core/storage/key_value_store.dart';
import 'package:ls45_mobile/features/auth/data/auth_repository.dart';
import 'package:ls45_mobile/features/auth/models/auth_models.dart';

/// In-memory [KeyValueStore] for tests (no platform channel).
class InMemoryKeyValueStore implements KeyValueStore {
  final Map<String, String> map = {};

  @override
  Future<String?> read(String key) async => map[key];

  @override
  Future<void> write(String key, String value) async => map[key] = value;

  @override
  Future<void> delete(String key) async => map.remove(key);
}

/// Configurable fake [AuthRepository] for controller/widget tests (no Dio/network).
class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({this.session});

  AuthUser? session;
  bool throwOnLogin = false;

  @override
  Future<AuthUser> login(String email, String password) async {
    if (throwOnLogin) {
      throw ApiException(statusCode: 401, message: 'Invalid credentials');
    }
    final user = AuthUser(
      publicId: 'u1',
      email: email,
      firstName: 'Test',
      lastName: 'User',
      roles: const ['CUSTOMER'],
    );
    session = user;
    return user;
  }

  @override
  Future<AuthUser> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    String? phoneNumber,
  }) async {
    final user = AuthUser(
      publicId: 'u2',
      email: email,
      firstName: firstName,
      lastName: lastName,
    );
    session = user;
    return user;
  }

  @override
  Future<void> logout() async {
    session = null;
  }

  @override
  Future<AuthUser?> restoreSession() async => session;
}
