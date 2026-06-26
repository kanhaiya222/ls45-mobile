import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/booking_repository.dart';
import '../data/traveller_repository.dart';
import '../models/booking_models.dart';

/// One traveller's details entered during booking.
class NewTraveller {
  const NewTraveller({required this.firstName, required this.lastName, this.email});

  final String firstName;
  final String lastName;
  final String? email;
}

/// Orchestrates the "start a booking" flow: create the draft, persist each traveller, then attach
/// them to the draft. Kept separate from the UI so it is unit-testable.
class BookingStarter {
  BookingStarter(this._booking, this._travellers);

  final BookingRepository _booking;
  final TravellerRepository _travellers;

  Future<BookingDraft> start({
    required String departurePublicId,
    required OccupancyType occupancy,
    required List<NewTraveller> travellers,
  }) async {
    final draft = await _booking.createDraft(
      departurePublicId: departurePublicId,
      occupancyType: occupancy,
      numTravellers: travellers.length,
    );

    final ids = <String>[];
    for (final t in travellers) {
      final saved = await _travellers.create(
        firstName: t.firstName,
        lastName: t.lastName,
        email: t.email,
      );
      ids.add(saved.publicId);
    }

    return _booking.setTravellers(draft.publicId, ids);
  }
}

final bookingStarterProvider = Provider<BookingStarter>(
  (ref) => BookingStarter(
    ref.watch(bookingRepositoryProvider),
    ref.watch(travellerRepositoryProvider),
  ),
);
