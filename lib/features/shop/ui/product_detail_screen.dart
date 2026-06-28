import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_exception.dart';
import '../../../shared/ui/app_ui.dart';
import '../../appconfig/data/app_config_repository.dart';
import '../../auth/state/auth_controller.dart';
import '../models/shop_models.dart';
import '../state/cart_controller.dart';
import '../state/products_controller.dart';
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
            ],
          ),
        ),
      ],
    );
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
