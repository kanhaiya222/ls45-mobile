import 'package:flutter_test/flutter_test.dart';
import 'package:ls45_mobile/features/booking/application/checkout_service.dart';

import '../../support/fakes.dart';

void main() {
  test('reserveAndPay returns ReservedPaymentPending when payments are disabled', () async {
    final service = CheckoutService(FakeBookingRepository());

    final outcome = await service.reserveAndPay('draft-1', 'snap-1');

    expect(outcome, isA<ReservedPaymentPending>());
    expect(outcome.booking.bookingReference, 'LS45-0001');
    expect(outcome.booking.isPendingPayment, isTrue);
  });

  test('reserveAndPay returns PaymentReady when payments are configured', () async {
    final repo = FakeBookingRepository()..paymentConfigured = true;
    final service = CheckoutService(repo);

    final outcome = await service.reserveAndPay('draft-1', 'snap-1');

    expect(outcome, isA<PaymentReady>());
    expect((outcome as PaymentReady).payment.razorpayOrderId, 'order_1');
  });

  test('review returns the locked price snapshot', () async {
    final service = CheckoutService(FakeBookingRepository());

    final snap = await service.review('draft-1');

    expect(snap.totalPrice, 94500.0);
    expect(snap.currencyCode, 'INR');
  });
}
