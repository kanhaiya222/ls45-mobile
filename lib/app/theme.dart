import 'package:flutter/material.dart';

/// Brand teal — the shipped default seed; matches the web/admin palette (#0F766E). At runtime the
/// app reseeds from the tenant's branding (GET /app/config) — see [buildLightTheme].
const Color brandTeal = Color(0xFF0F766E);

ThemeData _build(Color seed, Brightness brightness) {
  final scheme = ColorScheme.fromSeed(seedColor: seed, brightness: brightness);
  return ThemeData(
    colorScheme: scheme,
    useMaterial3: true,
    scaffoldBackgroundColor: scheme.surface,
    appBarTheme: AppBarTheme(
      centerTitle: false,
      scrolledUnderElevation: 1,
      backgroundColor: scheme.surface,
      foregroundColor: scheme.onSurface,
    ),
    inputDecorationTheme: InputDecorationTheme(
      isDense: true,
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    chipTheme: ChipThemeData(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
    ),
  );
}

/// Light/dark themes seeded from the tenant brand colour (defaults to [brandTeal]).
ThemeData buildLightTheme([Color seed = brandTeal]) => _build(seed, Brightness.light);
ThemeData buildDarkTheme([Color seed = brandTeal]) => _build(seed, Brightness.dark);
