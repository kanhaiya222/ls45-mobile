import 'package:flutter_test/flutter_test.dart';
import 'package:ls45_mobile/features/auth/models/auth_models.dart';

void main() {
  test('AuthResponse.fromJson parses tokens + nested user + roles', () {
    final auth = AuthResponse.fromJson({
      'accessToken': 'access-123',
      'refreshToken': 'refresh-456',
      'tokenType': 'Bearer',
      'expiresIn': 3600,
      'user': {
        'publicId': 'user-1',
        'email': 'admin@ls45.io',
        'firstName': 'Admin',
        'lastName': 'User',
        'status': 'ACTIVE',
        'roles': ['TENANT_ADMIN', 'CUSTOMER'],
      },
    });

    expect(auth.accessToken, 'access-123');
    expect(auth.refreshToken, 'refresh-456');
    expect(auth.expiresIn, 3600);
    expect(auth.user.fullName, 'Admin User');
    expect(auth.user.roles, contains('TENANT_ADMIN'));
  });

  test('AuthUser defaults roles to empty when absent', () {
    final user = AuthUser.fromJson({
      'publicId': 'u2',
      'email': 'c@ls45.io',
      'firstName': 'Demo',
      'lastName': 'Customer',
    });
    expect(user.roles, isEmpty);
    expect(user.status, isNull);
  });
}
