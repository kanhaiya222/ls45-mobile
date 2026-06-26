import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/catalog_repository.dart';
import '../models/catalog_models.dart';

/// Everything the detail screen needs, fetched together.
class PackageDetailBundle {
  const PackageDetailBundle({
    required this.detail,
    required this.departures,
    required this.itinerary,
    required this.faqs,
  });

  final PackageDetail detail;
  final List<DepartureSummary> departures;
  final Itinerary? itinerary;
  final List<Faq> faqs;
}

/// Loads a package by slug, then its availability, itinerary and FAQs.
final packageDetailProvider =
    FutureProvider.autoDispose.family<PackageDetailBundle, String>((ref, slug) async {
  final repo = ref.watch(catalogRepositoryProvider);
  final detail = await repo.packageBySlug(slug);
  final departures = await repo.availability(detail.publicId);
  final itinerary = await repo.itinerary(detail.publicId);
  final faqs = await repo.faqs(detail.publicId);
  return PackageDetailBundle(
    detail: detail,
    departures: departures,
    itinerary: itinerary,
    faqs: faqs,
  );
});
