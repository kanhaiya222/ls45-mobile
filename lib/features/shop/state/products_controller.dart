import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/shop_repository.dart';
import '../models/shop_models.dart';

/// Drives the Shop product grid: initial load + append-style pagination.
class ProductsController extends AsyncNotifier<List<ProductSummary>> {
  int _page = 0;
  bool _last = true;
  bool loadingMore = false;

  bool get hasMore => !_last;

  @override
  Future<List<ProductSummary>> build() => _fetchPage(0);

  Future<List<ProductSummary>> _fetchPage(int page) async {
    final res = await ref.read(shopRepositoryProvider).listProducts(page: page);
    _page = res.page;
    _last = res.last;
    return res.content;
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => _fetchPage(0));
  }

  Future<void> loadMore() async {
    if (_last || loadingMore || state.isLoading) return;
    loadingMore = true;
    try {
      final next = await _fetchPage(_page + 1);
      state = AsyncData([...(state.value ?? const []), ...next]);
    } finally {
      loadingMore = false;
    }
  }
}

final productsControllerProvider =
    AsyncNotifierProvider<ProductsController, List<ProductSummary>>(ProductsController.new);

/// Loads a single product's detail by slug (auto-disposed per slug).
final productDetailProvider = FutureProvider.autoDispose.family<ProductDetail, String>(
  (ref, slug) => ref.watch(shopRepositoryProvider).productBySlug(slug),
);
