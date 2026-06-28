import '../../appconfig/models/app_branding.dart';

/// Formats a money amount with the brand currency symbol, dropping a trailing `.00`.
String formatMoney(double? value, String currencyCode) {
  if (value == null) return '—';
  final symbol = currencySymbolFor(currencyCode);
  final whole = value == value.roundToDouble();
  return '$symbol${whole ? value.toStringAsFixed(0) : value.toStringAsFixed(2)}';
}
