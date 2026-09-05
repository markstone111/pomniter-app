import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pomniter_mobile/src/app.dart';

void main() {
  testWidgets('PomniterApp boots with home screen and neo-brutal branding', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: PomniterApp(),
      ),
    );

    await tester.pumpAndSettle();

    // Verify AppBar brand title
    expect(find.text('POMNITER'), findsOneWidget);

    // Verify Hero Local Memory Engine Banner
    expect(find.text('LOCAL MEMORY ENGINE'), findsOneWidget);

    // Verify Bottom Navigation items
    expect(find.text('HOME'), findsWidgets);
    expect(find.text('SEARCH'), findsWidgets);
    expect(find.text('GALLERY'), findsWidgets);
    expect(find.text('SETTINGS'), findsWidgets);
  });
}
