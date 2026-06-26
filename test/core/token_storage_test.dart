import 'package:flutter_test/flutter_test.dart';
import 'package:ls45_mobile/core/storage/key_value_store.dart';
import 'package:ls45_mobile/core/storage/token_storage.dart';

class InMemoryKeyValueStore implements KeyValueStore {
  final Map<String, String> _map = {};

  @override
  Future<String?> read(String key) async => _map[key];

  @override
  Future<void> write(String key, String value) async => _map[key] = value;

  @override
  Future<void> delete(String key) async => _map.remove(key);
}

void main() {
  late TokenStorage storage;

  setUp(() => storage = TokenStorage(InMemoryKeyValueStore()));

  test('saves and reads access + refresh tokens', () async {
    await storage.saveTokens(accessToken: 'a1', refreshToken: 'r1');

    expect(await storage.readAccessToken(), 'a1');
    expect(await storage.readRefreshToken(), 'r1');
    expect(await storage.hasSession(), isTrue);
  });

  test('clear removes both tokens and ends the session', () async {
    await storage.saveTokens(accessToken: 'a1', refreshToken: 'r1');

    await storage.clear();

    expect(await storage.readAccessToken(), isNull);
    expect(await storage.readRefreshToken(), isNull);
    expect(await storage.hasSession(), isFalse);
  });

  test('no session when nothing is stored', () async {
    expect(await storage.hasSession(), isFalse);
  });
}
