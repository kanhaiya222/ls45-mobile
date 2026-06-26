import 'package:flutter_test/flutter_test.dart';
import 'package:ls45_mobile/features/catalog/models/catalog_models.dart';

void main() {
  test('Category.fromJson', () {
    final c = Category.fromJson({
      'publicId': 'cat-1',
      'name': 'Himalayan Retreats',
      'slug': 'himalayan-retreats',
      'sortOrder': 1,
      'active': true,
      'packageCount': 4,
    });
    expect(c.publicId, 'cat-1');
    expect(c.name, 'Himalayan Retreats');
    expect(c.packageCount, 4);
    expect(c.active, isTrue);
  });

  test('PackageSummary.fromJson handles int and missing optionals', () {
    final p = PackageSummary.fromJson({
      'publicId': 'pkg-1',
      'name': 'Himalayan Yoga Retreat',
      'slug': 'himalayan-yoga-retreat',
      'basePrice': 45000, // int from JSON -> double
      'durationDays': 7,
      'durationNights': 6,
      'featured': true,
    });
    expect(p.basePrice, 45000.0);
    expect(p.durationDays, 7);
    expect(p.featured, isTrue);
    expect(p.heroImageUrl, isNull);
  });

  test('PackageDetail.fromJson parses string lists + nested media', () {
    final d = PackageDetail.fromJson({
      'publicId': 'pkg-1',
      'name': 'Himalayan Yoga Retreat',
      'slug': 'himalayan-yoga-retreat',
      'basePrice': 45000.0,
      'currencyCode': 'INR',
      'durationDays': 7,
      'durationNights': 6,
      'highlights': ['Sunrise yoga', 'Meditation'],
      'media': [
        {'publicId': 'm1', 'url': 'https://img/1.jpg', 'primary': true, 'sortOrder': 0},
        {'publicId': 'm2', 'url': 'https://img/2.jpg', 'sortOrder': 1},
      ],
    });
    expect(d.highlights, ['Sunrise yoga', 'Meditation']);
    expect(d.media, hasLength(2));
    expect(d.media.first.primary, isTrue);
    expect(d.media[1].primary, isFalse);
  });

  test('DepartureSummary.fromJson computes priceFrom from active pricing', () {
    final dep = DepartureSummary.fromJson({
      'publicId': 'dep-1',
      'packagePublicId': 'pkg-1',
      'startDate': '2026-07-15',
      'endDate': '2026-07-21',
      'status': 'OPEN',
      'totalCapacity': 14,
      'availableSeats': 10,
      'soldOut': false,
      'pricing': [
        {'occupancyType': 'SINGLE', 'price': 63000.0, 'active': true},
        {'occupancyType': 'DOUBLE_SHARING', 'price': 45000, 'active': true},
        {'occupancyType': 'TRIPLE_SHARING', 'price': 40000.0, 'active': false},
      ],
    });
    expect(dep.status, 'OPEN');
    expect(dep.pricing, hasLength(3));
    expect(dep.priceFrom, 45000.0); // lowest ACTIVE
  });

  test('Faq.fromJson', () {
    final f = Faq.fromJson({'question': 'Suitable for beginners?', 'answer': 'Yes.'});
    expect(f.question, 'Suitable for beginners?');
    expect(f.answer, 'Yes.');
  });

  test('Itinerary.fromJson parses nested days + activities', () {
    final it = Itinerary.fromJson({
      'publicId': 'it-1',
      'packagePublicId': 'pkg-1',
      'label': 'Standard Itinerary',
      'days': [
        {
          'publicId': 'd1',
          'dayNumber': 1,
          'title': 'Arrival',
          'activities': [
            {'publicId': 'a1', 'title': 'Ganga aarti', 'free': true, 'optional': false},
          ],
        },
      ],
    });
    expect(it.days, hasLength(1));
    expect(it.days.first.dayNumber, 1);
    expect(it.days.first.activities.first.title, 'Ganga aarti');
  });
}
