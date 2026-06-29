import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../appconfig/data/app_config_repository.dart';
import '../models/shop_models.dart';
import '../state/cart_controller.dart';
import '../state/wishlist_controller.dart';
import 'shop_format.dart';

/// The signed-in user's saved products — move to cart or remove.
class WishlistScreen extends ConsumerWidget {
  const WishlistScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final wishlist = ref.watch(wishlistControllerProvider);
    final code = ref.watch(currentBrandingProvider).currencyCode;

    return Scaffold(
      appBar: AppBar(title: const Text('Wishlist')),
      body: wishlist.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('Could not load your wishlist.')),
        data: (w) => (w == null || w.items.isEmpty)
            ? _empty(context)
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: w.items.length,
                separatorBuilder: (_, __) => const Divider(height: 20),
                itemBuilder: (_, i) => _WishlistLine(item: w.items[i], code: code),
              ),
      ),
    );
  }

  Widget _empty(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.favorite_border_rounded, size: 56, color: scheme.primary.withValues(alpha: 0.5)),
          const SizedBox(height: 14),
          const Text('Your wishlist is empty', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
          const SizedBox(height: 14),
          FilledButton(onPressed: () => context.go('/shop'), child: const Text('Browse the Shop')),
        ],
      ),
    );
  }
}

class _WishlistLine extends ConsumerStatefulWidget {
  const _WishlistLine({required this.item, required this.code});
  final WishlistItem item;
  final String code;

  @override
  ConsumerState<_WishlistLine> createState() => _WishlistLineState();
}

class _WishlistLineState extends ConsumerState<_WishlistLine> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final it = widget.item;
    final scheme = Theme.of(context).colorScheme;
    final title = (it.productName != null && it.productName!.isNotEmpty) ? it.productName! : it.variantName;
    final hasVariant = it.productName != null && it.variantName.isNotEmpty && it.variantName != it.productName;
    return Row(
      children: [
        _thumb(scheme),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              if (hasVariant) ...[
                const SizedBox(height: 2),
                Text(it.variantName, style: TextStyle(fontSize: 12.5, color: scheme.onSurfaceVariant)),
              ],
              const SizedBox(height: 2),
              Text(formatMoney(it.unitPrice, widget.code),
                  style: TextStyle(fontSize: 13.5, color: scheme.primary, fontWeight: FontWeight.w700)),
            ],
          ),
        ),
        TextButton(onPressed: _busy ? null : _moveToCart, child: const Text('Move to cart')),
        IconButton(
          onPressed: _busy ? null : _remove,
          icon: const Icon(Icons.close_rounded),
          tooltip: 'Remove',
        ),
      ],
    );
  }

  Future<void> _moveToCart() async {
    setState(() => _busy = true);
    try {
      await ref.read(cartControllerProvider.notifier).add(widget.item.variantPublicId, 1);
      await ref.read(wishlistControllerProvider.notifier).remove(widget.item.publicId);
    } catch (_) {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _remove() async {
    setState(() => _busy = true);
    try {
      await ref.read(wishlistControllerProvider.notifier).remove(widget.item.publicId);
    } catch (_) {
      if (mounted) setState(() => _busy = false);
    }
  }

  Widget _thumb(ColorScheme scheme) {
    final url = widget.item.imageUrl;
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
        width: 56,
        height: 56,
        child: (url != null && url.isNotEmpty)
            ? Image.network(
                url,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _thumbPlaceholder(scheme),
              )
            : _thumbPlaceholder(scheme),
      ),
    );
  }

  Widget _thumbPlaceholder(ColorScheme scheme) => Container(
        color: scheme.primary.withValues(alpha: 0.10),
        child: Icon(Icons.shopping_bag_outlined, color: scheme.primary.withValues(alpha: 0.7)),
      );
}
