import 'package:ls45_mobile/core/network/api_exception.dart';
import 'package:ls45_mobile/core/network/api_response.dart';
import 'package:ls45_mobile/core/storage/key_value_store.dart';
import 'package:ls45_mobile/features/auth/data/auth_repository.dart';
import 'package:ls45_mobile/features/auth/models/auth_models.dart';
import 'package:ls45_mobile/features/catalog/data/catalog_repository.dart';
import 'package:ls45_mobile/features/catalog/models/catalog_models.dart';

/// In-memory [KeyValueStore] for tests (no platform channel).
class InMemoryKeyValueStore implements KeyValueStore {
  final Map<String, String> map = {};

  @override
  Future<String?> read(String key) async => map[key];

  @override
  Future<void> write(String key, String value) async => map[key] = value;

  @override
  Future<void> delete(String key) async => map.remove(key);
}

/// Configurable fake [AuthRepository] for controller/widget tests (no Dio/network).
class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({this.session});

  AuthUser? session;
  bool throwOnLogin = false;

  @override
  Future<AuthUser> login(String email, String password) async {
    if (throwOnLogin) {
      throw ApiException(statusCode: 401, message: 'Invalid credentials');
    }
    final user = AuthUser(
      publicId: 'u1',
      email: email,
      firstName: 'Test',
      lastName: 'User',
      roles: const ['CUSTOMER'],
    );
    session = user;
    return user;
  }

  @override
  Future<AuthUser> register({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    String? phoneNumber,
  }) async {
    final user = AuthUser(publicId: 'u2', email: email, firstName: firstName, lastName: lastName);
    session = user;
    return user;
  }

  @override
  Future<void> logout() async => session = null;

  @override
  Future<AuthUser?> restoreSession() async => session;
}

PackageSummary fakePackage(String name) => PackageSummary(
      publicId: name,
      name: name,
      slug: name.toLowerCase().replaceAll(' ', '-'),
      durationDays: 5,
      durationNights: 4,
      featured: false,
      basePrice: 10000,
    );

PackageDetail fakeDetail(String name) => PackageDetail(
      publicId: '$name-id',
      name: name,
      slug: name.toLowerCase().replaceAll(' ', '-'),
      durationDays: 7,
      durationNights: 6,
      basePrice: 45000,
      highlights: const ['Sunrise yoga', 'Meditation'],
    );

/// Fake [CatalogRepository] backed by an in-memory list, with simple search + paging.
class FakeCatalogRepository implements CatalogRepository {
  FakeCatalogRepository({
    List<PackageSummary>? all,
    this.pageSize = 2,
    this.detail,
    this.departures = const [],
    this.itin,
    this.faqList = const [],
  }) : all = all ?? const [];

  final List<PackageSummary> all;
  final int pageSize;
  final PackageDetail? detail;
  final List<DepartureSummary> departures;
  final Itinerary? itin;
  final List<Faq> faqList;

  @override
  Future<PageResponse<PackageSummary>> listPackages({String? search, int page = 0}) async {
    final filtered = search == null
        ? all
        : all.where((p) => p.name.toLowerCase().contains(search.toLowerCase())).toList();
    final start = page * pageSize;
    final slice = start >= filtered.length
        ? <PackageSummary>[]
        : filtered.sublist(start, (start + pageSize).clamp(0, filtered.length));
    return PageResponse(
      content: slice,
      page: page,
      size: pageSize,
      totalElements: filtered.length,
      totalPages: (filtered.length / pageSize).ceil(),
      first: page == 0,
      last: (start + pageSize) >= filtered.length,
    );
  }

  @override
  Future<List<Category>> listCategories() async => const [];

  @override
  Future<PackageDetail> packageBySlug(String slug) async =>
      detail ?? (throw UnimplementedError());

  @override
  Future<List<DepartureSummary>> availability(String packagePublicId) async => departures;

  @override
  Future<Itinerary?> itinerary(String packagePublicId) async => itin;

  @override
  Future<List<Faq>> faqs(String packagePublicId) async => faqList;
}
