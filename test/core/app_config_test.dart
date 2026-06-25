import 'package:flutter_test/flutter_test.dart';
import 'package:ls45_mobile/core/config/app_config.dart';

void main() {
  test('apiBaseUrl resolves to a non-empty /api/v1 base', () {
    final base = AppConfig.apiBaseUrl;
    expect(base, isNotEmpty);
    expect(base, endsWith('/api/v1'));
    expect(base, startsWith('http'));
  });
}
