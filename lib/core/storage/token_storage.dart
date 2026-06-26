import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'key_value_store.dart';

/// Securely persists the JWT access + refresh tokens (OS keystore/keychain in prod).
class TokenStorage {
  TokenStorage(this._store);

  final KeyValueStore _store;

  static const _kAccess = 'ls45.accessToken';
  static const _kRefresh = 'ls45.refreshToken';
  static const _kUser = 'ls45.user';

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await _store.write(_kAccess, accessToken);
    await _store.write(_kRefresh, refreshToken);
  }

  /// Persists tokens plus the raw user JSON so the session can be restored on app restart.
  Future<void> saveSession({
    required String accessToken,
    required String refreshToken,
    required String userJson,
  }) async {
    await saveTokens(accessToken: accessToken, refreshToken: refreshToken);
    await _store.write(_kUser, userJson);
  }

  Future<String?> readAccessToken() => _store.read(_kAccess);

  Future<String?> readRefreshToken() => _store.read(_kRefresh);

  /// The raw user JSON saved at login, or null when there is no session.
  Future<String?> readUserJson() => _store.read(_kUser);

  Future<void> clear() async {
    await _store.delete(_kAccess);
    await _store.delete(_kRefresh);
    await _store.delete(_kUser);
  }

  Future<bool> hasSession() async {
    final token = await readAccessToken();
    return token != null && token.isNotEmpty;
  }
}

final keyValueStoreProvider =
    Provider<KeyValueStore>((ref) => SecureKeyValueStore());

final tokenStorageProvider =
    Provider<TokenStorage>((ref) => TokenStorage(ref.watch(keyValueStoreProvider)));
