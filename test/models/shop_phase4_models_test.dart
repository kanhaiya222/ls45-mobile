import 'package:flutter_test/flutter_test.dart';
import 'package:ls45_mobile/features/shop/models/shop_models.dart';

void main() {
  test('Shipment.fromJson parses carrier + tracking', () {
    final s = Shipment.fromJson(
        {'publicId': 's1', 'status': 'DELIVERED', 'carrier': 'Bluedart', 'trackingNumber': 'BD1'});
    expect(s.status, 'DELIVERED');
    expect(s.carrier, 'Bluedart');
    expect(s.trackingNumber, 'BD1');
  });

  test('TrackingEvent.fromJson parses status + description', () {
    final t = TrackingEvent.fromJson(
        {'status': 'IN_TRANSIT', 'location': 'Delhi', 'description': 'Left facility'});
    expect(t.status, 'IN_TRANSIT');
    expect(t.location, 'Delhi');
  });

  test('ReturnRequest.fromJson parses status + refund', () {
    final r = ReturnRequest.fromJson(
        {'publicId': 'r1', 'status': 'REQUESTED', 'reason': 'Changed mind', 'refundAmount': 499.0});
    expect(r.status, 'REQUESTED');
    expect(r.refundAmount, 499.0);
  });
}
