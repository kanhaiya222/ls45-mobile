import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/api_response.dart';
import '../../../core/network/dio_client.dart';
import '../models/shop_models.dart';

/// The Shop API: public product catalogue + the authenticated cart → checkout → order → payment
/// funnel (everything under /api/v1/me/* needs a signed-in session).
abstract interface class ShopRepository {
  Future<PageResponse<ProductSummary>> listProducts({int page = 0});
  Future<ProductDetail> productBySlug(String slug);
  Future<List<ShippingQuote>> shippingQuote(String country, int weightGrams, double subtotal);
  Future<Cart> getCart();
  Future<Cart> addItem(String variantPublicId, int quantity);
  Future<Cart> updateItem(String itemPublicId, int quantity);
  Future<Cart> removeItem(String itemPublicId);
  Future<Order> checkout(CheckoutRequest req);
  Future<PageResponse<OrderSummary>> listOrders({int page = 0});
  Future<Order> getOrder(String publicId);

  /// Initiate gateway payment. Throws ApiException(errorCode: PAYMENT_NOT_CONFIGURED) when off.
  Future<void> initiatePayment(String orderPublicId);

  Future<ReviewSummary> reviews(String slug);
  Future<void> submitReview(String productPublicId, int rating, String? title, String? body);
  Future<Wishlist> wishlist();
  Future<Wishlist> addToWishlist(String variantPublicId);
  Future<Wishlist> removeFromWishlist(String itemPublicId);
  Future<List<CollectionSummary>> collections();
  Future<CollectionDetail> collection(String slug);
}

class HttpShopRepository implements ShopRepository {
  HttpShopRepository(this._dio);

  final Dio _dio;

  List<T> _list<T>(dynamic data, T Function(Map<String, dynamic>) fromJson) =>
      (data as List).whereType<Map>().map((e) => fromJson(e.cast<String, dynamic>())).toList();

  @override
  Future<PageResponse<ProductSummary>> listProducts({int page = 0}) => _guard(() async {
        final res = await _dio.get<Map<String, dynamic>>('/products', queryParameters: {'page': page});
        return unwrap(
          res.data,
          (d) => PageResponse.fromJson((d as Map).cast<String, dynamic>(), ProductSummary.fromJson),
        );
      });

  @override
  Future<ProductDetail> productBySlug(String slug) => _guard(() async {
        final res = await _dio.get<Map<String, dynamic>>('/products/$slug');
        return unwrap(res.data, (d) => ProductDetail.fromJson((d as Map).cast<String, dynamic>()));
      });

  @override
  Future<List<ShippingQuote>> shippingQuote(String country, int weightGrams, double subtotal) =>
      _guard(() async {
        final res = await _dio.get<Map<String, dynamic>>('/shipping/quote', queryParameters: {
          'country': country,
          'weightGrams': weightGrams,
          'subtotal': subtotal,
        });
        return unwrap(res.data, (d) => _list(d, ShippingQuote.fromJson));
      });

  @override
  Future<Cart> getCart() => _guard(() async {
        final res = await _dio.get<Map<String, dynamic>>('/me/cart');
        return unwrap(res.data, (d) => Cart.fromJson((d as Map).cast<String, dynamic>()));
      });

  @override
  Future<Cart> addItem(String variantPublicId, int quantity) => _guard(() async {
        final res = await _dio.post<Map<String, dynamic>>('/me/cart/items',
            data: {'variantPublicId': variantPublicId, 'quantity': quantity});
        return unwrap(res.data, (d) => Cart.fromJson((d as Map).cast<String, dynamic>()));
      });

  @override
  Future<Cart> updateItem(String itemPublicId, int quantity) => _guard(() async {
        final res = await _dio.put<Map<String, dynamic>>('/me/cart/items/$itemPublicId',
            data: {'quantity': quantity});
        return unwrap(res.data, (d) => Cart.fromJson((d as Map).cast<String, dynamic>()));
      });

