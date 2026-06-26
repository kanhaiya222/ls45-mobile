import '../../../core/json/json_utils.dart';

/// Mirrors TravellerResponse (GET/POST /api/v1/me/travellers).
class Traveller {
  const Traveller({
    required this.publicId,
    required this.firstName,
    required this.lastName,
    this.email,
    this.phone,
    this.dateOfBirth,
    this.gender,
    this.nationality,
  });

  final String publicId;
  final String firstName;
  final String lastName;
  final String? email;
  final String? phone;
  final String? dateOfBirth;
  final String? gender;
  final String? nationality;

  String get fullName => '$firstName $lastName'.trim();

  factory Traveller.fromJson(Map<String, dynamic> json) => Traveller(
        publicId: asString(json['publicId']),
        firstName: asString(json['firstName']),
        lastName: asString(json['lastName']),
        email: asStringOrNull(json['email']),
        phone: asStringOrNull(json['phone']),
        dateOfBirth: asStringOrNull(json['dateOfBirth']),
        gender: asStringOrNull(json['gender']),
        nationality: asStringOrNull(json['nationality']),
      );
}
