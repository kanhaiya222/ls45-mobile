import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'router.dart';

/// Brand teal — matches the web/admin theme (#0F766E).
const Color kBrandTeal = Color(0xFF0F766E);

/// Root application widget. Drives navigation via go_router (see [routerProvider]).
class Ls45App extends ConsumerWidget {
  const Ls45App({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp.router(
      title: 'LS45 — Life Starts at 45',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: kBrandTeal),
        useMaterial3: true,
      ),
      routerConfig: ref.watch(routerProvider),
    );
  }
}
