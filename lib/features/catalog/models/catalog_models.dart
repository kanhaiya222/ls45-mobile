import '../../../core/json/json_utils.dart';

/// Mirrors CategoryResponse (GET /api/v1/categories).
class Category {
  const Category({
    required this.publicId,
    required this.name,
    required this.slug,
    this.description,
    this.iconCode,
    this.sortOrder = 0,
    this.active = true,
    this.packageCount = 0,
  });

  final String publicId;
  final String name;
  final String slug;
  final String? description;
  final String? iconCode;
  final int sortOrder;
  final bool active;
  final int packageCount;

  factory Category.fromJson(Map<String, dynamic> json) => Category(
        publicId: asString(json['publicId']),
        name: asString(json['name']),
        slug: asString(json['slug']),
        description: asStringOrNull(json['description']),
        iconCode: asStringOrNull(json['iconCode']),
        sortOrder: asInt(json['sortOrder']),
        active: asBool(json['active'], true),
        packageCount: asInt(json['packageCount']),
      );
}

/// Mirrors PackageListResponse (GET /api/v1/packages).
class PackageSummary {
  const PackageSummary({
    required this.publicId,
    required this.name,
    required this.slug,
    this.shortDescription,
    this.heroImageUrl,
    this.thumbnailUrl,
    this.basePrice,
    this.currency,
    this.durationDays = 0,
    this.durationNights = 0,
    this.difficulty,
    this.featured = false,
    this.status,
    this.categoryName,
  });

  final String publicId;
  final String name;
  final String slug;
  final String? shortDescription;
  final String? heroImageUrl;
  final String? thumbnailUrl;
  final double? basePrice;
  final String? currency;
  final int durationDays;
  final int durationNights;
  final String? difficulty;
  final bool featured;
  final String? status;
  final String? categoryName;

  factory PackageSummary.fromJson(Map<String, dynamic> json) => PackageSummary(
        publicId: asString(json['publicId']),
        name: asString(json['name']),
        slug: asString(json['slug']),
        shortDescription: asStringOrNull(json['shortDescription']),
        heroImageUrl: asStringOrNull(json['heroImageUrl']),
        thumbnailUrl: asStringOrNull(json['thumbnailUrl']),
        basePrice: asDoubleOrNull(json['basePrice']),
        currency: asStringOrNull(json['currency']),
        durationDays: asInt(json['durationDays']),
        durationNights: asInt(json['durationNights']),
        difficulty: asStringOrNull(json['difficulty']),
        featured: asBool(json['featured']),
        status: asStringOrNull(json['status']),
        categoryName: asStringOrNull(json['categoryName']),
      );
}

/// Mirrors PackageMediaResponse.
class PackageMedia {
  const PackageMedia({
    required this.publicId,
    required this.url,
    this.mediaType,
    this.altText,
    this.sortOrder = 0,
    this.primary = false,
  });

  final String publicId;
  final String url;
  final String? mediaType;
  final String? altText;
  final int sortOrder;
  final bool primary;

  factory PackageMedia.fromJson(Map<String, dynamic> json) => PackageMedia(
        publicId: asString(json['publicId']),
        url: asString(json['url']),
        mediaType: asStringOrNull(json['mediaType']),
        altText: asStringOrNull(json['altText']),
        sortOrder: asInt(json['sortOrder']),
        primary: asBool(json['primary']),
      );
}

/// Mirrors PackageDetailResponse (GET /api/v1/packages/{publicId}).
class PackageDetail {
  const PackageDetail({
    required this.publicId,
    required this.name,
    required this.slug,
    this.shortDescription,
    this.description,
    this.heroImageUrl,
    this.thumbnailUrl,
    this.basePrice,
    this.currencyCode,
    this.durationDays = 0,
    this.durationNights = 0,
    this.maxGroupSize,
    this.minGroupSize,
    this.difficulty,
    this.meetingLocation,
    this.endLocation,
    this.featured = false,
    this.categoryName,
    this.inclusions,
    this.exclusions,
    this.highlights,
    this.media = const [],
    this.taggedProducts = const [],
  });

