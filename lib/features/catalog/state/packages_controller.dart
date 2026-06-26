import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/catalog_repository.dart';
import '../models/catalog_models.dart';

/// Drives the catalog list: initial load, search, and append-style pagination.
class PackagesController extends AsyncNotifier<List<PackageSummary>> {
  int _page = 0;
  bool _last = true;
  String? _search;
  bool loadingMore = false;

  bool get hasMore => !_last;
  String? get currentSearch => _search;

  @override
  Future<List<PackageSummary>> build() => _fetchPage(0, null);

  Future<List<PackageSummary>> _fetchPage(int page, String? search) async {
    final res = await ref.read(catalogRepositoryProvider).listPackages(search: search, page: page);
    _page = res.page;
    _last = res.last;
    _search = search;
    return res.content;
  }

  Future<void> search(String? query) async {
    final q = (query == null || query.trim().isEmpty) ? null : query.trim();
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetchPage(0, q));
  }

  Future<void> refresh() => search(_search);

  Future<void> loadMore() async {
    if (_last || loadingMore || state.isLoading) return;
    loadingMore = true;
    try {
      final next = await _fetchPage(_page + 1, _search);
      state = AsyncData([...(state.value ?? const []), ...next]);
    } finally {
      loadingMore = false;
    }
  }
}

final packagesControllerProvider =
    AsyncNotifierProvider<PackagesController, List<PackageSummary>>(PackagesController.new);
