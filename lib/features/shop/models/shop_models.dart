import '../../../core/json/json_utils.dart';

/// Mirrors ProductListResponse (GET /api/v1/products).
class ProductSummary {
  const ProductSummary({
    required this.publicId,
    required this.name,
    required this.slug,
    required this.sku,
    this.status,
    this.productType,
    this.basePrice,
    this.currencyCode,
    this.thumbnailUrl,
    this.featured = false,
  });

  final String publicId;
  final String name;
  final String slug;
  final String sku;
  final String? status;
  final String? productType;
  final double? basePrice;
  final String? currencyCode;
  final String? thumbnailUrl;
  final bool featured;

  factory ProductSummary.fromJson(Map<String, dynamic> json) => ProductSummary(
        publicId: asString(json['publicId']),
        name: asString(json['name']),
        slug: asString(json['slug']),
        sku: asString(json['sku']),
        status: asStringOrNull(json['status']),
        productType: asStringOrNull(json['productType']),
        basePrice: asDoubleOrNull(json['basePrice']),
        currencyCode: asStringOrNull(json['currencyCode']),
        thumbnailUrl: asStringOrNull(json['thumbnailUrl']),
        featured: asBool(json['featured']),
      );
}

/// Mirrors ProductVariantResponse.
class ProductVariant {
  const ProductVariant({
    required this.publicId,
    required this.sku,
    required this.variantName,
    this.attributes,
    this.priceOverride,
    this.effectivePrice,
    this.sortOrder = 0,
    this.active = true,
  });

  final String publicId;
  final String sku;
  final String variantName;
  final String? attributes;
  final double? priceOverride;
  final double? effectivePrice;
  final int sortOrder;
  final bool active;

  double? get price => effectivePrice ?? priceOverride;

  factory ProductVariant.fromJson(Map<String, dynamic> json) => ProductVariant(
        publicId: asString(json['publicId']),
        sku: asString(json['sku']),
        variantName: asString(json['variantName']),
        attributes: asStringOrNull(json['attributes']),
        priceOverride: asDoubleOrNull(json['priceOverride']),
        effectivePrice: asDoubleOrNull(json['effectivePrice']),
        sortOrder: asInt(json['sortOrder']),
        active: asBool(json['active'], true),
      );
}

/// Mirrors ProductMediaResponse.
class ProductMedia {
  const ProductMedia({required this.publicId, required this.url, this.altText, this.primary = false});

  final String publicId;
  final String url;
  final String? altText;
  final bool primary;

  factory ProductMedia.fromJson(Map<String, dynamic> json) => ProductMedia(
        publicId: asString(json['publicId']),
        url: asString(json['url']),
        altText: asStringOrNull(json['altText']),
        primary: asBool(json['primary']),
      );
}

/// Mirrors ProductDetailResponse (GET /api/v1/products/{slug}).
class ProductDetail {
  const ProductDetail({
    required this.publicId,
    required this.name,
    required this.slug,
    required this.sku,
    this.shortDescription,
    this.description,
    this.basePrice,
    this.currencyCode,
    this.heroImageUrl,
    this.thumbnailUrl,
    this.featured = false,
    this.variants = const [],
    this.media = const [],
  });

  final String publicId;
  final String name;
  final String slug;
  final String sku;
  final String? shortDescription;
  final String? description;
  final double? basePrice;
  final String? currencyCode;
  final String? heroImageUrl;
  final String? thumbnailUrl;
  final bool featured;
  final List<ProductVariant> variants;
  final List<ProductMedia> media;

  List<ProductVariant> get activeVariants => variants.where((v) => v.active).toList();

  String? get image {
    if (heroImageUrl != null && heroImageUrl!.isNotEmpty) return heroImageUrl;
    if (media.isNotEmpty) return media.first.url;
    return thumbnailUrl;
  }

  factory ProductDetail.fromJson(Map<String, dynamic> json) => ProductDetail(
        publicId: asString(json['publicId']),
        name: asString(json['name']),
        slug: asString(json['slug']),
        sku: asString(json['sku']),
        shortDescription: asStringOrNull(json['shortDescription']),
        description: asStringOrNull(json['description']),
        basePrice: asDoubleOrNull(json['basePrice']),
        currencyCode: asStringOrNull(json['currencyCode']),
        heroImageUrl: asStringOrNull(json['heroImageUrl']),
        thumbnailUrl: asStringOrNull(json['thumbnailUrl']),
        featured: asBool(json['featured']),
        variants: asModelList(json['variants'], ProductVariant.fromJson),
        media: asModelList(json['media'], ProductMedia.fromJson),
      );
}

/// Mirrors CartItemResponse.
class CartItem {
  const CartItem({
    required this.publicId,
    required this.variantPublicId,
    required this.variantName,
    required this.quantity,
    required this.unitPrice,
    required this.lineTotal,
  });

  final String publicId;
  final String variantPublicId;
  final String variantName;
  final int quantity;
  final double unitPrice;
  final double lineTotal;

