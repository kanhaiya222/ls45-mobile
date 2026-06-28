import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_exception.dart';
import '../../appconfig/data/app_config_repository.dart';
import '../data/shop_repository.dart';
import '../models/shop_models.dart';
import '../state/cart_controller.dart';
import 'shop_format.dart';

/// Shop checkout: shipping address + live shipping quote + promo code → place order. Online payment
/// reuses the booking gateway; when it is not configured the order is placed as payment-pending.
class ShopCheckoutScreen extends ConsumerStatefulWidget {
  const ShopCheckoutScreen({super.key});

  @override
  ConsumerState<ShopCheckoutScreen> createState() => _ShopCheckoutScreenState();
}

class _ShopCheckoutScreenState extends ConsumerState<ShopCheckoutScreen> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _line1 = TextEditingController();
  final _line2 = TextEditingController();
  final _city = TextEditingController();
  final _state = TextEditingController();
  final _postal = TextEditingController();
  final _country = TextEditingController(text: 'IN');
  final _coupon = TextEditingController();

  List<ShippingQuote> _quotes = const [];
  String? _methodId;
  bool _loadingQuotes = false;
  bool _placing = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadQuotes());
  }

  @override
  void dispose() {
    for (final c in [_name, _phone, _line1, _line2, _city, _state, _postal, _country, _coupon]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _loadQuotes() async {
    final country = _country.text.trim().toUpperCase();
    if (country.length != 2) return;
    final subtotal = ref.read(cartControllerProvider).value?.subtotal ?? 0;
    setState(() => _loadingQuotes = true);
    try {
      final qs = await ref.read(shopRepositoryProvider).shippingQuote(country, 0, subtotal);
      setState(() {
        _quotes = qs;
        if (qs.isNotEmpty && !qs.any((q) => q.methodPublicId == _methodId)) {
          _methodId = qs.first.methodPublicId;
        }
      });
    } catch (_) {
      setState(() => _quotes = const []);
    } finally {
      if (mounted) setState(() => _loadingQuotes = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = ref.watch(cartControllerProvider).value;
    final code = ref.watch(currentBrandingProvider).currencyCode;
    final empty = cart == null || cart.items.isEmpty;

    return Scaffold(
      appBar: AppBar(title: const Text('Checkout')),
      body: empty
          ? const Center(child: Text('Your cart is empty.'))
          : Form(
              key: _form,
              child: ListView(
                padding: const EdgeInsets.all(18),
                children: [
                  _sectionTitle(context, 'Shipping address'),
                  _field(_name, 'Full name', required: true),
                  _field(_phone, 'Phone', keyboard: TextInputType.phone, required: true),
                  _field(_line1, 'Address line 1', required: true),
                  _field(_line2, 'Address line 2 (optional)'),
                  Row(children: [
                    Expanded(child: _field(_city, 'City', required: true)),
                    const SizedBox(width: 12),
                    Expanded(child: _field(_state, 'State (optional)')),
                  ]),
                  Row(children: [
                    Expanded(child: _field(_postal, 'Postal code (optional)')),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _field(_country, 'Country (ISO-2)', onEditingComplete: _loadQuotes, required: true),
                    ),
                  ]),
                  const SizedBox(height: 18),
                  _sectionTitle(context, 'Shipping method'),
                  if (_loadingQuotes)
                    const Padding(padding: EdgeInsets.all(8), child: LinearProgressIndicator())
                  else if (_quotes.isEmpty)
                    Text('No shipping options for this country yet.',
                        style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant))
                  else
                    ..._quotes.map((q) => RadioListTile<String>(
                          value: q.methodPublicId,
                          groupValue: _methodId,
                          onChanged: (v) => setState(() => _methodId = v),
                          title: Text(q.methodName),
                          subtitle: q.carrier != null ? Text(q.carrier!) : null,
                          secondary: Text(q.free ? 'Free' : formatMoney(q.price, code),
                              style: const TextStyle(fontWeight: FontWeight.w700)),
                          contentPadding: EdgeInsets.zero,
                        )),
                  const SizedBox(height: 18),
                  _sectionTitle(context, 'Promo code (optional)'),
                  _field(_coupon, 'Enter a code'),
                  const SizedBox(height: 18),
                  _Totals(cart: cart, shipping: _selectedQuote()?.price ?? 0, code: code),
                  const SizedBox(height: 20),
                  FilledButton(
                    onPressed: _placing ? null : _placeOrder,
                    style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                    child: Text(_placing ? 'Placing order…' : 'Place order'),
                  ),
                ],
              ),
            ),
    );
  }

  ShippingQuote? _selectedQuote() =>
      _quotes.where((q) => q.methodPublicId == _methodId).firstOrNull;

  Widget _sectionTitle(BuildContext context, String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(text.toUpperCase(),
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
                color: Theme.of(context).colorScheme.onSurfaceVariant)),
      );

  Widget _field(
    TextEditingController c,
    String label, {
    bool required = false,
    TextInputType? keyboard,
    VoidCallback? onEditingComplete,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextFormField(
        controller: c,
        keyboardType: keyboard,
        onEditingComplete: onEditingComplete,
        decoration: InputDecoration(labelText: label),
        validator: required ? (v) => (v == null || v.trim().isEmpty) ? 'Required' : null : null,
      ),
    );
  }

  Future<void> _placeOrder() async {
    if (!(_form.currentState?.validate() ?? false)) return;
    if (_methodId == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please choose a shipping method.')));
      return;
    }
    setState(() => _placing = true);
    final repo = ref.read(shopRepositoryProvider);
    try {
      final order = await repo.checkout(CheckoutRequest(
        shippingMethodPublicId: _methodId!,
        shipName: _name.text.trim(),
        shipPhone: _phone.text.trim(),
        shipLine1: _line1.text.trim(),
        shipLine2: _line2.text.trim(),
        shipCity: _city.text.trim(),
        shipState: _state.text.trim(),
        shipPostalCode: _postal.text.trim(),
        shipCountry: _country.text.trim().toUpperCase(),
        couponCode: _coupon.text.trim(),
      ));
      ref.read(cartControllerProvider.notifier).clearLocal();
      String note = 'Your order ${order.orderNumber} is placed.';
      try {
        await repo.initiatePayment(order.publicId);
      } on ApiException catch (e) {
        if (e.errorCode == 'PAYMENT_NOT_CONFIGURED') {
          note = 'Your order ${order.orderNumber} is placed. Online payment isn\'t enabled yet — '
              'our team will reach out to arrange payment.';
        }
      }
      if (!mounted) return;
      await _showConfirmation(order, note);
    } on ApiException catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.message)));
      }
    } finally {
      if (mounted) setState(() => _placing = false);
    }
  }

  Future<void> _showConfirmation(Order order, String note) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        icon: const Icon(Icons.check_circle_rounded, color: Colors.green, size: 44),
        title: const Text('Order placed'),
        content: Text(note),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              context.go('/shop');
            },
            child: const Text('Keep shopping'),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              context.go('/account/orders');
            },
            child: const Text('My orders'),
          ),
        ],
      ),
    );
  }
}

class _Totals extends StatelessWidget {
  const _Totals({required this.cart, required this.shipping, required this.code});

  final Cart cart;
  final double shipping;
  final String code;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          _row(context, 'Subtotal', formatMoney(cart.subtotal, code)),
          const SizedBox(height: 6),
          _row(context, 'Shipping', formatMoney(shipping, code)),
          const Divider(height: 20),
          _row(context, 'Estimated total', formatMoney(cart.subtotal + shipping, code), bold: true),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerLeft,
            child: Text('Tax is calculated when the order is placed.',
                style: TextStyle(fontSize: 11.5, color: scheme.onSurfaceVariant)),
          ),
        ],
      ),
    );
  }

  Widget _row(BuildContext context, String label, String value, {bool bold = false}) {
    final style = TextStyle(fontWeight: bold ? FontWeight.w800 : FontWeight.w500, fontSize: bold ? 16 : 14);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [Text(label, style: style), Text(value, style: style)],
    );
  }
}
