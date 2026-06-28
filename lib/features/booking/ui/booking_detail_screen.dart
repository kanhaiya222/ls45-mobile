import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../shared/ui/app_ui.dart';
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
    final booking = async.value;

    return Scaffold(
      appBar: AppBar(title: const Text('Booking')),
      body: SafeArea(
        child: async.when(
          loading: () => const LoadingView(),
          error: (e, _) => StateView(
            icon: Icons.cloud_off_rounded,
            title: 'Could not load this booking',
            message: e is ApiException ? e.message : 'Please try again.',
            iconColor: Theme.of(context).colorScheme.error,
            actionLabel: 'Try again',
            onAction: () => ref.invalidate(bookingDetailProvider(widget.bookingId)),
          ),
          data: (b) => _Body(booking: b),
        ),
      ),
      bottomNavigationBar: (booking != null && booking.isPendingPayment)
          ? BottomBar(
              child: PrimaryButton(
                label: 'Complete payment',
                icon: Icons.lock_rounded,
                busy: _processing,
                onPressed: () => _resumePayment(booking),
              ),
            )
          : null,
    );
  }
}

class _Body extends ConsumerWidget {
  const _Body({required this.booking});

  final Booking booking;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final code = booking.currencyCode ?? ref.watch(currentBrandingProvider).currencyCode;
    String money(double v) => '${currencySymbolFor(code)}${v.round()}';

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        ConstrainedBody(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(booking.bookingReference,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
                  ),
                  const SizedBox(width: 12),
                  StatusPill(booking.status),
                ],
              ),
              const SizedBox(height: 16),
              if (booking.isPendingPayment) ...[
                const AppBanner(
                  message: 'Payment pending — complete it to confirm your seat.',
                  tone: BannerTone.info,
                  icon: Icons.schedule_rounded,
                ),
                const SizedBox(height: 16),
              ],
              SectionCard(
                title: 'Trip details',
                child: Column(
                  children: [
                    SummaryRow(label: 'Room type', value: prettifyStatus(booking.occupancyType)),
                    SummaryRow(label: 'Travellers', value: '${booking.numTravellers}'),
                    if (booking.totalPrice != null)
                      SummaryRow(label: 'Total paid / due', value: money(booking.totalPrice!), emphasize: true),
                    if (booking.confirmedAt != null)
                      SummaryRow(label: 'Confirmed', value: booking.confirmedAt!),
                  ],
                ),
              ),
              if (booking.items.isNotEmpty) ...[
                const SizedBox(height: 16),
                SectionCard(
                  title: 'Items',
                  child: Column(
                    children: [
                      for (final item in booking.items)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Row(
                            children: [
                              Icon(Icons.check_circle_outline_rounded, size: 18, color: scheme.primary),
                              const SizedBox(width: 10),
                              Expanded(child: Text(item.name)),
                              if (item.totalPrice != null)
                                Text(money(item.totalPrice!),
                                    style: const TextStyle(fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
