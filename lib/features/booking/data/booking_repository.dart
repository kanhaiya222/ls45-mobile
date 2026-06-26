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

  /// Locks and returns the price snapshot for the draft.
  Future<BookingPriceSnapshot> review(String draftPublicId);

  /// Confirms the draft → a reserved booking (PENDING_PAYMENT).
  Future<Booking> confirm(String draftPublicId, String priceSnapshotPublicId);

  /// Starts payment; throws ApiException(errorCode: 'PAYMENT_NOT_CONFIGURED') when payments are off.
  Future<PaymentInitiation> initiatePayment(String bookingPublicId);
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

  @override
  Future<BookingPriceSnapshot> review(String draftPublicId) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>('/booking-drafts/$draftPublicId/review');
      return unwrap(
          res.data, (d) => BookingPriceSnapshot.fromJson((d as Map).cast<String, dynamic>()));
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  @override
  Future<Booking> confirm(String draftPublicId, String priceSnapshotPublicId) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '/booking-drafts/$draftPublicId/confirm',
        data: {'priceSnapshotPublicId': priceSnapshotPublicId},
      );
      return unwrap(res.data, (d) => Booking.fromJson((d as Map).cast<String, dynamic>()));
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }

  @override
  Future<PaymentInitiation> initiatePayment(String bookingPublicId) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        '/bookings/$bookingPublicId/payments/initiate',
      );
      return unwrap(res.data, (d) => PaymentInitiation.fromJson((d as Map).cast<String, dynamic>()));
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}

final bookingRepositoryProvider =
    Provider<BookingRepository>((ref) => HttpBookingRepository(ref.watch(dioProvider)));
