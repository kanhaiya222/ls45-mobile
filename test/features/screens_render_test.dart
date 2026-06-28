import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ls45_mobile/app/theme.dart';
import 'package:ls45_mobile/core/storage/token_storage.dart';
import 'package:ls45_mobile/features/auth/data/auth_repository.dart';
import 'package:ls45_mobile/features/auth/models/auth_models.dart';
import 'package:ls45_mobile/features/auth/ui/login_screen.dart';
import 'package:ls45_mobile/features/auth/ui/register_screen.dart';
import 'package:ls45_mobile/features/booking/data/booking_repository.dart';
import 'package:ls45_mobile/features/booking/ui/booking_start_screen.dart';
import 'package:ls45_mobile/features/booking/ui/checkout_screen.dart';
import 'package:ls45_mobile/features/booking/ui/my_bookings_screen.dart';

import '../support/fakes.dart';

/// Render-level smoke tests for the redesigned screens: each must lay out without throwing (the
/// pinned-search sliver crash slipped past analyze + unit tests, but a render test like this catches
/// that whole class of layout/overflow/null bug) and show its key content.
void main() {
  final store = keyValueStoreProvider.overrideWithValue(InMemoryKeyValueStore());

  testWidgets('Login renders the branded header + fields', (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [store, authRepositoryProvider.overrideWithValue(FakeAuthRepository())],
      child: MaterialApp(theme: buildLightTheme(), home: const LoginScreen()),
    ));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Welcome back'), findsOneWidget);
    expect(find.text('Sign in'), findsWidgets);
  });

  testWidgets('Register renders the create-account form', (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [store, authRepositoryProvider.overrideWithValue(FakeAuthRepository())],
      child: MaterialApp(theme: buildLightTheme(), home: const RegisterScreen()),
    ));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Create your account'), findsOneWidget);
    expect(find.text('Create account'), findsWidgets);
  });

  testWidgets('Booking start renders room type + traveller form + sticky CTA', (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [store],
      child: MaterialApp(
        theme: buildLightTheme(),
        home: const BookingStartScreen(departurePublicId: 'dep-1'),
      ),
    ));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Room type'), findsOneWidget);
    expect(find.text('Traveller 1'), findsOneWidget);
    expect(find.text('Continue to checkout'), findsOneWidget);
  });

  testWidgets('Checkout renders the price summary + reserve CTA', (tester) async {
    await tester.pumpWidget(ProviderScope(
      overrides: [store, bookingRepositoryProvider.overrideWithValue(FakeBookingRepository())],
      child: MaterialApp(theme: buildLightTheme(), home: const CheckoutScreen(draftId: 'draft-1')),
    ));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('Review your booking'), findsOneWidget);
    expect(find.text('Reserve & pay'), findsOneWidget);
    expect(find.text('Total'), findsWidgets);
  });

  testWidgets('My bookings shows the empty state when signed in with no trips', (tester) async {
    const seededUser = AuthUser(
      publicId: 'u1',
      email: 'a@b.com',
      firstName: 'Asha',
      lastName: 'Rao',
      roles: ['CUSTOMER'],
    );
    await tester.pumpWidget(ProviderScope(
      overrides: [
        store,
        authRepositoryProvider.overrideWithValue(FakeAuthRepository(session: seededUser)),
        bookingRepositoryProvider.overrideWithValue(FakeBookingRepository()),
      ],
      child: MaterialApp(theme: buildLightTheme(), home: const MyBookingsScreen()),
    ));
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.text('No bookings yet'), findsOneWidget);
    expect(find.text('Explore journeys'), findsOneWidget);
  });
}
