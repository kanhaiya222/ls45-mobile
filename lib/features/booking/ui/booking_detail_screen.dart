import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../appconfig/data/app_config_repository.dart';
import '../../appconfig/models/app_branding.dart';
import '../application/bookings_providers.dart';
import '../application/checkout_service.dart';
import '../models/booking_models.dart';
import '../payment/payment_launcher.dart';

class BookingDetailScreen extends ConsumerStatefulWidget {
  const BookingDetailScreen({super.key, required this.bookingId});

  final String bookingId;

  @override
  ConsumerState<BookingDetailScreen> createState() => _BookingDetailScreenState();
}

class _BookingDetailScreenState extends ConsumerState<BookingDetailScreen> {
  bool _processing = false;

  Future<void> _resumePayment(Booking booking) async {
    setState(() => _processing = true);
    try {
      final outcome = await ref.read(checkoutServiceProvider).resumePayment(booking);
      var paid = false;
      if (outcome is PaymentReady) {
        paid = await ref.read(paymentLauncherProvider).launch(outcome.payment);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(paid
            ? 'Payment complete — booking confirmed.'
            : 'Your booking is reserved; payment is still pending.'),
      ));
      ref.invalidate(bookingDetailProvider(widget.bookingId));
      ref.invalidate(myBookingsProvider);
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(bookingDetailProvider(widget.bookingId));

    return Scaffold(
      appBar: AppBar(title: const Text('Booking')),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text(e is ApiException ? e.message : 'Could not load this booking.'),
        ),
        data: (booking) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text(booking.bookingReference, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Chip(label: Text(booking.status)),
            const SizedBox(height: 16),
            _row('Occupancy', booking.occupancyType),
            _row('Travellers', '${booking.numTravellers}'),
            if (booking.totalPrice != null)
              _row('Total',
                  '${currencySymbolFor(booking.currencyCode ?? ref.watch(currentBrandingProvider).currencyCode)}${booking.totalPrice!.round()}'),
            if (booking.confirmedAt != null) _row('Confirmed', booking.confirmedAt!),
            if (booking.items.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text('Items', style: Theme.of(context).textTheme.titleMedium),
              for (final item in booking.items)
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  title: Text(item.name),
                  trailing: item.totalPrice != null
                      ? Text(
                          '${currencySymbolFor(booking.currencyCode ?? ref.watch(currentBrandingProvider).currencyCode)}${item.totalPrice!.round()}')
                      : null,
                ),
            ],
            if (booking.isPendingPayment) ...[
              const SizedBox(height: 24),
              FilledButton(
                onPressed: _processing ? null : () => _resumePayment(booking),
                child: _processing
                    ? const SizedBox(
                        height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Complete payment'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: TextStyle(color: Colors.grey[700])),
            Text(value),
          ],
        ),
      );
}
