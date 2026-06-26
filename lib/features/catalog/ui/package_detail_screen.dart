import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_exception.dart';
import '../models/catalog_models.dart';
import '../state/package_detail_controller.dart';

class PackageDetailScreen extends ConsumerWidget {
  const PackageDetailScreen({super.key, required this.slug});

  final String slug;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(packageDetailProvider(slug));

    return Scaffold(
      appBar: AppBar(title: const Text('Journey')),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(e is ApiException ? e.message : 'Could not load this journey.',
                    textAlign: TextAlign.center),
                const SizedBox(height: 12),
                FilledButton(
                  onPressed: () => ref.invalidate(packageDetailProvider(slug)),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
        data: (bundle) => _DetailBody(bundle: bundle),
      ),
    );
  }
}

class _DetailBody extends StatelessWidget {
  const _DetailBody({required this.bundle});

  final PackageDetailBundle bundle;

  @override
  Widget build(BuildContext context) {
    final d = bundle.detail;
    final text = Theme.of(context).textTheme;

    return ListView(
      children: [
        _MediaCarousel(detail: d),
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(d.name, style: text.headlineSmall),
              const SizedBox(height: 6),
              Text(
                '${d.durationDays}D / ${d.durationNights}N'
                '${d.difficulty != null ? ' · ${d.difficulty}' : ''}'
                '${d.meetingLocation != null ? ' · ${d.meetingLocation}' : ''}',
                style: text.bodyMedium?.copyWith(color: Colors.grey[700]),
              ),
              if (d.basePrice != null) ...[
                const SizedBox(height: 8),
                Text('from ₹${d.basePrice!.round()}',
                    style: text.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
              ],
              if (d.shortDescription != null) ...[
                const SizedBox(height: 12),
                Text(d.shortDescription!, style: text.bodyLarge),
              ],
              if (d.description != null) ...[
                const SizedBox(height: 8),
                Text(d.description!, style: text.bodyMedium),
              ],
              _Highlights(highlights: d.highlights),
              _BulletSection(title: "What's included", items: d.inclusions),
              _BulletSection(title: 'Not included', items: d.exclusions),
              _Departures(departures: bundle.departures),
              _ItineraryView(itinerary: bundle.itinerary),
              _Faqs(faqs: bundle.faqs),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ],
    );
  }
}

class _MediaCarousel extends StatelessWidget {
  const _MediaCarousel({required this.detail});

  final PackageDetail detail;

  @override
  Widget build(BuildContext context) {
    final urls = <String>{
      if (detail.heroImageUrl != null) detail.heroImageUrl!,
      ...detail.media.map((m) => m.url),
    }.toList();

    if (urls.isEmpty) return const SizedBox.shrink();

    return SizedBox(
      height: 240,
      child: PageView(
        children: [
          for (final url in urls)
            Image.network(
              url,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const ColoredBox(color: Color(0xFFE5E7EB)),
            ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.title);
  final String title;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 20, bottom: 8),
        child: Text(title, style: Theme.of(context).textTheme.titleMedium),
      );
}

class _Highlights extends StatelessWidget {
  const _Highlights({required this.highlights});
  final List<String>? highlights;

  @override
  Widget build(BuildContext context) {
    if (highlights == null || highlights!.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle('Highlights'),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [for (final h in highlights!) Chip(label: Text(h))],
        ),
      ],
    );
  }
}

class _BulletSection extends StatelessWidget {
  const _BulletSection({required this.title, required this.items});
  final String title;
  final List<String>? items;

  @override
  Widget build(BuildContext context) {
    if (items == null || items!.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _SectionTitle(title),
        for (final i in items!)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 2),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('•  '),
                Expanded(child: Text(i)),
              ],
            ),
          ),
      ],
    );
  }
}

class _Departures extends StatelessWidget {
  const _Departures({required this.departures});
  final List<DepartureSummary> departures;

  @override
  Widget build(BuildContext context) {
    if (departures.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle('Upcoming departures'),
        for (final dep in departures)
          Card(
            margin: const EdgeInsets.only(bottom: 8),
            child: ListTile(
              title: Text('${dep.startDate} – ${dep.endDate}'),
              subtitle: Text('${dep.status} · ${dep.availableSeats} seats left'),
              trailing: dep.priceFrom != null
                  ? Text('from ₹${dep.priceFrom!.round()}',
                      style: const TextStyle(fontWeight: FontWeight.bold))
                  : null,
              // Only OPEN departures can be booked; others are display-only.
              onTap: dep.status == 'OPEN' ? () => context.push('/book/${dep.publicId}') : null,
            ),
          ),
      ],
    );
  }
}

class _ItineraryView extends StatelessWidget {
  const _ItineraryView({required this.itinerary});
  final Itinerary? itinerary;

  @override
  Widget build(BuildContext context) {
    final days = itinerary?.days ?? const [];
    if (days.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle('Day-by-day itinerary'),
        for (final day in days)
          ExpansionTile(
            tilePadding: EdgeInsets.zero,
            title: Text('Day ${day.dayNumber}${day.title != null ? ' · ${day.title}' : ''}'),
            subtitle: day.location != null ? Text(day.location!) : null,
            childrenPadding: const EdgeInsets.only(bottom: 8),
            children: [
              if (day.description != null)
                Align(alignment: Alignment.centerLeft, child: Text(day.description!)),
              for (final act in day.activities)
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: act.startTime != null ? Text(act.startTime!) : const Icon(Icons.circle, size: 8),
                  title: Text(act.title),
                ),
            ],
          ),
      ],
    );
  }
}

class _Faqs extends StatelessWidget {
  const _Faqs({required this.faqs});
  final List<Faq> faqs;

  @override
  Widget build(BuildContext context) {
    if (faqs.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _SectionTitle('FAQs'),
        for (final faq in faqs)
          ExpansionTile(
            tilePadding: EdgeInsets.zero,
            title: Text(faq.question),
            childrenPadding: const EdgeInsets.only(bottom: 12),
            children: [Align(alignment: Alignment.centerLeft, child: Text(faq.answer))],
          ),
      ],
    );
  }
}
