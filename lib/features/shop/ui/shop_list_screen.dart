import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_exception.dart';
import '../../../shared/ui/app_ui.dart';
import '../../appconfig/data/app_config_repository.dart';
import '../models/shop_models.dart';
import '../state/cart_controller.dart';
import '../state/products_controller.dart';
import 'shop_format.dart';

/// The Shop: a grid of published wellness products with pagination + a cart shortcut.
class ShopListScreen extends ConsumerWidget {
  const ShopListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final products = ref.watch(productsControllerProvider);
    final cartCount = ref.watch(cartCountProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Shop'),
        actions: [
          IconButton(
            tooltip: 'Wishlist',
            onPressed: () => context.push('/shop/wishlist'),
            icon: const Icon(Icons.favorite_border_rounded),
          ),
          IconButton(
            tooltip: 'Cart',
            onPressed: () => context.push('/shop/cart'),
            icon: Badge(
              isLabelVisible: cartCount > 0,
              label: Text('$cartCount'),
              child: const Icon(Icons.shopping_bag_outlined),
            ),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(productsControllerProvider.notifier).refresh(),
        child: products.when(
          loading: () => const _ShopSkeleton(),
          error: (e, _) => _ShopError(
            message: e is ApiException ? e.message : 'Could not load the Shop.',
            onRetry: () => ref.read(productsControllerProvider.notifier).refresh(),
          ),
          data: (items) => items.isEmpty
              ? const _ShopEmpty()
              : Column(
                  children: [
                    const _CollectionsRail(),
                    Expanded(child: _ProductGrid(items: items)),
                  ],
                ),
        ),
      ),
    );
  }
}

/// Horizontal "shop by collection" rail; hidden when there are no collections.
class _CollectionsRail extends ConsumerWidget {
  const _CollectionsRail();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final collections = ref.watch(collectionsProvider).value ?? const [];
    if (collections.isEmpty) {
      return const SizedBox.shrink();
    }
    final scheme = Theme.of(context).colorScheme;
    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        itemCount: collections.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final c = collections[i];
          return ActionChip(
            label: Text(c.name),
            backgroundColor: scheme.surface,
            side: BorderSide(color: scheme.outlineVariant),
            onPressed: () => context.push('/shop/collections/${c.slug}'),
          );
        },
      ),
    );
  }
}

class _ProductGrid extends ConsumerWidget {
  const _ProductGrid({required this.items});

  final List<ProductSummary> items;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(productsControllerProvider.notifier);
    final hasMore = controller.hasMore;
    return GridView.builder(
      padding: const EdgeInsets.all(14),
      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
        maxCrossAxisExtent: 230,
        mainAxisSpacing: 14,
        crossAxisSpacing: 14,
        childAspectRatio: 0.72,
      ),
      itemCount: items.length + (hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= items.length) {
          WidgetsBinding.instance.addPostFrameCallback((_) => controller.loadMore());
          return const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()));
        }
        return _ProductCard(product: items[index]);
      },
    );
  }
}

class _ProductCard extends ConsumerWidget {
  const _ProductCard({required this.product});

  final ProductSummary product;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final code = product.currencyCode ?? ref.watch(currentBrandingProvider).currencyCode;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(kRadiusLg),
        boxShadow: softShadow(context),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(kRadiusLg),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => context.push('/shop/${product.slug}'),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Stack(
                  children: [
                    AspectRatio(aspectRatio: 1, child: NetworkImageFade(url: product.thumbnailUrl)),
                    if (product.featured)
                      Positioned(
                        top: 10,
                        left: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.92),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Text('Featured',
                              style: TextStyle(
                                  fontSize: 10.5, fontWeight: FontWeight.w700, color: scheme.primary)),
                        ),
                      ),
                  ],
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, height: 1.2),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        formatMoney(product.basePrice, code),
                        style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: scheme.primary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ShopSkeleton extends StatelessWidget {
  const _ShopSkeleton();

  @override
  Widget build(BuildContext context) {
    return Shimmer(
      child: GridView.count(
        padding: const EdgeInsets.all(14),
        crossAxisCount: 2,
        mainAxisSpacing: 14,
        crossAxisSpacing: 14,
        childAspectRatio: 0.72,
        children: List.generate(
          6,
          (_) => const ShimmerBox(width: 999, height: 999, radius: kRadiusLg),
        ),
      ),
    );
  }
}

class _ShopEmpty extends StatelessWidget {
  const _ShopEmpty();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListView(
      children: [
        const SizedBox(height: 120),
        Icon(Icons.shopping_bag_outlined, size: 56, color: scheme.primary.withValues(alpha: 0.5)),
        const SizedBox(height: 16),
        Center(
          child: Text('The Shop is empty',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
        ),
        const SizedBox(height: 6),
        Center(
          child: Text('New wellness goods are on their way.',
              style: TextStyle(color: scheme.onSurfaceVariant)),
        ),
      ],
    );
  }
}

class _ShopError extends StatelessWidget {
  const _ShopError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListView(
      children: [
        const SizedBox(height: 120),
        Icon(Icons.cloud_off_rounded, size: 56, color: scheme.error.withValues(alpha: 0.7)),
        const SizedBox(height: 16),
        Center(
          child: Text('Something went wrong',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
        ),
        const SizedBox(height: 6),
        Center(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 32), child: Text(message, textAlign: TextAlign.center, style: TextStyle(color: scheme.onSurfaceVariant)))),
        const SizedBox(height: 18),
        Center(child: FilledButton.icon(onPressed: onRetry, icon: const Icon(Icons.refresh_rounded), label: const Text('Try again'))),
      ],
    );
  }
}
