import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/state/auth_controller.dart';
import '../data/shop_repository.dart';
import '../models/shop_models.dart';

/// Holds the signed-in user's wishlist. Reloads on auth changes; null when signed out.
class WishlistController extends AsyncNotifier<Wishlist?> {
  @override
  Future<Wishlist?> build() async {
    final signedIn = ref.watch(authControllerProvider).value != null;
    if (!signedIn) return null;
    try {
      return await ref.read(shopRepositoryProvider).wishlist();
    } catch (_) {
      return null;
    }
  }

  Future<void> add(String variantPublicId) async {
    final w = await ref.read(shopRepositoryProvider).addToWishlist(variantPublicId);
    state = AsyncData(w);
  }

  Future<void> remove(String itemPublicId) async {
    final w = await ref.read(shopRepositoryProvider).removeFromWishlist(itemPublicId);
    state = AsyncData(w);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(build);
  }
}

final wishlistControllerProvider =
    AsyncNotifierProvider<WishlistController, Wishlist?>(WishlistController.new);
