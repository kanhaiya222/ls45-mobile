import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../appconfig/data/app_config_repository.dart';
import '../data/shop_repository.dart';
import '../models/shop_models.dart';
import 'shop_format.dart';

/// First page of the signed-in user's Shop orders.
final ordersProvider = FutureProvider.autoDispose<List<OrderSummary>>(
  (ref) async => (await ref.watch(shopRepositoryProvider).listOrders()).content,
);

/// "Your orders": Shop order history with an expandable detail sheet.
class OrdersScreen extends ConsumerWidget {
  const OrdersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final orders = ref.watch(ordersProvider);
    final code = ref.watch(currentBrandingProvider).currencyCode;

    return Scaffold(
      appBar: AppBar(title: const Text('Your orders')),
      body: RefreshIndicator(
        onRefresh: () => ref.refresh(ordersProvider.future),
        child: orders.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => const _Empty(message: 'Could not load your orders.'),
          data: (list) => list.isEmpty
              ? const _Empty(message: 'You haven\'t placed any Shop orders yet.', shop: true)
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: list.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (_, i) => _OrderCard(order: list[i], code: code),
                ),
        ),
      ),
    );
  }
}

class _OrderCard extends ConsumerWidget {
  const _OrderCard({required this.order, required this.code});

  final OrderSummary order;
  final String code;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      child: ListTile(
        title: Text(order.orderNumber, style: const TextStyle(fontWeight: FontWeight.w700)),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Row(
            children: [
              _StatusChip(status: order.status),
              const SizedBox(width: 8),
              Text('${order.itemCount} item${order.itemCount == 1 ? '' : 's'}',
                  style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12.5)),
            ],
          ),
        ),
        trailing: Text(formatMoney(order.grandTotal, code), style: const TextStyle(fontWeight: FontWeight.w800)),
        onTap: () => _openDetail(context, ref),
      ),
    );
  }

  void _openDetail(BuildContext context, WidgetRef ref) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (_) => _OrderDetailSheet(orderPublicId: order.publicId, code: code),
    );
  }
}

class _OrderDetailSheet extends ConsumerWidget {
  const _OrderDetailSheet({required this.orderPublicId, required this.code});

  final String orderPublicId;
  final String code;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(_orderDetailProvider(orderPublicId));
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      maxChildSize: 0.9,
      builder: (_, scrollController) => detail.when(
        loading: () => const Center(child: Padding(padding: EdgeInsets.all(40), child: CircularProgressIndicator())),
        error: (_, __) => const Center(child: Padding(padding: EdgeInsets.all(40), child: Text('Could not load order.'))),
        data: (o) => ListView(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
          children: [
            Text(o.orderNumber, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            _StatusChip(status: o.status),
            const SizedBox(height: 18),
            ...o.items.map((it) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(child: Text('${it.name}  × ${it.quantity}')),
                      Text(formatMoney(it.lineTotal, code)),
                    ],
                  ),
                )),
            const Divider(height: 24),
            _row('Items', formatMoney(o.itemSubtotal, code)),
            _row('Shipping', formatMoney(o.shippingTotal, code)),
            _row('Tax', formatMoney(o.taxTotal, code)),
            if (o.discountTotal > 0) _row('Discount', '−${formatMoney(o.discountTotal, code)}'),
            const SizedBox(height: 6),
            _row('Total', formatMoney(o.grandTotal, code), bold: true),
            if (o.shipName != null) ...[
              const SizedBox(height: 18),
              Text('Shipping to', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: Theme.of(context).colorScheme.onSurfaceVariant)),
              const SizedBox(height: 4),
              Text('${o.shipName}, ${o.shipCity ?? ''}'),
              if (o.shippingMethodName != null) Text('via ${o.shippingMethodName}', style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
            ],
          ],
        ),
      ),
    );
  }

  Widget _row(String label, String value, {bool bold = false}) {
    final style = TextStyle(fontWeight: bold ? FontWeight.w800 : FontWeight.w400, fontSize: bold ? 16 : 14);
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [Text(label, style: style), Text(value, style: style)],
      ),
    );
  }
}

final _orderDetailProvider = FutureProvider.autoDispose.family<Order, String>(
  (ref, id) => ref.watch(shopRepositoryProvider).getOrder(id),
);

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});

  final String status;

  @override
  Widget build(BuildContext context) {
    final label = status
        .toLowerCase()
        .split('_')
        .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
    final scheme = Theme.of(context).colorScheme;
    final isPending = status == 'PENDING_PAYMENT';
    final bg = isPending ? const Color(0xFFFDECC8) : scheme.primaryContainer;
    final fg = isPending ? const Color(0xFF9A6700) : scheme.onPrimaryContainer;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Text(label, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: fg)),
    );
  }
}

class _Empty extends StatelessWidget {
  const _Empty({required this.message, this.shop = false});

  final String message;
  final bool shop;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ListView(
      children: [
        const SizedBox(height: 120),
        Icon(Icons.receipt_long_outlined, size: 56, color: scheme.primary.withValues(alpha: 0.5)),
        const SizedBox(height: 14),
        Center(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 32), child: Text(message, textAlign: TextAlign.center))),
        if (shop) ...[
          const SizedBox(height: 16),
          Center(child: FilledButton(onPressed: () => context.go('/shop'), child: const Text('Visit the Shop'))),
        ],
      ],
    );
  }
}