  @override
  Future<Cart> removeItem(String itemPublicId) => _guard(() async {
        final res = await _dio.delete<Map<String, dynamic>>('/me/cart/items/$itemPublicId');
        return unwrap(res.data, (d) => Cart.fromJson((d as Map).cast<String, dynamic>()));
      });

  @override
  Future<Order> checkout(CheckoutRequest req) => _guard(() async {
        final res = await _dio.post<Map<String, dynamic>>('/me/checkout', data: req.toJson());
        return unwrap(res.data, (d) => Order.fromJson((d as Map).cast<String, dynamic>()));
      });

  @override
  Future<PageResponse<OrderSummary>> listOrders({int page = 0}) => _guard(() async {
        final res = await _dio.get<Map<String, dynamic>>('/me/orders', queryParameters: {'page': page});
        return unwrap(
          res.data,
          (d) => PageResponse.fromJson((d as Map).cast<String, dynamic>(), OrderSummary.fromJson),
        );
      });

  @override
  Future<Order> getOrder(String publicId) => _guard(() async {
        final res = await _dio.get<Map<String, dynamic>>('/me/orders/$publicId');
        return unwrap(res.data, (d) => Order.fromJson((d as Map).cast<String, dynamic>()));
      });

  @override
  Future<void> initiatePayment(String orderPublicId) => _guard(() async {
        await _dio.post<Map<String, dynamic>>('/me/orders/$orderPublicId/payments/initiate');
      });

  @override
  Future<ReviewSummary> reviews(String slug) => _guard(() async {
        final res = await _dio.get<Map<String, dynamic>>('/products/$slug/reviews');
        return unwrap(res.data, (d) => ReviewSummary.fromJson((d as Map).cast<String, dynamic>()));
      });

  @override
  Future<void> submitReview(String productPublicId, int rating, String? title, String? body) =>
      _guard(() async {
        await _dio.post<Map<String, dynamic>>('/me/reviews', data: {
          'productPublicId': productPublicId,
          'rating': rating,
          if (title != null && title.isNotEmpty) 'title': title,
          if (body != null && body.isNotEmpty) 'body': body,
        });
      });

  @override
  Future<Wishlist> wishlist() => _guard(() async {
        final res = await _dio.get<Map<String, dynamic>>('/me/wishlist');
        return unwrap(res.data, (d) => Wishlist.fromJson((d as Map).cast<String, dynamic>()));
      });

  @override
  Future<Wishlist> addToWishlist(String variantPublicId) => _guard(() async {
        final res = await _dio.post<Map<String, dynamic>>('/me/wishlist/items',
            data: {'variantPublicId': variantPublicId});
        return unwrap(res.data, (d) => Wishlist.fromJson((d as Map).cast<String, dynamic>()));
      });

  @override
  Future<Wishlist> removeFromWishlist(String itemPublicId) => _guard(() async {
        final res = await _dio.delete<Map<String, dynamic>>('/me/wishlist/items/$itemPublicId');
        return unwrap(res.data, (d) => Wishlist.fromJson((d as Map).cast<String, dynamic>()));
      });

  @override
  Future<List<CollectionSummary>> collections() => _guard(() async {
        final res = await _dio.get<Map<String, dynamic>>('/product-collections');
        return unwrap(
          res.data,
          (d) => PageResponse.fromJson((d as Map).cast<String, dynamic>(), CollectionSummary.fromJson).content,
        );
      });

  @override
  Future<CollectionDetail> collection(String slug) => _guard(() async {
        final res = await _dio.get<Map<String, dynamic>>('/product-collections/$slug');
        return unwrap(res.data, (d) => CollectionDetail.fromJson((d as Map).cast<String, dynamic>()));
      });

  Future<T> _guard<T>(Future<T> Function() run) async {
    try {
      return await run();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}

final shopRepositoryProvider =
    Provider<ShopRepository>((ref) => HttpShopRepository(ref.watch(dioProvider)));
