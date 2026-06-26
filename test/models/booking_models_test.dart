import 'package:flutter_test/flutter_test.dart';
import 'package:ls45_mobile/features/booking/models/booking_models.dart';

void main() {
  test('Booking.fromJson parses fields, items and status helpers', () {
    final b = Booking.fromJson({
      'publicId': 'bk-1',
      'bookingReference': 'LS45-0001',
      'status': 'CONFIRMED',
      'occupancyType': 'DOUBLE_SHARING',
      'departureId': 100,
      'numTravellers': 2,
      'totalPrice': 90000.0,
      'currencyCode': 'INR',
      'items': [
        {'publicId': 'i1', 'itemType': 'DEPARTURE', 'name': 'Twin share', 'quantity': 2, 'totalPrice': 90000},
      ],
    });

    expect(b.bookingReference, 'LS45-0001');
    expect(b.isConfirmed, isTrue);
    expect(b.isCancelled, isFalse);
    expect(b.numTravellers, 2);
    expect(b.items, hasLength(1));
    expect(b.items.first.quantity, 2);
  });

  test('Booking status helpers reflect PENDING_PAYMENT', () {
    final b = Booking.fromJson({
      'publicId': 'bk-2',
      'bookingReference': 'LS45-0002',
      'status': 'PENDING_PAYMENT',
      'occupancyType': 'SINGLE',
    });
    expect(b.isPendingPayment, isTrue);
    expect(b.isConfirmed, isFalse);
    expect(b.items, isEmpty);
  });
}
