import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ls45_mobile/app/ls45_app.dart';

void main() {
  testWidgets('App boots and renders the home scaffold', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: Ls45App()));

    expect(find.text('LS45 Wellness Journeys'), findsOneWidget);
  });
}