  final String publicId;
  final String name;
  final String slug;
  final String? shortDescription;
  final String? description;
  final String? heroImageUrl;
  final String? thumbnailUrl;
  final double? basePrice;
  final String? currencyCode;
  final int durationDays;
  final int durationNights;
  final int? maxGroupSize;
  final int? minGroupSize;
  final String? difficulty;
  final String? meetingLocation;
  final String? endLocation;
  final bool featured;
  final String? categoryName;
  final List<String>? inclusions;
  final List<String>? exclusions;
  final List<String>? highlights;
  final List<PackageMedia> media;

  /// "Shop this journey" — commerce products cross-sold on this package's detail page.
  final List<TaggedProduct> taggedProducts;

  factory PackageDetail.fromJson(Map<String, dynamic> json) => PackageDetail(
        publicId: asString(json['publicId']),
        name: asString(json['name']),
        slug: asString(json['slug']),
        shortDescription: asStringOrNull(json['shortDescription']),
        description: asStringOrNull(json['description']),
        heroImageUrl: asStringOrNull(json['heroImageUrl']),
        thumbnailUrl: asStringOrNull(json['thumbnailUrl']),
        basePrice: asDoubleOrNull(json['basePrice']),
        currencyCode: asStringOrNull(json['currencyCode']),
        durationDays: asInt(json['durationDays']),
        durationNights: asInt(json['durationNights']),
        maxGroupSize: asIntOrNull(json['maxGroupSize']),
        minGroupSize: asIntOrNull(json['minGroupSize']),
        difficulty: asStringOrNull(json['difficulty']),
        meetingLocation: asStringOrNull(json['meetingLocation']),
        endLocation: asStringOrNull(json['endLocation']),
        featured: asBool(json['featured']),
        categoryName: asStringOrNull(json['categoryName']),
        inclusions: asStringListOrNull(json['inclusions']),
        exclusions: asStringListOrNull(json['exclusions']),
        highlights: asStringListOrNull(json['highlights']),
        media: asModelList(json['media'], PackageMedia.fromJson),
        taggedProducts: asModelList(json['taggedProducts'], TaggedProduct.fromJson),
      );
}

/// Mirrors TaggedProductResponse — a Shop product surfaced on a package detail page.
class TaggedProduct {
  const TaggedProduct({
    required this.publicId,
    required this.name,
    this.slug,
    this.shortDescription,
    this.heroImageUrl,
    this.thumbnailUrl,
    this.basePrice,
    this.currencyCode,
  });

  final String publicId;
  final String name;
  final String? slug;
  final String? shortDescription;
  final String? heroImageUrl;
  final String? thumbnailUrl;
  final double? basePrice;
  final String? currencyCode;

  factory TaggedProduct.fromJson(Map<String, dynamic> json) => TaggedProduct(
        publicId: asString(json['publicId']),
        name: asString(json['name']),
        slug: asStringOrNull(json['slug']),
        shortDescription: asStringOrNull(json['shortDescription']),
        heroImageUrl: asStringOrNull(json['heroImageUrl']),
        thumbnailUrl: asStringOrNull(json['thumbnailUrl']),
        basePrice: asDoubleOrNull(json['basePrice']),
        currencyCode: asStringOrNull(json['currencyCode']),
      );
}

/// Mirrors DeparturePricingResponse.
class DeparturePricing {
  const DeparturePricing({
    required this.occupancyType,
    required this.price,
    this.currency,
    this.active = true,
  });

  final String occupancyType;
  final double price;
  final String? currency;
  final bool active;

  factory DeparturePricing.fromJson(Map<String, dynamic> json) => DeparturePricing(
        occupancyType: asString(json['occupancyType']),
        price: asDoubleOrNull(json['price']) ?? 0,
        currency: asStringOrNull(json['currency']),
        active: asBool(json['active'], true),
      );
}

/// Mirrors DepartureSummaryResponse (GET /api/v1/packages/{publicId}/availability).
class DepartureSummary {
  const DepartureSummary({
    required this.publicId,
    required this.packagePublicId,
    required this.startDate,
    required this.endDate,
    required this.status,
    this.totalCapacity = 0,
    this.availableSeats = 0,
    this.soldOut = false,
    this.bookingCutoffDate,
    this.pricing = const [],
  });

