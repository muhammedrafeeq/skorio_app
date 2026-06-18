import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:skorio_app/main.dart';

void main() {
  testWidgets('SkorioApp smoke test', (WidgetTester tester) async {
    // Build our app wrapped in ProviderScope and trigger a frame.
    await tester.pumpWidget(
      const ProviderScope(
        child: SkorioApp(),
      ),
    );

    // Verify that the login screen text is displayed.
    expect(find.textContaining('Login'), findsOneWidget);
  });
}
