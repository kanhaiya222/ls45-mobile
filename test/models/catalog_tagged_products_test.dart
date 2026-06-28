import 'package:flutter_test/flutter_test.dart';
import 'package:ls45_mobile/features/catalog/models/catalog_models.dart';

void main() {
  test('PackageDetail.fromJson parses taggedProducts ("Shop this journey")', () {
    final d = PackageDetail.fromJson({
      'publicId': 'pkg-1',
      'name': 'Himalayan Yoga Retreat',
      'slug': 'himalayan-yoga-retreat',
      'taggedProducts': [
        {
          'publicId': 'prod-1',
          'name': 'Yoga Cork Mat',
          'slug': 'yoga-cork-mat',
          'shortDescription': 'Natural cork, non-slip.',
          'basePrice': 1899.0,
          'currencyCode': 'INR',
        },
      ],
    });

    expect(d.taggedProducts.length, 1);
    expect(d.taggedProducts.single.name, 'Yoga Cork Mat');
    expect(d.taggedProducts.single.slug, 'yoga-cork-mat');
    expect(d.taggedProducts.single.basePrice, 1899.0);
  });

  test('PackageDetail.fromJson defaults taggedProducts to empty when absent', () {
    final d = PackageDetail.fromJson({'publicId': 'p', 'name': 'n', 'slug': 's'});
    expect(d.taggedProducts, isEmpty);
  });
}
