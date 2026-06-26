import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/state/auth_controller.dart';
import '../features/auth/ui/login_screen.dart';
import '../features/auth/ui/register_screen.dart';
import '../features/catalog/ui/catalog_list_screen.dart';

/// App router. The redirect guard keeps signed-in users out of the auth screens; protected routes
/// (account, checkout) are added with their slices (M.7+). Rebuilds when auth state changes.
final routerProvider = Provider<GoRouter>((ref) {
  final refresh = ValueNotifier<int>(0);
  ref.onDispose(refresh.dispose);
  ref.listen(authControllerProvider, (_, __) => refresh.value++);

  final router = GoRouter(
    initialLocation: '/',
    refreshListenable: refresh,
    redirect: (context, state) {
      final auth = ref.read(authControllerProvider);
      if (auth.isLoading) return null; // wait for the initial session restore
      final loggedIn = auth.value != null;
      final atAuthScreen =
          state.matchedLocation == '/login' || state.matchedLocation == '/register';
      if (loggedIn && atAuthScreen) return '/';
      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (_, __) => const CatalogListScreen()),
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
      // Real package-detail screen is wired in M.6; this keeps catalog taps working meanwhile.
      GoRoute(
        path: '/packages/:slug',
        builder: (_, state) => Scaffold(
          appBar: AppBar(title: const Text('Journey')),
          body: Center(child: Text('Opening ${state.pathParameters['slug']}…')),
        ),
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});
