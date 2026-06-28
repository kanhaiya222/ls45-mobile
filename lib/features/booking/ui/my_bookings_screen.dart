import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_exception.dart';
import '../../../shared/ui/app_ui.dart';
import '../../appconfig/data/app_config_repository.dart';
import '../../appconfig/models/app_branding.dart';
import '../../auth/state/auth_controller.dart';
import '../application/bookings_providers.dart';
import '../models/booking_models.dart';

class MyBookingsScreen extends ConsumerWidget {
  const MyBookingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final signedIn = ref.watch(authControllerProvider).value != null;

    return Scaffold(
      appBar: AppBar(title: const Text('Your bookings')),
      body: SafeArea(
        child: signedIn
            ? _bookingsBody(context, ref)
            : StateView(
                icon: Icons.lock_outline_rounded,
                title: 'Sign in to see your bookings',
                message: 'Your trips and payment status live here once you sign in.',
                actionLabel: 'Sign in',
                onAction: () => context.go('/login'),
              ),
      ),
    );
  }

  Widget _bookingsBody(BuildContext context, WidgetRef ref) {
    return ref.watch(myBookingsProvider).when(
          loading: () => const LoadingView(),
          error: (e, _) => StateView(
            icon: Icons.cloud_off_rounded,
            title: 'Could not load your bookings',
            message: e is ApiException ? e.message : 'Please try again.',
            iconColor: Theme.of(context).colorScheme.error,
            actionLabel: 'Try again',
            onAction: () => ref.invalidate(myBookingsProvider),
          ),
          data: (list) => list.isEmpty
              ? StateView(
                  icon: Icons.luggage_outlined,
                  title: 'No bookings yet',
                  message: "When you book a journey, it'll appear here.",
                  actionLabel: 'Explore journeys',
                  onAction: () => context.go('/'),
                )
              : RefreshIndicator(
                  onRefresh: () async => ref.invalidate(myBookingsProvider),
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
                    itemCount: list.length,
                    itemBuilder: (context, i) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: ConstrainedBody(child: _BookingCard(booking: list[i])),
                    ),
                  ),
                ),
        );
  }
}

class _BookingCard extends ConsumerWidget {
  const _BookingCard({required this.booking});

  final Booking booking;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final code = booking.currencyCode ?? ref.watch(currentBrandingProvider).currencyCode;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(kRadiusLg),
        boxShadow: softShadow(context),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(kRadiusLg),
        child: InkWell(
          borderRadius: BorderRadius.circular(kRadiusLg),
          onTap: () => context.push('/account/bookings/${booking.publicId}'),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(booking.bookingReference,
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16, letterSpacing: 0.2)),
                    ),
                    StatusPill(booking.status),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _Meta(icon: Icons.king_bed_outlined, label: prettifyStatus(booking.occupancyType)),
                    const SizedBox(width: 16),
                    _Meta(icon: Icons.group_outlined, label: '${booking.numTravellers} traveller(s)'),
                  ],
                ),
                if (booking.totalPrice != null) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Text('${currencySymbolFor(code)}${booking.totalPrice!.round()}',
                          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17, color: scheme.onSurface)),
                      const Spacer(),
                      Text('Details', style: TextStyle(color: scheme.primary, fontWeight: FontWeight.w600)),
                      Icon(Icons.chevron_right_rounded, color: scheme.primary, size: 20),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Meta extends StatelessWidget {
  const _Meta({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: scheme.onSurfaceVariant),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13)),
      ],
    );
  }
}