  final String publicId;
  final String packagePublicId;
  final String startDate;
  final String endDate;
  final String status;
  final int totalCapacity;
  final int availableSeats;
  final bool soldOut;
  final String? bookingCutoffDate;
  final List<DeparturePricing> pricing;

  /// Lowest active per-person price across occupancy options, if any.
  double? get priceFrom {
    final active = pricing.where((p) => p.active).map((p) => p.price);
    if (active.isEmpty) return null;
    return active.reduce((a, b) => a < b ? a : b);
  }

  factory DepartureSummary.fromJson(Map<String, dynamic> json) => DepartureSummary(
        publicId: asString(json['publicId']),
        packagePublicId: asString(json['packagePublicId']),
        startDate: asString(json['startDate']),
        endDate: asString(json['endDate']),
        status: asString(json['status']),
        totalCapacity: asInt(json['totalCapacity']),
        availableSeats: asInt(json['availableSeats']),
        soldOut: asBool(json['soldOut']),
        bookingCutoffDate: asStringOrNull(json['bookingCutoffDate']),
        pricing: asModelList(json['pricing'], DeparturePricing.fromJson),
      );
}

/// Mirrors FaqResponse (GET /api/v1/packages/{publicId}/faqs).
class Faq {
  const Faq({required this.question, required this.answer, this.publicId});

  final String? publicId;
  final String question;
  final String answer;

  factory Faq.fromJson(Map<String, dynamic> json) => Faq(
        publicId: asStringOrNull(json['publicId']),
        question: asString(json['question']),
        answer: asString(json['answer']),
      );
}

/// Mirrors ItineraryActivityResponse.
class ItineraryActivity {
  const ItineraryActivity({
    required this.publicId,
    required this.title,
    this.description,
    this.activityType,
    this.startTime,
    this.endTime,
    this.durationMinutes,
    this.optional = false,
    this.free = true,
  });

  final String publicId;
  final String title;
  final String? description;
  final String? activityType;
  final String? startTime;
  final String? endTime;
  final int? durationMinutes;
  final bool optional;
  final bool free;

  factory ItineraryActivity.fromJson(Map<String, dynamic> json) => ItineraryActivity(
        publicId: asString(json['publicId']),
        title: asString(json['title']),
        description: asStringOrNull(json['description']),
        activityType: asStringOrNull(json['activityType']),
        startTime: asStringOrNull(json['startTime']),
        endTime: asStringOrNull(json['endTime']),
        durationMinutes: asIntOrNull(json['durationMinutes']),
        optional: asBool(json['optional']),
        free: asBool(json['free'], true),
      );
}

/// Mirrors ItineraryDayResponse.
class ItineraryDay {
  const ItineraryDay({
    required this.publicId,
    required this.dayNumber,
    this.title,
    this.description,
    this.location,
    this.activities = const [],
  });

  final String publicId;
  final int dayNumber;
  final String? title;
  final String? description;
  final String? location;
  final List<ItineraryActivity> activities;

  factory ItineraryDay.fromJson(Map<String, dynamic> json) => ItineraryDay(
        publicId: asString(json['publicId']),
        dayNumber: asInt(json['dayNumber']),
        title: asStringOrNull(json['title']),
        description: asStringOrNull(json['description']),
        location: asStringOrNull(json['location']),
        activities: asModelList(json['activities'], ItineraryActivity.fromJson),
      );
}

/// Mirrors ItineraryResponse (GET /api/v1/packages/{publicId}/itinerary).
class Itinerary {
  const Itinerary({
    required this.publicId,
    required this.packagePublicId,
    this.label,
    this.days = const [],
  });

  final String publicId;
  final String packagePublicId;
  final String? label;
  final List<ItineraryDay> days;

  factory Itinerary.fromJson(Map<String, dynamic> json) => Itinerary(
        publicId: asString(json['publicId']),
        packagePublicId: asString(json['packagePublicId']),
        label: asStringOrNull(json['label']),
        days: asModelList(json['days'], ItineraryDay.fromJson),
      );
}
