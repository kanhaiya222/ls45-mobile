import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ls45_mobile/features/appconfig/models/app_branding.dart';

void main() {
  test('AppBranding.fromConfigJson parses brand colours + currency', () {
    final b = AppBranding.fromConfigJson({
      'currencyCode': 'INR',
      'branding': {
        'siteName': 'Acme Travel',
        'primaryColor': '#1D4ED8',
        'accentColor': 'F59E0B',
        'currencyCode': 'USD',
      },
    });
    expect(b.siteName, 'Acme Travel');
    expect(b.primaryColor, const Color(0xFF1D4ED8));
    expect(b.accentColor, const Color(0xFFF59E0B)); // tolerates a missing '#'
    expect(b.currencyCode, 'USD'); // branding currency wins over the top-level one
    expect(b.currencySymbol, '\$');
  });

  test('falls back to shipped defaults when branding is absent/invalid', () {
    final b = AppBranding.fromConfigJson({
      'branding': {'primaryColor': 'not-a-colour'},
    });
    expect(b.siteName, AppBranding.fallback.siteName);
    expect(b.primaryColor, AppBranding.fallback.primaryColor);
    expect(b.currencyCode, 'INR');
    expect(b.currencySymbol, '₹');
  });

  test('top-level currencyCode is used when branding omits it', () {
    final b = AppBranding.fromConfigJson({
      'currencyCode': 'GBP',
      'branding': {'siteName': 'X'},
    });
    expect(b.currencyCode, 'GBP');
    expect(b.currencySymbol, '£');
  });

  test('currencySymbolFor + formatMoney', () {
    expect(currencySymbolFor('EUR'), '€');
    expect(currencySymbolFor('ZZZ'), 'ZZZ '); // unmapped code -> "<CODE> "
    expect(formatMoney(12499.6, 'INR'), '₹12500');
  });
}
