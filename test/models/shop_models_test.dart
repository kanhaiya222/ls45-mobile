import 'package:flutter_test/flutter_test.dart';
import 'package:ls45_mobile/features/shop/models/shop_models.dart';

void main() {
  test('ProductDetail.fromJson parses variants + resolves image + active filter', () {
    final p = ProductDetail.fromJson({
      'publicId': 'prod-1',
      'name': 'Herbal Tea',
      'slug': 'herbal-tea',
      'sku': 'HHT-001',
      'basePrice': 499.0,
      'currencyCode': 'INR',
      'heroImageUrl': 'https://img/hero.jpg',
      'variants': [
        {'publicId': 'v1', 'sku': 'HHT-250', 'variantName': '250g', 'effectivePrice': 499.0, 'active': true},
        {'publicId': 'v2', 'sku': 'HHT-OLD', 'variantName': 'Discontinued', 'active': false},
      ],
    });

    expect(p.name, 'Herbal Tea');
    expect(p.image, 'https://img/hero.jpg');
    expect(p.variants.length, 2);
    expect(p.activeVariants.length, 1);
    expect(p.activeVariants.first.price, 499.0);
  });

  test('Cart.fromJson parses items + totals', () {
    final c = Cart.fromJson({
      'publicId': 'cart-1',
      'currencyCode': 'INR',
      'totalQuantity': 2,
      'subtotal': 998.0,
      'items': [
        {
          'publicId': 'ci-1',
          'variantPublicId': 'v1',
          'variantName': '250g',
          'quantity': 2,
          'unitPrice': 499.0,
          'lineTotal': 998.0,
        },
      ],
    });

    expect(c.totalQuantity, 2);
    expect(c.subtotal, 998.0);
    expect(c.items.single.variantName, '250g');
  });

  test('Order.fromJson parses totals + items', () {
    final o = Order.fromJson({
      'publicId': 'o-1',
      'orderNumber': 'ORD-2026-0001',
      'status': 'PENDING_PAYMENT',
      'itemSubtotal': 998.0,
      'shippingTotal': 99.0,
      'taxTotal': 49.9,
      'grandTotal': 1146.9,
      'items': [
        {'publicId': 'oi-1', 'name': 'Herbal Tea', 'sku': 'HHT-001', 'unitPrice': 499.0, 'quantity': 2, 'lineTotal': 998.0},
      ],
    });

    expect(o.orderNumber, 'ORD-2026-0001');
    expect(o.status, 'PENDING_PAYMENT');
    expect(o.grandTotal, 1146.9);
    expect(o.items.single.name, 'Herbal Tea');
  });

  test('CheckoutRequest.toJson omits blank optional fields', () {
    final json = const CheckoutRequest(
      shippingMethodPublicId: 'm1',
      shipName: 'A',
      shipPhone: '9',
      shipLine1: 'x',
      shipCity: 'y',
      shipCountry: 'IN',
      shipLine2: '',
      couponCode: 'SAVE10',
    ).toJson();

    expect(json['shippingMethodPublicId'], 'm1');
    expect(json.containsKey('shipLine2'), isFalse);
    expect(json['couponCode'], 'SAVE10');
  });

  test('ShippingQuote.fromJson parses free flag', () {
    final q = ShippingQuote.fromJson({'methodPublicId': 'm1', 'methodName': 'Standard', 'price': 99.0, 'free': false});
    expect(q.methodName, 'Standard');
    expect(q.free, isFalse);
    expect(q.price, 99.0);
  });
}
