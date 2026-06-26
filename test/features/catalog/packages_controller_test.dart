import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ls45_mobile/features/catalog/data/catalog_repository.dart';
import 'package:ls45_mobile/features/catalog/state/packages_controller.dart';

import '../../support/fakes.dart';

void main() {
  ProviderContainer withRepo(FakeCatalogRepository repo) {
    final container = ProviderContainer(
      overrides: [catalogRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);
    return container;
  }

  test('loads the first page on build', () async {
    final container = withRepo(
      FakeCatalogRepository(
        all: [fakePackage('A'), fakePackage('B'), fakePackage('C')],
        pageSize: 2,
      ),
    );

    final first = await container.read(packagesControllerProvider.future);

    expect(first, hasLength(2));
    expect(container.read(packagesControllerProvider.notifier).hasMore, isTrue);
  });

  test('loadMore appends the next page and clears hasMore at the end', () async {
    final container = withRepo(
      FakeCatalogRepository(
        all: [fakePackage('A'), fakePackage('B'), fakePackage('C')],
        pageSize: 2,
      ),
    );
    await container.read(packagesControllerProvider.future);

    await container.read(packagesControllerProvider.notifier).loadMore();

    expect(container.read(packagesControllerProvider).value, hasLength(3));
    expect(container.read(packagesControllerProvider.notifier).hasMore, isFalse);
  });

  test('search filters results and resets paging', () async {
    final container = withRepo(
      FakeCatalogRepository(
        all: [fakePackage('Goa Escape'), fakePackage('Himalaya Trek')],
        pageSize: 10,
      ),
    );
    await container.read(packagesControllerProvider.future);

    await container.read(packagesControllerProvider.notifier).search('goa');

    final results = container.read(packagesControllerProvider).value!;
    expect(results, hasLength(1));
    expect(results.first.name, 'Goa Escape');
  });
}
