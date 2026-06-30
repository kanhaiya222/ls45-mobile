import 'package:flutter/material.dart';

import '../../../core/json/json_utils.dart';

/// Tenant branding from `GET /api/v1/app/config` — the theme seed colour + currency the app applies
/// at launch, so a rebranded tenant looks and prices consistently with its web + admin portals.
class AppBranding {
  const AppBranding({
    required this.siteName,
    required this.primaryColor,
    required this.accentColor,
    required this.currencyCode,
  });

  final String siteName;
  final Color primaryColor;
  final Color accentColor;
  final String currencyCode;

  /// Shipped defaults — used until /app/config resolves and if the call ever fails.
  static const AppBranding fallback = AppBranding(
    siteName: 'TheSalori',
    primaryColor: Color(0xFF0F766E),
    accentColor: Color(0xFFF97316),
    currencyCode: 'INR',
  );

  String get currencySymbol => currencySymbolFor(currencyCode);

  /// Builds from the `data` object of the app-config envelope (currency falls back to the top-level
  /// `currencyCode` the backend also exposes there).
  factory AppBranding.fromConfigJson(Map<String, dynamic> data) {
    final branding = (data['branding'] as Map?)?.cast<String, dynamic>() ?? const {};
    return AppBranding(
      siteName: asStringOrNull(branding['siteName']) ?? fallback.siteName,
      primaryColor: _hexColor(branding['primaryColor']) ?? fallback.primaryColor,
      accentColor: _hexColor(branding['accentColor']) ?? fallback.accentColor,
      currencyCode: asStringOrNull(branding['currencyCode']) ??
          asStringOrNull(data['currencyCode']) ??
          fallback.currencyCode,
    );
  }
}

/// Parses `#RRGGBB` / `RRGGBB` (and `#AARRGGBB`) into a [Color]; null when unparseable.
Color? _hexColor(dynamic value) {
  if (value is! String) return null;
  var hex = value.trim().replaceFirst('#', '');
  if (hex.length == 6) hex = 'FF$hex';
  if (hex.length != 8) return null;
  final argb = int.tryParse(hex, radix: 16);
  return argb == null ? null : Color(argb);
}

const Map<String, String> _currencySymbols = {
  'INR': '₹',
  'USD': '\$',
  'EUR': '€',
  'GBP': '£',
  'AED': 'AED ',
  'SGD': 'S\$',
  'AUD': 'A\$',
  'JPY': '¥',
  'CAD': 'C\$',
};

/// Symbol for an ISO currency code, falling back to "<CODE> " for unmapped currencies.
String currencySymbolFor(String code) => _currencySymbols[code] ?? '$code ';

/// Formats a rounded money amount with the tenant currency symbol, e.g. `₹12500`.
String formatMoney(num value, String currencyCode) =>
    '${currencySymbolFor(currencyCode)}${value.round()}';
