import 'package:flutter_test/flutter_test.dart';
import 'package:ls45_mobile/features/booking/application/booking_starter.dart';
import 'package:ls45_mobile/features/booking/models/booking_models.dart';

import '../../support/fakes.dart';

void main() {
  test('start creates a draft, persists each traveller, then attaches them to the draft', () async {
    final booking = FakeBookingRepository();
    final travellers = FakeTravellerRepository();
    final starter = BookingStarter(booking, travellers);

    final draft = await starter.start(
      departurePublicId: 'dep-1',
      occupancy: OccupancyType.doubleSharing,
      travellers: const [
        NewTraveller(firstName: 'Aarav', lastName: 'Mehta', email: 'a@b.com'),
        NewTraveller(firstName: 'Diya', lastName: 'Sharma'),
      ],
    );

    expect(travellers.created, hasLength(2));
    expect(booking.lastDraftId, 'draft-1');
    expect(booking.lastTravellerIds, ['trav-1', 'trav-2']);
    expect(draft.numTravellers, 2);
  });
}
