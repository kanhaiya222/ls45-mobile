import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/appconfig/data/app_config_repository.dart';
import 'router.dart';
import 'theme.dart';

/// Root application widget. Drives navigation via go_router (see [routerProvider]) and applies the
/// shared light/dark brand theme, reseeded from the tenant branding fetched at launch (follows the
/// system light/dark setting).
class Ls45App extends ConsumerWidget {
  const Ls45App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final brand = ref.watch(currentBrandingProvider);
    return MaterialApp.router(
      title: 'TheSalori — Wellness journeys for life',
      debugShowCheckedModeBanner: false,
      theme: buildLightTheme(brand.primaryColor),
      darkTheme: buildDarkTheme(brand.primaryColor),
      themeMode: ThemeMode.system,
      routerConfig: ref.watch(routerProvider),
    );
  }
}
