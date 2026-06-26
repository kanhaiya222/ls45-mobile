import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../data/booking_repository.dart';
import '../models/booking_models.dart';

/// Result of a reserve+pay attempt.
sealed class CheckoutOutcome {
  const CheckoutOutcome(this.booking);
  final Booking booking;
}

/// The booking is reserved and payment is configured — proceed to the payment sheet.
class PaymentReady extends CheckoutOutcome {
  const PaymentReady(super.booking, this.payment);
  final PaymentInitiation payment;
}

/// The booking is reserved but online payment is unavailable (disabled / not wired) — pending.
class ReservedPaymentPending extends CheckoutOutcome {
  const ReservedPaymentPending(super.booking);
}

class CheckoutService {
  CheckoutService(this._booking);

  final BookingRepository _booking;

  Future<BookingPriceSnapshot> review(String draftPublicId) => _booking.review(draftPublicId);

  /// Confirms the draft (reserves the booking as PENDING_PAYMENT), then tries to start payment.
  /// When payments are disabled (PAYMENT_NOT_CONFIGURED) the booking stays reserved (pending).
  Future<CheckoutOutcome> reserveAndPay(String draftPublicId, String priceSnapshotPublicId) async {
    final booking = await _booking.confirm(draftPublicId, priceSnapshotPublicId);
    return _startPayment(booking);
  }

  /// Resumes payment for an already-reserved (PENDING_PAYMENT) booking.
  Future<CheckoutOutcome> resumePayment(Booking booking) => _startPayment(booking);

  Future<CheckoutOutcome> _startPayment(Booking booking) async {
    try {
      final payment = await _booking.initiatePayment(booking.publicId);
      return PaymentReady(booking, payment);
    } on ApiException catch (e) {
      if (e.errorCode == 'PAYMENT_NOT_CONFIGURED') {
        return ReservedPaymentPending(booking);
      }
      rethrow;
    }
  }
}

final checkoutServiceProvider =
    Provider<CheckoutService>((ref) => CheckoutService(ref.watch(bookingRepositoryProvider)));

final checkoutReviewProvider =
    FutureProvider.autoDispose.family<BookingPriceSnapshot, String>(
  (ref, draftId) => ref.watch(checkoutServiceProvider).review(draftId),
);
