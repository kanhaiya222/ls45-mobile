import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ls45_mobile/app/ls45_app.dart';
import 'package:ls45_mobile/core/storage/token_storage.dart';
import 'package:ls45_mobile/features/catalog/data/catalog_repository.dart';

import 'support/fakes.dart';

void main() {
  testWidgets('App boots and renders the catalog home', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          // No platform secure-storage and no network in the widget test.
          keyValueStoreProvider.overrideWithValue(InMemoryKeyValueStore()),
          catalogRepositoryProvider.overrideWithValue(FakeCatalogRepository()),
        ],
        child: const Ls45App(),
      ),
    );
    await tester.pumpAndSettle();

    // The branded hero header renders regardless of catalogue data.
    expect(find.text('LS45 · WELLNESS'), findsOneWidget);
    expect(find.text('Journeys for life\nafter 45'), findsOneWidget);
  });
}
