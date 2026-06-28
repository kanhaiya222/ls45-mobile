import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../appconfig/data/app_config_repository.dart';
import '../models/shop_models.dart';
import '../state/cart_controller.dart';
import 'shop_format.dart';

/// The Shop cart: review lines, adjust quantities, remove items, then check out.
class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.watch(cartControllerProvider);
    final code = ref.watch(currentBrandingProvider).currencyCode;

    return Scaffold(
      appBar: AppBar(title: const Text('Your cart')),
      body: cart.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('Could not load your cart.')),
        data: (c) => (c == null || c.items.isEmpty) ? _empty(context) : _content(context, ref, c, code),
      ),
    );
  }

  Widget _empty(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.shopping_bag_outlined, size: 56, color: scheme.primary.withValues(alpha: 0.5)),
          const SizedBox(height: 14),
          const Text('Your cart is empty', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700)),
          const SizedBox(height: 14),
          FilledButton(onPressed: () => context.go('/shop'), child: const Text('Browse the Shop')),
        ],
      ),
    );
  }

  Widget _content(BuildContext context, WidgetRef ref, Cart c, String code) {
    return Column(
      children: [
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: c.items.length,
            separatorBuilder: (_, __) => const Divider(height: 22),
            itemBuilder: (_, i) => _CartLine(item: c.items[i], code: code),
          ),
        ),
        _Summary(cart: c, code: code),
      ],
    );
  }
}

class _CartLine extends ConsumerStatefulWidget {
  const _CartLine({required this.item, required this.code});

  final CartItem item;
  final String code;

  @override
  ConsumerState<_CartLine> createState() => _CartLineState();
}

class _CartLineState extends ConsumerState<_CartLine> {
  bool _busy = false;

  @override
  Widget build(BuildContext context) {
    final it = widget.item;
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(it.variantName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
              const SizedBox(height: 2),
              Text('${formatMoney(it.unitPrice, widget.code)} each',
                  style: TextStyle(fontSize: 12.5, color: scheme.onSurfaceVariant)),
              const SizedBox(height: 8),
              Row(
                children: [
                  _miniBtn(Icons.remove_rounded, _busy || it.quantity <= 1 ? null : () => _update(it.quantity - 1)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text('${it.quantity}', style: const TextStyle(fontWeight: FontWeight.w700)),
                  ),
                  _miniBtn(Icons.add_rounded, _busy ? null : () => _update(it.quantity + 1)),
                ],
              ),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(formatMoney(it.lineTotal, widget.code), style: const TextStyle(fontWeight: FontWeight.w800)),
            TextButton(
              onPressed: _busy ? null : _remove,
              style: TextButton.styleFrom(visualDensity: VisualDensity.compact, foregroundColor: scheme.error),
              child: const Text('Remove'),
            ),
          ],
        ),
      ],
    );
  }

  Widget _miniBtn(IconData icon, VoidCallback? onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Padding(padding: const EdgeInsets.all(4), child: Icon(icon, size: 20)),
    );
  }

  Future<void> _update(int qty) async {
    setState(() => _busy = true);
    try {
      await ref.read(cartControllerProvider.notifier).updateItem(widget.item.publicId, qty);
    } catch (_) {
      /* surfaced via snackbar elsewhere; keep the cart usable */
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _remove() async {
    setState(() => _busy = true);
    try {
      await ref.read(cartControllerProvider.notifier).removeItem(widget.item.publicId);
    } catch (_) {
      if (mounted) setState(() => _busy = false);
    }
  }
}

class _Summary extends StatelessWidget {
  const _Summary({required this.cart, required this.code});

  final Cart cart;
  final String code;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: EdgeInsets.fromLTRB(18, 16, 18, MediaQuery.of(context).padding.bottom + 16),
      decoration: BoxDecoration(
        color: scheme.surface,
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 12, offset: const Offset(0, -2))],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Subtotal (${cart.totalQuantity} item${cart.totalQuantity == 1 ? '' : 's'})',
                  style: TextStyle(color: scheme.onSurfaceVariant)),
              Text(formatMoney(cart.subtotal, code), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            ],
          ),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerLeft,
            child: Text('Shipping & taxes are calculated at checkout.',
                style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
          ),
          const SizedBox(height: 12),
          FilledButton(
            onPressed: () => context.push('/shop/checkout'),
            style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(50)),
            child: const Text('Proceed to checkout'),
          ),
        ],
      ),
    );
  }
}
