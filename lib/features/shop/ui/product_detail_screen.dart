import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_exception.dart';
import '../../../shared/ui/app_ui.dart';
import '../../appconfig/data/app_config_repository.dart';
import '../../auth/state/auth_controller.dart';
import '../data/shop_repository.dart';
import '../models/shop_models.dart';
import '../state/cart_controller.dart';
import '../state/products_controller.dart';
import '../state/wishlist_controller.dart';
import 'shop_format.dart';

/// Product detail: gallery, description, variant picker, quantity stepper and add-to-cart.
class ProductDetailScreen extends ConsumerStatefulWidget {
  const ProductDetailScreen({super.key, required this.slug});

  final String slug;

  @override
  ConsumerState<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends ConsumerState<ProductDetailScreen> {
  String? _variantId;
  int _qty = 1;
  bool _adding = false;

  @override
  Widget build(BuildContext context) {
    final detail = ref.watch(productDetailProvider(widget.slug));
    return Scaffold(
      appBar: AppBar(title: const Text('Product')),
      body: detail.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => _Error(message: e is ApiException ? e.message : 'Could not load this product.'),
        data: (p) => _content(context, p),
      ),
    );
  }

  Widget _content(BuildContext context, ProductDetail p) {
    final scheme = Theme.of(context).colorScheme;
    final code = p.currencyCode ?? ref.watch(currentBrandingProvider).currencyCode;
    final variants = p.activeVariants;
    final selected = variants.where((v) => v.publicId == _variantId).firstOrNull ??
        (variants.isNotEmpty ? variants.first : null);
    final price = selected?.price ?? p.basePrice;

    return ListView(
      padding: EdgeInsets.zero,
      children: [
        AspectRatio(aspectRatio: 1, child: NetworkImageFade(url: p.image)),
        Padding(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(p.name, style: const TextStyle(fontSize: 23, fontWeight: FontWeight.w800, height: 1.2)),
              const SizedBox(height: 8),
              Text(formatMoney(price, code),
                  style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800, color: scheme.primary)),
              if (p.shortDescription != null) ...[
                const SizedBox(height: 14),
                Text(p.shortDescription!, style: TextStyle(fontSize: 15, height: 1.5, color: scheme.onSurfaceVariant)),
              ],
              if (variants.length > 1) ...[
                const SizedBox(height: 22),
                Text('Choose an option', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: variants.map((v) {
                    final isSel = selected?.publicId == v.publicId;
                    return ChoiceChip(
                      label: Text(v.variantName),
                      selected: isSel,
                      onSelected: (_) => setState(() => _variantId = v.publicId),
                    );
                  }).toList(),
                ),
              ],
              const SizedBox(height: 22),
              Row(
                children: [
                  _QtyStepper(
                    value: _qty,
                    onChanged: (v) => setState(() => _qty = v),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: (selected == null || _adding) ? null : () => _addToCart(p, selected),
                      icon: _adding
                          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.add_shopping_cart_rounded),
                      label: Text(_adding ? 'Adding…' : 'Add to cart'),
                      style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(50)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  IconButton.outlined(
                    onPressed: selected == null ? null : () => _addToWishlist(p, selected),
                    icon: const Icon(Icons.favorite_border_rounded),
                    tooltip: 'Save to wishlist',
                    style: IconButton.styleFrom(minimumSize: const Size(50, 50)),
                  ),
                ],
              ),
              if (selected == null)
                Padding(
                  padding: const EdgeInsets.only(top: 12),
                  child: Text('This product is not available to purchase right now.',
                      style: TextStyle(color: scheme.error)),
                ),
              if (p.description != null) ...[
                const SizedBox(height: 28),
                Text('Details', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Text(p.description!, style: const TextStyle(fontSize: 14.5, height: 1.6)),
              ],
              const SizedBox(height: 28),
              _ReviewsSection(slug: p.slug, productPublicId: p.publicId),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _addToWishlist(ProductDetail p, ProductVariant variant) async {
    final signedIn = ref.read(authControllerProvider).value != null;
    if (!signedIn) {
      if (mounted) context.push('/login');
      return;
    }
    try {
      await ref.read(wishlistControllerProvider.notifier).add(variant.publicId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${p.name} saved to wishlist'),
          action: SnackBarAction(label: 'View', onPressed: () => context.push('/shop/wishlist')),
        ),
      );
    } on ApiException catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
    }
  }

  Future<void> _addToCart(ProductDetail p, ProductVariant variant) async {
    final signedIn = ref.read(authControllerProvider).value != null;
    if (!signedIn) {
      if (mounted) context.push('/login');
      return;
    }
    setState(() => _adding = true);
    try {
      await ref.read(cartControllerProvider.notifier).add(variant.publicId, _qty);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${p.name} added to cart'),
          action: SnackBarAction(label: 'View cart', onPressed: () => context.push('/shop/cart')),
        ),
      );
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _adding = false);
    }
  }
}

