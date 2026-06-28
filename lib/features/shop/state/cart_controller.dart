import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../auth/state/auth_controller.dart';
import '../data/shop_repository.dart';
import '../models/shop_models.dart';

/// Holds the signed-in user's Shop cart. Reloads on auth changes; null when signed out.
class CartController extends AsyncNotifier<Cart?> {
  @override
  Future<Cart?> build() async {
    final signedIn = ref.watch(authControllerProvider).value != null;
    if (!signedIn) return null;
    try {
      return await ref.read(shopRepositoryProvider).getCart();
    } catch (_) {
      return null;
    }
  }

  Future<Cart> add(String variantPublicId, int quantity) async {
    final cart = await ref.read(shopRepositoryProvider).addItem(variantPublicId, quantity);
    state = AsyncData(cart);
    return cart;
  }

  Future<void> updateItem(String itemPublicId, int quantity) async {
    final cart = await ref.read(shopRepositoryProvider).updateItem(itemPublicId, quantity);
    state = AsyncData(cart);
  }

  Future<void> removeItem(String itemPublicId) async {
    final cart = await ref.read(shopRepositoryProvider).removeItem(itemPublicId);
    state = AsyncData(cart);
  }

  Future<void> refresh() async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(build);
  }

  /// Clear the local cart after a successful checkout (server already converted it).
  void clearLocal() => state = const AsyncData(null);
}

final cartControllerProvider =
    AsyncNotifierProvider<CartController, Cart?>(CartController.new);

/// Item count for the Shop tab badge (0 when signed out / loading).
final cartCountProvider = Provider<int>(
  (ref) => ref.watch(cartControllerProvider).value?.totalQuantity ?? 0,
);
