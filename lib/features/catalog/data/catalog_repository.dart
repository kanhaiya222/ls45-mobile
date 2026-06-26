import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_exception.dart';
import '../../../core/network/api_response.dart';
import '../../../core/network/dio_client.dart';
import '../models/catalog_models.dart';

/// Read access to the public catalog (packages, categories, detail, availability, itinerary, FAQs).
abstract interface class CatalogRepository {
  Future<PageResponse<PackageSummary>> listPackages({String? search, int page = 0});
  Future<List<Category>> listCategories();
  Future<PackageDetail> packageBySlug(String slug);
  Future<List<DepartureSummary>> availability(String packagePublicId);
  Future<Itinerary?> itinerary(String packagePublicId);
  Future<List<Faq>> faqs(String packagePublicId);
}

class HttpCatalogRepository implements CatalogRepository {
  HttpCatalogRepository(this._dio);

  final Dio _dio;

  List<T> _list<T>(dynamic data, T Function(Map<String, dynamic>) fromJson) =>
      (data as List).whereType<Map>().map((e) => fromJson(e.cast<String, dynamic>())).toList();

  @override
  Future<PageResponse<PackageSummary>> listPackages({String? search, int page = 0}) =>
      _guard(() async {
        final res = await _dio.get<Map<String, dynamic>>('/packages', queryParameters: {
          'page': page,
          if (search != null && search.isNotEmpty) 'search': search,
        });
        return unwrap(
          res.data,
          (d) => PageResponse.fromJson((d as Map).cast<String, dynamic>(), PackageSummary.fromJson),
        );
      });

  @override
  Future<List<Category>> listCategories() => _guard(() async {
        final res = await _dio.get<Map<String, dynamic>>('/categories');
        return unwrap(res.data, (d) => _list(d, Category.fromJson));
      });

  @override
  Future<PackageDetail> packageBySlug(String slug) => _guard(() async {
        final res = await _dio.get<Map<String, dynamic>>('/packages/by-slug/$slug');
        return unwrap(res.data, (d) => PackageDetail.fromJson((d as Map).cast<String, dynamic>()));
      });

  @override
  Future<List<DepartureSummary>> availability(String packagePublicId) => _guard(() async {
        final res = await _dio.get<Map<String, dynamic>>('/packages/$packagePublicId/availability');
        return unwrap(res.data, (d) => _list(d, DepartureSummary.fromJson));
      });

  @override
  Future<Itinerary?> itinerary(String packagePublicId) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>('/packages/$packagePublicId/itinerary');
      final data = res.data?['data'];
      return data == null ? null : Itinerary.fromJson((data as Map).cast<String, dynamic>());
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) return null;
      throw ApiException.fromDio(e);
    }
  }

  @override
  Future<List<Faq>> faqs(String packagePublicId) => _guard(() async {
        final res = await _dio.get<Map<String, dynamic>>('/packages/$packagePublicId/faqs');
        return unwrap(res.data, (d) => _list(d, Faq.fromJson));
      });

  Future<T> _guard<T>(Future<T> Function() run) async {
    try {
      return await run();
    } on DioException catch (e) {
      throw ApiException.fromDio(e);
    }
  }
}

final catalogRepositoryProvider =
    Provider<CatalogRepository>((ref) => HttpCatalogRepository(ref.watch(dioProvider)));
