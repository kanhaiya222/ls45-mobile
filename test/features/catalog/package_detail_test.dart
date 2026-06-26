import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ls45_mobile/features/catalog/data/catalog_repository.dart';
import 'package:ls45_mobile/features/catalog/models/catalog_models.dart';
import 'package:ls45_mobile/features/catalog/state/package_detail_controller.dart';

import '../../support/fakes.dart';

void main() {
  test('packageDetailProvider assembles detail + departures + itinerary + faqs', () async {
    final repo = FakeCatalogRepository(
      detail: fakeDetail('Himalayan Yoga'),
      departures: const [
        DepartureSummary(
          publicId: 'd1',
          packagePublicId: 'Himalayan Yoga-id',
          startDate: '2026-07-15',
          endDate: '2026-07-21',
          status: 'OPEN',
          availableSeats: 10,
          pricing: [DeparturePricing(occupancyType: 'DOUBLE_SHARING', price: 45000)],
        ),
      ],
      itin: const Itinerary(
        publicId: 'it1',
        packagePublicId: 'Himalayan Yoga-id',
        days: [ItineraryDay(publicId: 'day1', dayNumber: 1, title: 'Arrival')],
      ),
      faqList: const [Faq(question: 'Beginner friendly?', answer: 'Yes.')],
    );
    final container = ProviderContainer(
      overrides: [catalogRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);

    final bundle = await container.read(packageDetailProvider('himalayan-yoga').future);

    expect(bundle.detail.name, 'Himalayan Yoga');
    expect(bundle.departures, hasLength(1));
    expect(bundle.departures.first.priceFrom, 45000.0);
    expect(bundle.itinerary?.days.first.title, 'Arrival');
    expect(bundle.faqs.first.question, 'Beginner friendly?');
  });
}
