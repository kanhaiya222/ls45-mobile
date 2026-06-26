import '../../../core/json/json_utils.dart';

/// Mirrors the UserDto inside AuthResponse.
class AuthUser {
  const AuthUser({
    required this.publicId,
    required this.email,
    required this.firstName,
    required this.lastName,
    this.status,
    this.roles = const [],
    this.lastLoginAt,
  });

  final String publicId;
  final String email;
  final String firstName;
  final String lastName;
  final String? status;
  final List<String> roles;
  final String? lastLoginAt;

  String get fullName => '$firstName $lastName'.trim();

  factory AuthUser.fromJson(Map<String, dynamic> json) => AuthUser(
        publicId: asString(json['publicId']),
        email: asString(json['email']),
        firstName: asString(json['firstName']),
        lastName: asString(json['lastName']),
        status: asStringOrNull(json['status']),
        roles: asStringListOrNull(json['roles']) ?? const [],
        lastLoginAt: asStringOrNull(json['lastLoginAt']),
      );
}

/// Mirrors AuthResponse (data of POST /api/v1/auth/login | /register | /refresh).
class AuthResponse {
  const AuthResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.tokenType,
    required this.expiresIn,
    required this.user,
  });

  final String accessToken;
  final String refreshToken;
  final String tokenType;
  final int expiresIn;
  final AuthUser user;

  factory AuthResponse.fromJson(Map<String, dynamic> json) => AuthResponse(
        accessToken: asString(json['accessToken']),
        refreshToken: asString(json['refreshToken']),
        tokenType: asString(json['tokenType'], 'Bearer'),
        expiresIn: asInt(json['expiresIn']),
        user: AuthUser.fromJson((json['user'] as Map).cast<String, dynamic>()),
      );
}
