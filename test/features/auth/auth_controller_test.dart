import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ls45_mobile/features/auth/data/auth_repository.dart';
import 'package:ls45_mobile/features/auth/models/auth_models.dart';
import 'package:ls45_mobile/features/auth/state/auth_controller.dart';

import '../../support/fakes.dart';

void main() {
  ProviderContainer containerWith(FakeAuthRepository repo) {
    final container = ProviderContainer(
      overrides: [authRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);
    return container;
  }

  const seededUser =
      AuthUser(publicId: 'u', email: 'a@b.com', firstName: 'A', lastName: 'B');

  test('starts unauthenticated when there is no session', () async {
    final container = containerWith(FakeAuthRepository());

    final user = await container.read(authControllerProvider.future);

    expect(user, isNull);
  });

  test('restores a persisted session on build', () async {
    final container = containerWith(FakeAuthRepository(session: seededUser));

    final user = await container.read(authControllerProvider.future);

    expect(user?.email, 'a@b.com');
  });

  test('login authenticates the user', () async {
    final container = containerWith(FakeAuthRepository());
    await container.read(authControllerProvider.future);

    await container.read(authControllerProvider.notifier).login('admin@ls45.io', 'pw');

    expect(container.read(authControllerProvider).value?.email, 'admin@ls45.io');
  });

  test('login failure surfaces as an AsyncError', () async {
    final container = containerWith(FakeAuthRepository()..throwOnLogin = true);
    await container.read(authControllerProvider.future);

    await container.read(authControllerProvider.notifier).login('x@y.com', 'bad');

    expect(container.read(authControllerProvider).hasError, isTrue);
  });

  test('logout clears the user', () async {
    final container = containerWith(FakeAuthRepository(session: seededUser));
    await container.read(authControllerProvider.future);

    await container.read(authControllerProvider.notifier).logout();

    expect(container.read(authControllerProvider).value, isNull);
  });
}
