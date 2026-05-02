import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:turbolink_app/app.dart';

void main() {
  testWidgets('App renders with TurboLink branding', (tester) async {
    // Use fakeAsync to control mock timers.
    await tester.runAsync(() async {
      await tester.pumpWidget(
        const ProviderScope(child: TurboLinkApp()),
      );
      await tester.pump();
    });

    // Verify the app title is displayed.
    expect(find.text('TURBOLINK'), findsOneWidget);

    // Verify navigation destinations exist.
    expect(find.text('DISCOVER'), findsOneWidget);
    expect(find.text('TRANSFERS'), findsOneWidget);

    // Verify the MOCK badge is shown.
    expect(find.text('MOCK'), findsOneWidget);
  });
}
