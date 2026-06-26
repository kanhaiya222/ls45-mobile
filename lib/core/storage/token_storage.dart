import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'key_value_store.dart';

/// Securely persists the JWT access + refresh tokens (OS keystore/keychain in prod).
class TokenStorage {
  TokenStorage(this._store);

  final KeyValueStore _store;

  static const _kAccess = 'ls45.accessToken';
  static const _kRefresh = 'ls45.refreshToken';

  Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    await _store.write(_kAccess, accessToken);
    await _store.write(_kRefresh, refreshToken);
  }

  Future<String?> readAccessToken() => _store.read(_kAccess);

  Future<String?> readRefreshToken() => _store.read(_kRefresh);

  Future<void> clear() async {
    await _store.delete(_kAccess);
    await _store.delete(_kRefresh);
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
