import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ls45_mobile/features/booking/application/bookings_providers.dart';
import 'package:ls45_mobile/features/booking/application/checkout_service.dart';
import 'package:ls45_mobile/features/booking/data/booking_repository.dart';
import 'package:ls45_mobile/features/booking/models/booking_models.dart';

import '../../support/fakes.dart';

void main() {
  const booking = Booking(
    publicId: 'bk-1',
    bookingReference: 'LS45-9',
    status: 'PENDING_PAYMENT',
    occupancyType: 'DOUBLE_SHARING',
    numTravellers: 2,
    totalPrice: 94500,
  );

  ProviderContainer withRepo(FakeBookingRepository repo) {
    final container = ProviderContainer(
      overrides: [bookingRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);
    return container;
  }

  test('myBookingsProvider returns the user bookings', () async {
    final container = withRepo(FakeBookingRepository()..bookings = [booking]);

    final list = await container.read(myBookingsProvider.future);

    expect(list, hasLength(1));
    expect(list.first.bookingReference, 'LS45-9');
  });

  test('bookingDetailProvider returns the booking by id', () async {
    final container = withRepo(FakeBookingRepository()..bookings = [booking]);

    final b = await container.read(bookingDetailProvider('bk-1').future);

    expect(b.publicId, 'bk-1');
    expect(b.isPendingPayment, isTrue);
  });

  test('resumePayment returns ReservedPaymentPending when payments disabled', () async {
    final outcome = await CheckoutService(FakeBookingRepository()).resumePayment(booking);

    expect(outcome, isA<ReservedPaymentPending>());
    expect(outcome.booking.publicId, 'bk-1');
  });
}