  factory CartItem.fromJson(Map<String, dynamic> json) => CartItem(
        publicId: asString(json['publicId']),
        variantPublicId: asString(json['variantPublicId']),
        variantName: asString(json['variantName']),
        quantity: asInt(json['quantity']),
        unitPrice: asDoubleOrNull(json['unitPrice']) ?? 0,
        lineTotal: asDoubleOrNull(json['lineTotal']) ?? 0,
      );
}

/// Mirrors CartResponse (GET /api/v1/me/cart).
class Cart {
  const Cart({
    required this.publicId,
    this.currencyCode,
    this.items = const [],
    this.totalQuantity = 0,
    this.subtotal = 0,
  });

  final String publicId;
  final String? currencyCode;
  final List<CartItem> items;
  final int totalQuantity;
  final double subtotal;

  factory Cart.fromJson(Map<String, dynamic> json) => Cart(
        publicId: asString(json['publicId']),
        currencyCode: asStringOrNull(json['currencyCode']),
        items: asModelList(json['items'], CartItem.fromJson),
        totalQuantity: asInt(json['totalQuantity']),
        subtotal: asDoubleOrNull(json['subtotal']) ?? 0,
      );
}

/// Mirrors ShippingQuoteResponse (GET /api/v1/shipping/quote).
class ShippingQuote {
  const ShippingQuote({
    required this.methodPublicId,
    required this.methodName,
    this.carrier,
    this.price = 0,
    this.free = false,
  });

  final String methodPublicId;
  final String methodName;
  final String? carrier;
  final double price;
  final bool free;

  factory ShippingQuote.fromJson(Map<String, dynamic> json) => ShippingQuote(
        methodPublicId: asString(json['methodPublicId']),
        methodName: asString(json['methodName']),
        carrier: asStringOrNull(json['carrier']),
        price: asDoubleOrNull(json['price']) ?? 0,
        free: asBool(json['free']),
      );
}

/// Mirrors OrderItemResponse.
class OrderItem {
  const OrderItem({
    required this.publicId,
    required this.name,
    required this.sku,
    required this.unitPrice,
    required this.quantity,
    required this.lineTotal,
  });

  final String publicId;
  final String name;
  final String sku;
  final double unitPrice;
  final int quantity;
  final double lineTotal;

  factory OrderItem.fromJson(Map<String, dynamic> json) => OrderItem(
        publicId: asString(json['publicId']),
        name: asString(json['name']),
        sku: asString(json['sku']),
        unitPrice: asDoubleOrNull(json['unitPrice']) ?? 0,
        quantity: asInt(json['quantity']),
        lineTotal: asDoubleOrNull(json['lineTotal']) ?? 0,
      );
}

/// Mirrors OrderListResponse (GET /api/v1/me/orders).
class OrderSummary {
  const OrderSummary({
    required this.publicId,
    required this.orderNumber,
    required this.status,
    this.grandTotal = 0,
    this.currencyCode,
    this.placedAt,
    this.itemCount = 0,
  });

  final String publicId;
  final String orderNumber;
  final String status;
  final double grandTotal;
  final String? currencyCode;
  final String? placedAt;
  final int itemCount;

  factory OrderSummary.fromJson(Map<String, dynamic> json) => OrderSummary(
        publicId: asString(json['publicId']),
        orderNumber: asString(json['orderNumber']),
        status: asString(json['status']),
        grandTotal: asDoubleOrNull(json['grandTotal']) ?? 0,
        currencyCode: asStringOrNull(json['currencyCode']),
        placedAt: asStringOrNull(json['placedAt']),
        itemCount: asInt(json['itemCount']),
      );
}

/// Mirrors OrderResponse (GET /api/v1/me/orders/{id} + checkout result).
class Order {
  const Order({
    required this.publicId,
    required this.orderNumber,
    required this.status,
    this.currencyCode,
    this.itemSubtotal = 0,
    this.shippingTotal = 0,
    this.taxTotal = 0,
    this.discountTotal = 0,
    this.grandTotal = 0,
    this.shippingMethodName,
    this.shipName,
    this.shipCity,
    this.items = const [],
  });

  final String publicId;
  final String orderNumber;
  final String status;
  final String? currencyCode;
  final double itemSubtotal;
  final double shippingTotal;
  final double taxTotal;
  final double discountTotal;
  final double grandTotal;
  final String? shippingMethodName;
  final String? shipName;
  final String? shipCity;
  final List<OrderItem> items;

  factory Order.fromJson(Map<String, dynamic> json) => Order(
        publicId: asString(json['publicId']),
        orderNumber: asString(json['orderNumber']),
        status: asString(json['status']),
        currencyCode: asStringOrNull(json['currencyCode']),
        itemSubtotal: asDoubleOrNull(json['itemSubtotal']) ?? 0,
        shippingTotal: asDoubleOrNull(json['shippingTotal']) ?? 0,
        taxTotal: asDoubleOrNull(json['taxTotal']) ?? 0,
        discountTotal: asDoubleOrNull(json['discountTotal']) ?? 0,
        grandTotal: asDoubleOrNull(json['grandTotal']) ?? 0,
        shippingMethodName: asStringOrNull(json['shippingMethodName']),
        shipName: asStringOrNull(json['shipName']),
        shipCity: asStringOrNull(json['shipCity']),
        items: asModelList(json['items'], OrderItem.fromJson),
      );
}

