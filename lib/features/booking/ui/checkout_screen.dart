import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_exception.dart';
import '../application/checkout_service.dart';
import '../models/booking_models.dart';
import '../payment/payment_launcher.dart';

class CheckoutScreen extends ConsumerStatefulWidget {
  const CheckoutScreen({super.key, required this.draftId});

  final String draftId;

  @override
  ConsumerState<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends ConsumerState<CheckoutScreen> {
  bool _processing = false;
  String? _error;
  Booking? _reserved;
  bool _paid = false;

  Future<void> _reserveAndPay(BookingPriceSnapshot snap) async {
    setState(() {
      _processing = true;
      _error = null;
    });
    try {
      final outcome =
          await ref.read(checkoutServiceProvider).reserveAndPay(widget.draftId, snap.publicId);
      var paid = false;
      if (outcome is PaymentReady) {
        paid = await ref.read(paymentLauncherProvider).launch(outcome.payment);
      }
      if (mounted) {
        setState(() {
          _reserved = outcome.booking;
          _paid = paid;
        });
      }
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Could not complete checkout. Please try again.');
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: _reserved != null
          ? _Confirmation(booking: _reserved!, paid: _paid)
          : ref.watch(checkoutReviewProvider(widget.draftId)).when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (e, _) => Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(e is ApiException ? e.message : 'Could not load your booking.',
                            textAlign: TextAlign.center),
                        const SizedBox(height: 12),
                        FilledButton(
                          onPressed: () => ref.invalidate(checkoutReviewProvider(widget.draftId)),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  ),
                ),
                data: _buildReview,
              ),
    );
  }

  Widget _buildReview(BookingPriceSnapshot snap) {
    final currency = snap.currencyCode ?? 'INR';
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Price summary', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 12),
        if (snap.basePrice != null) _row('Base price', snap.basePrice!, currency),
        if (snap.addonTotal != null && snap.addonTotal! > 0)
          _row('Add-ons', snap.addonTotal!, currency),
        if (snap.couponDiscount != null && snap.couponDiscount! > 0)
          _row('Discount', -snap.couponDiscount!, currency),
        if (snap.taxAmount != null) _row('Taxes', snap.taxAmount!, currency),
        const Divider(height: 24),
        if (snap.totalPrice != null) _row('Total', snap.totalPrice!, currency, bold: true),
        const SizedBox(height: 24),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(_error!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ),
        FilledButton(
          onPressed: _processing ? null : () => _reserveAndPay(snap),
          child: _processing
              ? const SizedBox(
                  height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
              : const Text('Reserve & pay'),
        ),
      ],
    );
  }

  Widget _row(String label, double amount, String currency, {bool bold = false}) {
    final style = bold
        ? Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)
        : Theme.of(context).textTheme.bodyLarge;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: style),
          Text('₹${amount.round()}', style: style),
        ],
      ),
    );
  }
}

class _Confirmation extends StatelessWidget {
  const _Confirmation({required this.booking, required this.paid});

  final Booking booking;
  final bool paid;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(paid ? Icons.check_circle : Icons.schedule,
                size: 64, color: paid ? Colors.green : Colors.orange),
            const SizedBox(height: 16),
            Text(
              paid ? 'Booking confirmed' : 'Booking reserved',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text('Reference: ${booking.bookingReference}', textAlign: TextAlign.center),
            const SizedBox(height: 8),
            Text(
              paid
                  ? 'Your payment is complete and your seat is confirmed.'
                  : 'Your seat is held. Complete payment to confirm your booking.',
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            FilledButton(
              onPressed: () => context.go('/account/bookings'),
              child: const Text('View my bookings'),
            ),
          ],
        ),
      ),
    );
  }
}
