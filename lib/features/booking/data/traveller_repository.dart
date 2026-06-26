import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/api_response.dart';
import '../../../core/network/dio_client.dart';
import '../models/traveller_models.dart';

/// The signed-in user's saved travellers (/api/v1/me/travellers).
abstract interface class TravellerRepository {
  Future<List<Traveller>> listMine();

  Future<Traveller> create({
    required String firstName,
    required String lastName,
    String? email,
    String? phone,
    String? dateOfBirth,
    String? gender,
    String? nationality,
  });
}

class HttpTravellerRepository implements TravellerRepository {
  HttpTravellerRepository(this._dio);

  final Dio _dio;

  @override
  Future<List<Traveller>> listMine() async {
    try {
      final res = await _dio.get<Map<String, dynamic>>('/me/travellers');
      return unwrap(
        res.data,
        (d) => (d as List)
            .whereType<Map>()
            .map((e) => Traveller.fromJson(e.cast<String, dynamic>()))
            .toList(),
      );
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  @override
  Future<Traveller> create({
    required String firstName,
    required String lastName,
    String? email,
    String? phone,
    String? dateOfBirth,
    String? gender,
    String? nationality,
  }) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>('/me/travellers', data: {
        'firstName': firstName,
        'lastName': lastName,
        if (email != null && email.isNotEmpty) 'email': email,
        if (phone != null && phone.isNotEmpty) 'phone': phone,
        if (dateOfBirth != null && dateOfBirth.isNotEmpty) 'dateOfBirth': dateOfBirth,
        if (gender != null && gender.isNotEmpty) 'gender': gender,
        if (nationality != null && nationality.isNotEmpty) 'nationality': nationality,
      });
      return unwrap(res.data, (d) => Traveller.fromJson((d as Map).cast<String, dynamic>()));
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}

final travellerRepositoryProvider =
    Provider<TravellerRepository>((ref) => HttpTravellerRepository(ref.watch(dioProvider)));
