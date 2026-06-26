import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../features/account/profile_screen.dart';
import '../features/auth/state/auth_controller.dart';
import '../features/auth/ui/login_screen.dart';
import '../features/auth/ui/register_screen.dart';
import '../features/booking/ui/booking_detail_screen.dart';
import '../features/booking/ui/booking_start_screen.dart';
import '../features/booking/ui/checkout_screen.dart';
import '../features/booking/ui/my_bookings_screen.dart';
import '../features/catalog/ui/catalog_list_screen.dart';
import '../features/catalog/ui/package_detail_screen.dart';
import 'app_scaffold.dart';

/// App router. A bottom-nav shell hosts Explore / Bookings / Profile; auth, detail, booking and
/// checkout screens push over it. The redirect guard gates the booking flow + booking detail.
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
      final protected = loc.startsWith('/book') ||
          loc.startsWith('/checkout') ||
          loc.startsWith('/account/bookings/');
      if (loggedIn && atAuthScreen) return '/';
      if (!loggedIn && protected) return '/login';
      return null;
    },
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            AppScaffold(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [GoRoute(path: '/', builder: (_, __) => const CatalogListScreen())],
          ),
          StatefulShellBranch(
            routes: [GoRoute(path: '/account/bookings', builder: (_, __) => const MyBookingsScreen())],
          ),
          StatefulShellBranch(
            routes: [GoRoute(path: '/profile', builder: (_, __) => const ProfileScreen())],
          ),
        ],
      ),
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
      GoRoute(
        path: '/checkout/:draftId',
        builder: (_, state) => CheckoutScreen(draftId: state.pathParameters['draftId']!),
      ),
      GoRoute(
        path: '/account/bookings/:id',
        builder: (_, state) => BookingDetailScreen(bookingId: state.pathParameters['id']!),
      ),
    ],
  );
  ref.onDispose(router.dispose);
  return router;
});
