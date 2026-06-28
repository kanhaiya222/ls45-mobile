import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_exception.dart';
import '../../../shared/ui/app_ui.dart';
import '../../appconfig/models/app_branding.dart';
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
    if (_reserved != null) {
      return Scaffold(
        appBar: AppBar(automaticallyImplyLeading: false, title: const Text('Booking')),
        body: SafeArea(child: _Confirmation(booking: _reserved!, paid: _paid)),
      );
    }

    final review = ref.watch(checkoutReviewProvider(widget.draftId));
    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: SafeArea(
        child: review.when(
          loading: () => const LoadingView(label: 'Loading your booking…'),
          error: (e, _) => StateView(
            icon: Icons.cloud_off_rounded,
            title: 'Could not load checkout',
            message: e is ApiException ? e.message : 'Please try again.',
            iconColor: Theme.of(context).colorScheme.error,
            actionLabel: 'Try again',
            onAction: () => ref.invalidate(checkoutReviewProvider(widget.draftId)),
          ),
          data: _buildReview,
        ),
      ),
      bottomNavigationBar: review.maybeWhen(
        data: (snap) => BottomBar(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (snap.totalPrice != null) ...[
                _TotalRow(snap: snap),
                const SizedBox(height: 12),
              ],
              PrimaryButton(
                label: 'Reserve & pay',
                icon: Icons.lock_rounded,
                busy: _processing,
                onPressed: () => _reserveAndPay(snap),
              ),
            ],
          ),
        ),
        orElse: () => null,
      ),
    );
  }

  Widget _buildReview(BookingPriceSnapshot snap) {
    final scheme = Theme.of(context).colorScheme;
    final currency = snap.currencyCode ?? 'INR';
    String money(double v) => '${currencySymbolFor(currency)}${v.round()}';

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
      children: [
        ConstrainedBody(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Review your booking',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
              const SizedBox(height: 4),
              Text("You won't be charged until you reserve & pay.",
                  style: TextStyle(color: scheme.onSurfaceVariant)),
              const SizedBox(height: 16),
              SectionCard(
                title: 'Price summary',
                child: Column(
                  children: [
                    if (snap.basePrice != null) SummaryRow(label: 'Base price', value: money(snap.basePrice!)),
                    if (snap.addonTotal != null && snap.addonTotal! > 0)
                      SummaryRow(label: 'Add-ons', value: money(snap.addonTotal!)),
                    if (snap.couponDiscount != null && snap.couponDiscount! > 0)
                      SummaryRow(
                        label: 'Discount',
                        value: '−${money(snap.couponDiscount!)}',
                        valueColor: const Color(0xFF15803D),
                      ),
                    if (snap.taxAmount != null) SummaryRow(label: 'Taxes & fees', value: money(snap.taxAmount!)),
                    if (snap.totalPrice != null) ...[
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 6),
                        child: Divider(height: 1),
                      ),
                      SummaryRow(label: 'Total', value: money(snap.totalPrice!), emphasize: true),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Icon(Icons.verified_user_outlined, size: 18, color: scheme.onSurfaceVariant),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text('Your seat is held the moment you reserve. Payment confirms it.',
                        style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13)),
                  ),
                ],
              ),
              if (_error != null) ...[
                const SizedBox(height: 16),
                AppBanner(message: _error!),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _TotalRow extends StatelessWidget {
  const _TotalRow({required this.snap});

  final BookingPriceSnapshot snap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final currency = snap.currencyCode ?? 'INR';
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('Total', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
        Text('${currencySymbolFor(currency)}${snap.totalPrice!.round()}',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: scheme.primary)),
      ],
    );
  }
}

class _Confirmation extends StatelessWidget {
  const _Confirmation({required this.booking, required this.paid});

  final Booking booking;
  final bool paid;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final accent = paid ? const Color(0xFF15803D) : const Color(0xFFB45309);

    return ConstrainedBody(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 92,
              height: 92,
              decoration: BoxDecoration(color: accent.withValues(alpha: 0.12), shape: BoxShape.circle),
              child: Icon(paid ? Icons.check_rounded : Icons.schedule_rounded, size: 50, color: accent),
            ),
            const SizedBox(height: 24),
            Text(
              paid ? 'Booking confirmed' : 'Seat reserved',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 10),
            Text(
              paid
                  ? 'Your payment is complete and your seat is confirmed. A confirmation is on its way.'
                  : 'Your seat is held. Complete payment from your bookings to confirm it.',
              textAlign: TextAlign.center,
              style: TextStyle(color: scheme.onSurfaceVariant, height: 1.45),
            ),
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: scheme.surfaceContainerHighest.withValues(alpha: 0.6),
                borderRadius: BorderRadius.circular(999),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.confirmation_number_outlined, size: 16, color: scheme.onSurfaceVariant),
                  const SizedBox(width: 8),
                  Text('Ref ${booking.bookingReference}',
                      style: const TextStyle(fontWeight: FontWeight.w700, letterSpacing: 0.3)),
                ],
              ),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: PrimaryButton(
                label: 'View my bookings',
                onPressed: () => context.go('/account/bookings'),
              ),
            ),
            const SizedBox(height: 4),
            TextButton(onPressed: () => context.go('/'), child: const Text('Back to journeys')),
          ],
        ),
      ),
    );
  }
}
