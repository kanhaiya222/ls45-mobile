import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_exception.dart';
import '../../../shared/ui/app_ui.dart';
import '../../appconfig/data/app_config_repository.dart';
import '../models/shop_models.dart';
import '../state/products_controller.dart';
import 'shop_format.dart';

/// A Shop collection's products.
class CollectionDetailScreen extends ConsumerWidget {
  const CollectionDetailScreen({super.key, required this.slug});

  final String slug;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(collectionProvider(slug));
    return Scaffold(
      appBar: AppBar(title: Text(detail.value?.name ?? 'Collection')),
      body: detail.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Text(e is ApiException ? e.message : 'Could not load this collection.', textAlign: TextAlign.center),
          ),
        ),
        data: (c) => _content(context, ref, c),
      ),
    );
  }

  Widget _content(BuildContext context, WidgetRef ref, CollectionDetail c) {
    final code = ref.watch(currentBrandingProvider).currencyCode;
    return CustomScrollView(
      slivers: [
        if (c.description != null)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Text(c.description!, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, height: 1.5)),
            ),
          ),
        if (c.products.isEmpty)
          const SliverFillRemaining(
            hasScrollBody: false,
            child: Center(child: Text('No products in this collection yet.')),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.all(14),
            sliver: SliverGrid.builder(
              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                maxCrossAxisExtent: 230,
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                childAspectRatio: 0.72,
              ),
              itemCount: c.products.length,
              itemBuilder: (_, i) => _ProductTile(product: c.products[i], code: code),
            ),
          ),
      ],
    );
  }
}

class _ProductTile extends StatelessWidget {
  const _ProductTile({required this.product, required this.code});
  final ProductSummary product;
  final String code;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
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
                AspectRatio(aspectRatio: 1, child: NetworkImageFade(url: product.thumbnailUrl)),
                Padding(
                  padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(product.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700, height: 1.2)),
                      const SizedBox(height: 6),
                      Text(formatMoney(product.basePrice, code),
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: scheme.primary)),
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
