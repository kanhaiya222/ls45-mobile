import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ls45_mobile/app/ls45_app.dart';
import 'package:ls45_mobile/core/storage/token_storage.dart';

import 'support/fakes.dart';

void main() {
  testWidgets('App boots and renders the home scaffold (signed out)', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        // Override secure storage so session restore runs against an empty in-memory store.
        overrides: [keyValueStoreProvider.overrideWithValue(InMemoryKeyValueStore())],
        child: const Ls45App(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('LS45 Wellness Journeys'), findsOneWidget);
    expect(find.text('Sign in'), findsOneWidget);
  });
}
