import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/api_response.dart';
import '../../../core/network/dio_client.dart';
import '../models/booking_models.dart';

/// Booking draft lifecycle (the steps before payment).
abstract interface class BookingRepository {
  Future<BookingDraft> createDraft({
    required String departurePublicId,
    required OccupancyType occupancyType,
    required int numTravellers,
  });

  Future<BookingDraft> setTravellers(String draftPublicId, List<String> travellerPublicIds);
}

class HttpBookingRepository implements BookingRepository {
  HttpBookingRepository(this._dio);

  final Dio _dio;

  @override
  Future<BookingDraft> createDraft({
    required String departurePublicId,
    required OccupancyType occupancyType,
    required int numTravellers,
  }) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>('/booking-drafts', data: {
        'departurePublicId': departurePublicId,
        'occupancyType': occupancyType.wire,
        'numTravellers': numTravellers,
      });
      return unwrap(res.data, (d) => BookingDraft.fromJson((d as Map).cast<String, dynamic>()));
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  @override
  Future<BookingDraft> setTravellers(String draftPublicId, List<String> travellerPublicIds) async {
    try {
      final res = await _dio.put<Map<String, dynamic>>(
        '/booking-drafts/$draftPublicId/travellers',
        data: {'travellerPublicIds': travellerPublicIds},
      );
      return unwrap(res.data, (d) => BookingDraft.fromJson((d as Map).cast<String, dynamic>()));
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}

final bookingRepositoryProvider =
    Provider<BookingRepository>((ref) => HttpBookingRepository(ref.watch(dioProvider)));
