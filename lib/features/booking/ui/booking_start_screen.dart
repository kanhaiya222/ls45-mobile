import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_exception.dart';
import '../application/booking_starter.dart';
import '../models/booking_models.dart';

class _TravellerControllers {
  final firstName = TextEditingController();
  final lastName = TextEditingController();
  final email = TextEditingController();

  void dispose() {
    firstName.dispose();
    lastName.dispose();
    email.dispose();
  }
}

/// Step 1 of booking: choose occupancy and enter each traveller's details, then create the draft.
class BookingStartScreen extends ConsumerStatefulWidget {
  const BookingStartScreen({super.key, required this.departurePublicId});

  final String departurePublicId;

  @override
  ConsumerState<BookingStartScreen> createState() => _BookingStartScreenState();
}

class _BookingStartScreenState extends ConsumerState<BookingStartScreen> {
  final _formKey = GlobalKey<FormState>();
  final List<_TravellerControllers> _travellers = [_TravellerControllers()];
  OccupancyType _occupancy = OccupancyType.doubleSharing;
  bool _submitting = false;
  String? _error;

  @override
  void dispose() {
    for (final t in _travellers) {
      t.dispose();
    }
    super.dispose();
  }

  void _addTraveller() => setState(() => _travellers.add(_TravellerControllers()));

  void _removeTraveller(int index) {
    if (_travellers.length <= 1) return;
    setState(() => _travellers.removeAt(index).dispose());
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final travellers = _travellers
          .map((c) => NewTraveller(
                firstName: c.firstName.text.trim(),
                lastName: c.lastName.text.trim(),
                email: c.email.text.trim().isEmpty ? null : c.email.text.trim(),
              ))
          .toList();
      final draft = await ref.read(bookingStarterProvider).start(
            departurePublicId: widget.departurePublicId,
            occupancy: _occupancy,
            travellers: travellers,
          );
      if (mounted) context.go('/checkout/${draft.publicId}');
    } on ApiException catch (e) {
      if (mounted) setState(() => _error = e.message);
    } catch (_) {
      if (mounted) setState(() => _error = 'Could not start your booking. Please try again.');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Start booking')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text('Occupancy', style: Theme.of(context).textTheme.titleMedium),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: [
                  for (final o in OccupancyType.values)
                    ChoiceChip(
                      label: Text(o.label),
                      selected: _occupancy == o,
                      onSelected: (_) => setState(() => _occupancy = o),
                    ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Text('Travellers', style: Theme.of(context).textTheme.titleMedium),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: _submitting ? null : _addTraveller,
                    icon: const Icon(Icons.add),
                    label: const Text('Add'),
                  ),
                ],
              ),
              for (var i = 0; i < _travellers.length; i++) _travellerCard(i),
              const SizedBox(height: 16),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(_error!,
                      style: TextStyle(color: Theme.of(context).colorScheme.error)),
                ),
              FilledButton(
                onPressed: _submitting ? null : _submit,
                child: _submitting
                    ? const SizedBox(
                        height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Continue to checkout'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _travellerCard(int index) {
    final c = _travellers[index];
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Row(
              children: [
                Text('Traveller ${index + 1}',
                    style: Theme.of(context).textTheme.labelLarge),
                const Spacer(),
                if (_travellers.length > 1)
                  IconButton(
                    tooltip: 'Remove',
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: _submitting ? null : () => _removeTraveller(index),
                  ),
              ],
            ),
            TextFormField(
              controller: c.firstName,
              decoration: const InputDecoration(labelText: 'First name'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: c.lastName,
              decoration: const InputDecoration(labelText: 'Last name'),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 8),
            TextFormField(
              controller: c.email,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'Email (optional)'),
              validator: (v) =>
                  (v != null && v.isNotEmpty && !v.contains('@')) ? 'Enter a valid email' : null,
            ),
          ],
        ),
      ),
    );
  }
}
