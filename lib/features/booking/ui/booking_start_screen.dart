import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_exception.dart';
import '../../../shared/ui/app_ui.dart';
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
    FocusScope.of(context).unfocus();
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
      appBar: AppBar(title: const Text('Travellers & rooming')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
            children: [
              ConstrainedBody(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SectionCard(
                      title: 'Room type',
                      child: Column(
                        children: [
                          for (final o in OccupancyType.values)
                            _OccupancyOption(
                              label: o.label,
                              selected: _occupancy == o,
                              onTap: _submitting ? null : () => setState(() => _occupancy = o),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Text("Who's travelling",
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                        const Spacer(),
                        Text('${_travellers.length}',
                            style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    for (var i = 0; i < _travellers.length; i++) ...[
                      _travellerCard(i),
                      const SizedBox(height: 12),
                    ],
                    OutlinedButton.icon(
                      onPressed: _submitting ? null : _addTraveller,
                      icon: const Icon(Icons.person_add_alt_1_rounded),
                      label: const Text('Add another traveller'),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 16),
                      AppBanner(message: _error!),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: BottomBar(
        child: PrimaryButton(
          label: 'Continue to checkout',
          icon: Icons.arrow_forward_rounded,
          busy: _submitting,
          onPressed: _submit,
        ),
      ),
    );
  }

  Widget _travellerCard(int index) {
    final c = _travellers[index];
    return SectionCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 14,
                backgroundColor: Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
                child: Text('${index + 1}',
                    style: TextStyle(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w700,
                        fontSize: 13)),
              ),
              const SizedBox(width: 10),
              Text('Traveller ${index + 1}',
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              const Spacer(),
              if (_travellers.length > 1)
                IconButton(
                  tooltip: 'Remove',
                  visualDensity: VisualDensity.compact,
                  icon: const Icon(Icons.close_rounded, size: 20),
                  onPressed: _submitting ? null : () => _removeTraveller(index),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: TextFormField(
                  controller: c.firstName,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(labelText: 'First name'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: TextFormField(
                  controller: c.lastName,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(labelText: 'Last name'),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Required' : null,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: c.email,
            keyboardType: TextInputType.emailAddress,
            decoration: const InputDecoration(labelText: 'Email (optional)'),
            validator: (v) =>
                (v != null && v.isNotEmpty && !v.contains('@')) ? 'Enter a valid email' : null,
          ),
        ],
      ),
    );
  }
}

class _OccupancyOption extends StatelessWidget {
  const _OccupancyOption({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: selected ? scheme.primary.withValues(alpha: 0.06) : Colors.transparent,
        borderRadius: BorderRadius.circular(kRadiusMd),
        child: InkWell(
          borderRadius: BorderRadius.circular(kRadiusMd),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(kRadiusMd),
              border: Border.all(
                color: selected ? scheme.primary : scheme.outlineVariant,
                width: selected ? 1.6 : 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  selected ? Icons.radio_button_checked_rounded : Icons.radio_button_unchecked_rounded,
                  color: selected ? scheme.primary : scheme.outline,
                  size: 22,
                ),
                const SizedBox(width: 12),
                Text(label,
                    style: TextStyle(
                        fontSize: 15, fontWeight: selected ? FontWeight.w700 : FontWeight.w500)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
