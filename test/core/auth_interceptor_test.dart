import 'package:flutter_test/flutter_test.dart';
import 'package:ls45_mobile/core/network/auth_interceptor.dart';

void main() {
  test('bearerFor attaches the token for protected paths', () {
    expect(bearerFor('/packages', 'tok'), 'Bearer tok');
    expect(bearerFor('/account/bookings', 'tok'), 'Bearer tok');
  });

  test('bearerFor returns null for public auth paths (incl. logout)', () {
    expect(bearerFor('/auth/login', 'tok'), isNull);
    expect(bearerFor('/auth/register', 'tok'), isNull);
    expect(bearerFor('/auth/refresh', 'tok'), isNull);
    expect(bearerFor('/auth/logout', 'tok'), isNull);
  });

  test('bearerFor returns null when there is no token', () {
    expect(bearerFor('/packages', null), isNull);
    expect(bearerFor('/packages', ''), isNull);
  });

  test('isPublicAuthPath recognises auth endpoints only', () {
    expect(isPublicAuthPath('/api/v1/auth/login'), isTrue);
    expect(isPublicAuthPath('/api/v1/auth/refresh'), isTrue);
    expect(isPublicAuthPath('/api/v1/packages'), isFalse);
  });
}