class _QtyStepper extends StatelessWidget {
  const _QtyStepper({required this.value, required this.onChanged});

  final int value;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: scheme.outlineVariant),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            onPressed: value > 1 ? () => onChanged(value - 1) : null,
            icon: const Icon(Icons.remove_rounded),
            visualDensity: VisualDensity.compact,
          ),
          Text('$value', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
          IconButton(
            onPressed: () => onChanged(value + 1),
            icon: const Icon(Icons.add_rounded),
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }
}

class _Error extends StatelessWidget {
  const _Error({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(padding: const EdgeInsets.all(32), child: Text(message, textAlign: TextAlign.center)),
    );
  }
}

/// Reviews block: average + list, plus a write-a-review sheet for signed-in customers.
class _ReviewsSection extends ConsumerWidget {
  const _ReviewsSection({required this.slug, required this.productPublicId});

  final String slug;
  final String productPublicId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(productReviewsProvider(slug));
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Reviews', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            if (ref.watch(authControllerProvider).value != null)
              TextButton(onPressed: () => _openWrite(context, ref), child: const Text('Write a review')),
          ],
        ),
        const SizedBox(height: 8),
        summary.when(
          loading: () => const Padding(padding: EdgeInsets.all(8), child: LinearProgressIndicator()),
          error: (_, __) => Text('Could not load reviews.', style: TextStyle(color: scheme.onSurfaceVariant)),
          data: (s) => s.totalReviews == 0
              ? Text('No reviews yet — be the first.', style: TextStyle(color: scheme.onSurfaceVariant))
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      _Stars(rating: s.averageRating.round()),
                      const SizedBox(width: 8),
                      Text('${s.averageRating.toStringAsFixed(1)} · ${s.totalReviews} review${s.totalReviews == 1 ? '' : 's'}',
                          style: TextStyle(color: scheme.onSurfaceVariant)),
                    ]),
                    const SizedBox(height: 12),
                    ...s.reviews.map((r) => Padding(
                          padding: const EdgeInsets.only(bottom: 14),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _Stars(rating: r.rating, size: 14),
                              if (r.title != null) Text(r.title!, style: const TextStyle(fontWeight: FontWeight.w700)),
                              if (r.body != null) Text(r.body!, style: const TextStyle(height: 1.5)),
                            ],
                          ),
                        )),
                  ],
                ),
        ),
      ],
    );
  }

  void _openWrite(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _WriteReviewSheet(productPublicId: productPublicId, slug: slug),
    );
  }
}

class _Stars extends StatelessWidget {
  const _Stars({required this.rating, this.size = 18});
  final int rating;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        5,
        (i) => Icon(i < rating ? Icons.star_rounded : Icons.star_border_rounded,
            size: size, color: const Color(0xFFF5A623)),
      ),
    );
  }
}

class _WriteReviewSheet extends ConsumerStatefulWidget {
  const _WriteReviewSheet({required this.productPublicId, required this.slug});
  final String productPublicId;
  final String slug;

  @override
  ConsumerState<_WriteReviewSheet> createState() => _WriteReviewSheetState();
}

class _WriteReviewSheetState extends ConsumerState<_WriteReviewSheet> {
  int _rating = 5;
  final _title = TextEditingController();
  final _body = TextEditingController();
  bool _saving = false;

  @override
  void dispose() {
    _title.dispose();
    _body.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(20, 4, 20, MediaQuery.of(context).viewInsets.bottom + 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Write a review', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          Row(
            children: List.generate(
              5,
              (i) => IconButton(
                onPressed: () => setState(() => _rating = i + 1),
                icon: Icon(i < _rating ? Icons.star_rounded : Icons.star_border_rounded,
                    color: const Color(0xFFF5A623), size: 30),
                visualDensity: VisualDensity.compact,
              ),
            ),
          ),
          TextField(controller: _title, decoration: const InputDecoration(labelText: 'Title (optional)')),
          const SizedBox(height: 8),
          TextField(controller: _body, maxLines: 3, decoration: const InputDecoration(labelText: 'Your review')),
          const SizedBox(height: 16),
          FilledButton(
            onPressed: _saving ? null : _submit,
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
            child: Text(_saving ? 'Submitting…' : 'Submit review'),
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    if (_body.text.trim().isEmpty) {
      return;
    }
    setState(() => _saving = true);
    try {
      await ref
          .read(shopRepositoryProvider)
          .submitReview(widget.productPublicId, _rating, _title.text.trim(), _body.text.trim());
      ref.invalidate(productReviewsProvider(widget.slug));
      if (!mounted) return;
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Thanks — your review will appear once approved.')),
      );
    } on ApiException catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    }
  }
}
