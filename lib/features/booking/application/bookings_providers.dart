import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/booking_repository.dart';
import '../models/booking_models.dart';

/// The signed-in user's bookings (first page).
final myBookingsProvider = FutureProvider.autoDispose<List<Booking>>((ref) async {
  final page = await ref.watch(bookingRepositoryProvider).listMine();
  return page.content;
});

/// A single booking by public id.
final bookingDetailProvider = FutureProvider.autoDispose.family<Booking, String>(
  (ref, publicId) => ref.watch(bookingRepositoryProvider).getByPublicId(publicId),
);
