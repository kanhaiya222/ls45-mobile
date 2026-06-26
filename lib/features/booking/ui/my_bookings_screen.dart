import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_exception.dart';
import '../application/bookings_providers.dart';
import '../models/booking_models.dart';

class MyBookingsScreen extends ConsumerWidget {
  const MyBookingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final bookings = ref.watch(myBookingsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Your bookings')),
      body: bookings.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(e is ApiException ? e.message : 'Could not load your bookings.',
                    textAlign: TextAlign.center),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () => ref.invalidate(myBookingsProvider),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        data: (list) => list.isEmpty
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Text('You have no bookings yet.', textAlign: TextAlign.center),
                ),
              )
            : RefreshIndicator(
                onRefresh: () async => ref.invalidate(myBookingsProvider),
                child: ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: list.length,
                  itemBuilder: (context, i) => _BookingCard(booking: list[i]),
                ),
              ),
      ),
    );
  }
}

class _BookingCard extends StatelessWidget {
  const _BookingCard({required this.booking});

  final Booking booking;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        title: Text(booking.bookingReference),
        subtitle: Text(
          '${booking.occupancyType} · ${booking.numTravellers} traveller(s)'
          '${booking.totalPrice != null ? ' · ₹${booking.totalPrice!.round()}' : ''}',
        ),
        trailing: Chip(label: Text(booking.status), visualDensity: VisualDensity.compact),
        onTap: () => context.push('/account/bookings/${booking.publicId}'),
      ),
    );
  }
}
