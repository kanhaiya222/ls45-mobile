import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_response.dart';
import '../../../core/network/dio_client.dart';
import '../models/app_branding.dart';

/// Fetches the public bootstrap config (`GET /api/v1/app/config`). No auth required, so it uses the
/// bare Dio client.
class AppConfigRepository {
  AppConfigRepository(this._dio);

  final Dio _dio;

  Future<AppBranding> fetchBranding() async {
    final res = await _dio.get<dynamic>('/app/config');
    return unwrap<AppBranding>(
      res.data,
      (data) => AppBranding.fromConfigJson((data as Map).cast<String, dynamic>()),
    );
  }
}

final appConfigRepositoryProvider = Provider<AppConfigRepository>(
  (ref) => AppConfigRepository(ref.watch(bareDioProvider)),
);

/// Tenant branding, fetched once at launch. Falls back to [AppBranding.fallback] on any error, so the
/// app always themes + prices consistently even when offline or before the call resolves.
final brandingProvider = FutureProvider<AppBranding>((ref) async {
  try {
    return await ref.watch(appConfigRepositoryProvider).fetchBranding();
  } catch (_) {
    return AppBranding.fallback;
  }
});

/// The resolved branding synchronously (or the fallback while loading) — convenient for theming and
/// currency formatting inside build methods.
final currentBrandingProvider = Provider<AppBranding>(
  (ref) => ref.watch(brandingProvider).value ?? AppBranding.fallback,
);
