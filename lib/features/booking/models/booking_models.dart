import '../../../core/json/json_utils.dart';

/// Mirrors BookingItemResponse.
class BookingItem {
  const BookingItem({
    required this.publicId,
    required this.itemType,
    required this.name,
    this.unitPrice,
    this.quantity = 1,
    this.totalPrice,
  });

  final String publicId;
  final String itemType;
  final String name;
  final double? unitPrice;
  final int quantity;
  final double? totalPrice;

  factory BookingItem.fromJson(Map<String, dynamic> json) => BookingItem(
        publicId: asString(json['publicId']),
        itemType: asString(json['itemType']),
        name: asString(json['name']),
        unitPrice: asDoubleOrNull(json['unitPrice']),
        quantity: asInt(json['quantity'], 1),
        totalPrice: asDoubleOrNull(json['totalPrice']),
      );
}

/// Mirrors BookingResponse (GET /api/v1/bookings, POST /api/v1/booking-drafts/{id}/confirm).
class Booking {
  const Booking({
    required this.publicId,
    required this.bookingReference,
    required this.status,
    required this.occupancyType,
    this.departureId = 0,
    this.numTravellers = 1,
    this.basePrice,
    this.addonTotal,
    this.taxAmount,
    this.totalPrice,
    this.currencyCode,
    this.confirmedAt,
    this.cancelledAt,
    this.cancellationReason,
    this.items = const [],
    this.createdAt,
  });

  final String publicId;
  final String bookingReference;
  final String status;
  final String occupancyType;
  final int departureId;
  final int numTravellers;
  final double? basePrice;
  final double? addonTotal;
  final double? taxAmount;
  final double? totalPrice;
  final String? currencyCode;
  final String? confirmedAt;
  final String? cancelledAt;
  final String? cancellationReason;
  final List<BookingItem> items;
  final String? createdAt;

  bool get isConfirmed => status == 'CONFIRMED';
  bool get isCancelled => status == 'CANCELLED';
  bool get isPendingPayment => status == 'PENDING_PAYMENT';

  factory Booking.fromJson(Map<String, dynamic> json) => Booking(
        publicId: asString(json['publicId']),
        bookingReference: asString(json['bookingReference']),
        status: asString(json['status']),
        occupancyType: asString(json['occupancyType']),
        departureId: asInt(json['departureId']),
        numTravellers: asInt(json['numTravellers'], 1),
        basePrice: asDoubleOrNull(json['basePrice']),
        addonTotal: asDoubleOrNull(json['addonTotal']),
        taxAmount: asDoubleOrNull(json['taxAmount']),
        totalPrice: asDoubleOrNull(json['totalPrice']),
        currencyCode: asStringOrNull(json['currencyCode']),
        confirmedAt: asStringOrNull(json['confirmedAt']),
        cancelledAt: asStringOrNull(json['cancelledAt']),
        cancellationReason: asStringOrNull(json['cancellationReason']),
        items: asModelList(json['items'], BookingItem.fromJson),
        createdAt: asStringOrNull(json['createdAt']),
      );
}
