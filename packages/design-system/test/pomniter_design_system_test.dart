import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pomniter_design_system/pomniter_design_system.dart';

void main() {
  group('NeoColors', () {
    test('brand color tokens match specification', () {
      expect(NeoColors.yellow, const Color(0xFFFFE156));
      expect(NeoColors.pink, const Color(0xFFFF6B9D));
      expect(NeoColors.green, const Color(0xFF4ADE80));
      expect(NeoColors.purple, const Color(0xFFA855F7));
      expect(NeoColors.blue, const Color(0xFF60A5FA));
      expect(NeoColors.black, const Color(0xFF121212));
      expect(NeoColors.white, const Color(0xFFFFFFFF));
    });
  });

  group('NeoThemeData', () {
    test('light theme has expected colors', () {
      final light = NeoThemeData.light;
      expect(light.isDark, isFalse);
      expect(light.bgMain, NeoColors.bgMain);
      expect(light.textMain, NeoColors.textMain);
      expect(light.borderColor, NeoColors.borderLight);
    });

    test('dark theme has expected colors', () {
      final dark = NeoThemeData.dark;
      expect(dark.isDark, isTrue);
      expect(dark.bgMain, NeoColors.bgMainDark);
      expect(dark.textMain, NeoColors.textMainDark);
      expect(dark.borderColor, NeoColors.borderDark);
    });

    test('toMaterialTheme creates valid ThemeData', () {
      final theme = NeoTheme.toMaterialTheme(NeoThemeData.light);
      expect(theme.useMaterial3, isTrue);
      expect(theme.brightness, Brightness.light);
    });
  });

  group('NeoButton', () {
    testWidgets('renders text and responds to tap', (WidgetTester tester) async {
      var tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: NeoButton(
                label: 'TEST BUTTON',
                onPressed: () {
                  tapped = true;
                },
              ),
            ),
          ),
        ),
      );

      expect(find.text('TEST BUTTON'), findsOneWidget);
      await tester.tap(find.text('TEST BUTTON'));
      await tester.pumpAndSettle();
      expect(tapped, isTrue);
    });

    testWidgets('shows loading indicator when isLoading is true', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: NeoButton(
                label: 'Submit',
                isLoading: true,
              ),
            ),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(find.text('Submit'), findsNothing);
    });
  });

  group('NeoCard', () {
    testWidgets('renders children and handles tap', (WidgetTester tester) async {
      var tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: NeoCard(
              onTap: () {
                tapped = true;
              },
              child: const Text('Card Content'),
            ),
          ),
        ),
      );

      expect(find.text('Card Content'), findsOneWidget);
      await tester.tap(find.text('Card Content'));
      await tester.pumpAndSettle();
      expect(tapped, isTrue);
    });
  });

  group('NeoBadge', () {
    testWidgets('renders label in uppercase with icon', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: NeoBadge(
              label: 'RECEIPT',
              icon: Icons.tag,
            ),
          ),
        ),
      );

      expect(find.text('RECEIPT'), findsOneWidget);
      expect(find.byIcon(Icons.tag), findsOneWidget);
    });
  });

  group('NeoAppBar', () {
    testWidgets('renders uppercase title', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            appBar: NeoAppBar(title: 'Pomniter'),
            body: Center(child: Text('Body')),
          ),
        ),
      );

      expect(find.text('POMNITER'), findsOneWidget);
    });
  });

  group('NeoTextField', () {
    testWidgets('accepts text input and updates controller', (WidgetTester tester) async {
      final controller = TextEditingController();

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(16.0),
              child: NeoTextField(
                controller: controller,
                hintText: 'Search screenshots...',
                isSearch: true,
              ),
            ),
          ),
        ),
      );

      expect(find.text('Search screenshots...'), findsOneWidget);
      await tester.enterText(find.byType(TextField), 'receipt from amazon');
      expect(controller.text, 'receipt from amazon');
    });
  });
}
