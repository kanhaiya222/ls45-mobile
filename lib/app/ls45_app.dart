import 'package:flutter/material.dart';

/// Brand teal — matches the web/admin theme (#0F766E).
const Color kBrandTeal = Color(0xFF0F766E);

/// Root application widget. Routing (go_router) and the real screens are wired in later slices
/// (M.4+); this scaffold establishes the app shell, theme, and a compiling entry point.
class Ls45App extends StatelessWidget {
  const Ls45App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'LS45 — Life Starts at 45',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: kBrandTeal),
        useMaterial3: true,
      ),
      home: const HomePlaceholderScreen(),
    );
  }
}

/// Temporary landing screen until the catalog (M.5) replaces it.
class HomePlaceholderScreen extends StatelessWidget {
  const HomePlaceholderScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('LS45 Wellness Journeys')),
      body: const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Mobile app scaffold ready.\nCatalog, auth and booking arrive in the next slices.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}