/// Mirrors ReviewResponse.
class Review {
  const Review({required this.publicId, required this.rating, this.title, this.body, this.status});

  final String publicId;
  final int rating;
  final String? title;
  final String? body;
  final String? status;

  factory Review.fromJson(Map<String, dynamic> json) => Review(
        publicId: asString(json['publicId']),
        rating: asInt(json['rating']),
        title: asStringOrNull(json['title']),
        body: asStringOrNull(json['body']),
        status: asStringOrNull(json['status']),
      );
}

/// Mirrors ReviewSummaryResponse (GET /products/{slug}/reviews).
class ReviewSummary {
  const ReviewSummary({this.averageRating = 0, this.totalReviews = 0, this.reviews = const []});

  final double averageRating;
  final int totalReviews;
  final List<Review> reviews;

  factory ReviewSummary.fromJson(Map<String, dynamic> json) => ReviewSummary(
        averageRating: asDoubleOrNull(json['averageRating']) ?? 0,
        totalReviews: asInt(json['totalReviews']),
        reviews: asModelList(json['reviews'], Review.fromJson),
      );
}

/// Mirrors WishlistItemResponse.
class WishlistItem {
  const WishlistItem({
    required this.publicId,
    required this.variantPublicId,
    required this.variantName,
    this.unitPrice,
  });

  final String publicId;
  final String variantPublicId;
  final String variantName;
  final double? unitPrice;

  factory WishlistItem.fromJson(Map<String, dynamic> json) => WishlistItem(
        publicId: asString(json['publicId']),
        variantPublicId: asString(json['variantPublicId']),
        variantName: asString(json['variantName']),
        unitPrice: asDoubleOrNull(json['unitPrice']),
      );
}

/// Mirrors WishlistResponse (GET /me/wishlist).
class Wishlist {
  const Wishlist({required this.publicId, this.itemCount = 0, this.items = const []});

  final String publicId;
  final int itemCount;
  final List<WishlistItem> items;

  factory Wishlist.fromJson(Map<String, dynamic> json) => Wishlist(
        publicId: asString(json['publicId']),
        itemCount: asInt(json['itemCount']),
        items: asModelList(json['items'], WishlistItem.fromJson),
      );
}

/// Mirrors CollectionListResponse (GET /product-collections).
class CollectionSummary {
  const CollectionSummary({required this.publicId, required this.name, required this.slug, this.thumbnailUrl});

  final String publicId;
  final String name;
  final String slug;
  final String? thumbnailUrl;

  factory CollectionSummary.fromJson(Map<String, dynamic> json) => CollectionSummary(
        publicId: asString(json['publicId']),
        name: asString(json['name']),
        slug: asString(json['slug']),
        thumbnailUrl: asStringOrNull(json['thumbnailUrl']),
      );
}

/// Mirrors CollectionDetailResponse (GET /product-collections/{slug}).
class CollectionDetail {
  const CollectionDetail({
    required this.publicId,
    required this.name,
    required this.slug,
    this.description,
    this.heroImageUrl,
    this.products = const [],
  });

  final String publicId;
  final String name;
  final String slug;
  final String? description;
  final String? heroImageUrl;
  final List<ProductSummary> products;

  factory CollectionDetail.fromJson(Map<String, dynamic> json) => CollectionDetail(
        publicId: asString(json['publicId']),
        name: asString(json['name']),
        slug: asString(json['slug']),
        description: asStringOrNull(json['description']),
        heroImageUrl: asStringOrNull(json['heroImageUrl']),
        products: asModelList(json['products'], ProductSummary.fromJson),
      );
}

/// Checkout request body (POST /api/v1/me/checkout).
class CheckoutRequest {
  const CheckoutRequest({
    required this.shippingMethodPublicId,
    required this.shipName,
    required this.shipPhone,
    required this.shipLine1,
    required this.shipCity,
    required this.shipCountry,
    this.shipLine2,
    this.shipState,
    this.shipPostalCode,
    this.couponCode,
  });

  final String shippingMethodPublicId;
  final String shipName;
  final String shipPhone;
  final String shipLine1;
  final String? shipLine2;
  final String shipCity;
  final String? shipState;
  final String? shipPostalCode;
  final String shipCountry;
  final String? couponCode;

  Map<String, dynamic> toJson() => {
        'shippingMethodPublicId': shippingMethodPublicId,
        'shipName': shipName,
        'shipPhone': shipPhone,
        'shipLine1': shipLine1,
        if (shipLine2 != null && shipLine2!.isNotEmpty) 'shipLine2': shipLine2,
        'shipCity': shipCity,
        if (shipState != null && shipState!.isNotEmpty) 'shipState': shipState,
        if (shipPostalCode != null && shipPostalCode!.isNotEmpty) 'shipPostalCode': shipPostalCode,
        'shipCountry': shipCountry,
        if (couponCode != null && couponCode!.isNotEmpty) 'couponCode': couponCode,
      };
}
