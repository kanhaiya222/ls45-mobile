import 'package:flutter_test/flutter_test.dart';
import 'package:ls45_mobile/features/shop/models/shop_models.dart';

void main() {
  test('ReviewSummary.fromJson parses average + reviews', () {
    final s = ReviewSummary.fromJson({
      'averageRating': 4.5,
      'totalReviews': 2,
      'reviews': [
        {'publicId': 'r1', 'rating': 5, 'title': 'Great', 'body': 'Lovely', 'status': 'APPROVED'},
        {'publicId': 'r2', 'rating': 4},
      ],
    });
    expect(s.averageRating, 4.5);
    expect(s.totalReviews, 2);
    expect(s.reviews.first.title, 'Great');
    expect(s.reviews[1].rating, 4);
  });

  test('Wishlist.fromJson parses items', () {
    final w = Wishlist.fromJson({
      'publicId': 'wl1',
      'itemCount': 1,
      'items': [
        {'publicId': 'i1', 'variantPublicId': 'v1', 'variantName': '250g', 'unitPrice': 499.0},
      ],
    });
    expect(w.itemCount, 1);
    expect(w.items.single.variantName, '250g');
    expect(w.items.single.unitPrice, 499.0);
  });

  test('CollectionDetail.fromJson parses products', () {
    final c = CollectionDetail.fromJson({
      'publicId': 'c1',
      'name': 'Wellness Teas',
      'slug': 'wellness-teas',
      'description': 'Calming blends.',
      'products': [
        {'publicId': 'p1', 'name': 'Tea', 'slug': 'tea', 'sku': 'T1', 'basePrice': 499.0, 'featured': false},
      ],
    });
    expect(c.name, 'Wellness Teas');
    expect(c.products.single.name, 'Tea');
  });
}
