import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ls45_mobile/features/appconfig/data/app_config_repository.dart';
import 'package:ls45_mobile/features/appconfig/models/app_branding.dart';

/// Stand-in for the real repository — implements its public interface so we can drive the provider
/// without a Dio/HTTP layer.
class _FakeConfigRepo implements AppConfigRepository {
  _FakeConfigRepo(this._result, {this.fails = false});

  final AppBranding _result;
  final bool fails;

  @override
  Future<AppBranding> fetchBranding() async {
    if (fails) {
      throw Exception('/app/config unreachable');
    }
    return _result;
  }
}

void main() {
  const custom = AppBranding(
    siteName: 'Acme Travel',
    primaryColor: Color(0xFF1D4ED8),
    accentColor: Color(0xFFF59E0B),
    currencyCode: 'USD',
  );

  ProviderContainer containerWith(_FakeConfigRepo repo) {
    final c = ProviderContainer(
      overrides: [appConfigRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(c.dispose);
    return c;
  }

  test('brandingProvider returns the tenant branding on success', () async {
    final c = containerWith(_FakeConfigRepo(custom));
    final branding = await c.read(brandingProvider.future);
    expect(branding.siteName, 'Acme Travel');
    expect(branding.currencyCode, 'USD');
    expect(branding.primaryColor, const Color(0xFF1D4ED8));
  });

  test('brandingProvider fails safe to shipped defaults when /app/config is down', () async {
    final c = containerWith(_FakeConfigRepo(custom, fails: true));
    final branding = await c.read(brandingProvider.future);
    expect(branding, AppBranding.fallback);
  });

  test('currentBrandingProvider yields the fallback until branding resolves (no flash)', () {
    final c = containerWith(_FakeConfigRepo(custom));
    // Read synchronously before awaiting: brandingProvider is still loading, so the theme/currency
    // get the shipped defaults rather than null.
    expect(c.read(currentBrandingProvider), AppBranding.fallback);
  });
}
