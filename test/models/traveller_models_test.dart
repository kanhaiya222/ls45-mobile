import 'package:flutter_test/flutter_test.dart';
import 'package:ls45_mobile/features/booking/models/booking_models.dart';
import 'package:ls45_mobile/features/booking/models/traveller_models.dart';

void main() {
  test('Traveller.fromJson + fullName', () {
    final t = Traveller.fromJson({
      'publicId': 't1',
      'firstName': 'Aarav',
      'lastName': 'Mehta',
      'email': 'a@b.com',
      'nationality': 'IN',
    });
    expect(t.fullName, 'Aarav Mehta');
    expect(t.email, 'a@b.com');
    expect(t.nationality, 'IN');
  });

  test('BookingDraft.fromJson', () {
    final d = BookingDraft.fromJson({
      'publicId': 'draft-1',
      'status': 'DRAFT',
      'step': 2,
      'occupancyType': 'DOUBLE_SHARING',
      'numTravellers': 2,
      'totalPrice': 90000,
      'currencyCode': 'INR',
    });
    expect(d.status, 'DRAFT');
    expect(d.step, 2);
    expect(d.numTravellers, 2);
    expect(d.totalPrice, 90000.0);
  });

  test('OccupancyType exposes wire + label', () {
    expect(OccupancyType.doubleSharing.wire, 'DOUBLE_SHARING');
    expect(OccupancyType.single.label, 'Single');
  });
}
