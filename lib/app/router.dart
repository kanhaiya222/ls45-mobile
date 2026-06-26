import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/auth/state/auth_controller.dart';
import '../features/auth/ui/login_screen.dart';
import '../features/auth/ui/register_screen.dart';
import '../features/booking/ui/booking_start_screen.dart';
import '../features/catalog/ui/catalog_list_screen.dart';
import '../features/catalog/ui/package_detail_screen.dart';

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
      final loc = state.matchedLocation;
      final atAuthScreen = loc == '/login' || loc == '/register';
      final protected =
          loc.startsWith('/book') || loc.startsWith('/checkout') || loc.startsWith('/account');
      if (loggedIn && atAuthScreen) return '/';
      if (!loggedIn && protected) return '/login';
      return null;
    },
    routes: [
      GoRoute(path: '/', builder: (_, __) => const CatalogListScreen()),
      GoRoute(path: '/login', builder: (_, __) => const LoginScreen()),
      GoRoute(path: '/register', builder: (_, __) => const RegisterScreen()),
      GoRoute(
        path: '/packages/:slug',
        builder: (_, state) => PackageDetailScreen(slug: state.pathParameters['slug']!),
      ),
      GoRoute(
        path: '/book/:departureId',
        builder: (_, state) =>
            BookingStartScreen(departurePublicId: state.pathParameters['departureId']!),
      ),
      // Real checkout (reserve + payment) lands in M.8; this keeps the booking flow navigable.
      GoRoute(
        path: '/checkout/:draftId',
        builder: (_, state) => Scaffold(
          appBar: AppBar(title: const Text('Checkout')),
          body: Center(
            child: Text('Checkout for draft ${state.pathParameters['draftId']} — payment in M.8'),
          ),
        ),
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});
