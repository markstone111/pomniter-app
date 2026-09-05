import 'package:flutter/material.dart';
import '../tokens/neo_colors.dart';
import '../tokens/neo_typography.dart';
import 'neo_theme_data.dart';

/// InheritedWidget that provides [NeoThemeData] to the widget tree.
///
/// Wraps your app to provide neo-brutal theme tokens everywhere.
///
/// `dart
/// NeoTheme(
///   data: NeoThemeData.light,
///   child: MaterialApp(...),
/// )
/// `
class NeoTheme extends InheritedWidget {
  final NeoThemeData data;

  const NeoTheme({
    super.key,
    required this.data,
    required super.child,
  });

  /// Access the nearest [NeoThemeData] from the widget tree.
  static NeoThemeData of(BuildContext context) {
    final widget = context.dependOnInheritedWidgetOfExactType<NeoTheme>();
    assert(widget != null, 'No NeoTheme found in context. Wrap your app with NeoTheme.');
    return widget!.data;
  }

  /// Try to access [NeoThemeData], returns null if not found.
  static NeoThemeData? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<NeoTheme>()?.data;
  }

  @override
  bool updateShouldNotify(NeoTheme oldWidget) => data != oldWidget.data;

  /// Generates a Material [ThemeData] from [NeoThemeData].
  ///
  /// This bridges the neo-brutal design system with Flutter's Material theme,
  /// so that standard Material widgets also pick up our styling.
  static ThemeData toMaterialTheme(NeoThemeData neo) {

    return ThemeData(
      useMaterial3: true,
      brightness: neo.brightness,
      scaffoldBackgroundColor: neo.bgMain,
      colorScheme: ColorScheme(
        brightness: neo.brightness,
        primary: NeoColors.yellow,
        onPrimary: NeoColors.black,
        secondary: NeoColors.pink,
        onSecondary: NeoColors.black,
        error: NeoColors.error,
        onError: NeoColors.white,
        surface: neo.bgSurface,
        onSurface: neo.textMain,
      ),
      textTheme: TextTheme(
        displayLarge: NeoTypography.displayLarge.copyWith(color: neo.textMain),
        displayMedium: NeoTypography.displayMedium.copyWith(color: neo.textMain),
        displaySmall: NeoTypography.displaySmall.copyWith(color: neo.textMain),
        headlineLarge: NeoTypography.headlineLarge.copyWith(color: neo.textMain),
        headlineMedium: NeoTypography.headlineMedium.copyWith(color: neo.textMain),
        headlineSmall: NeoTypography.headlineSmall.copyWith(color: neo.textMain),
        bodyLarge: NeoTypography.bodyLarge.copyWith(color: neo.textMain),
        bodyMedium: NeoTypography.bodyMedium.copyWith(color: neo.textMuted),
        bodySmall: NeoTypography.bodySmall.copyWith(color: neo.textDim),
        labelLarge: NeoTypography.labelLarge.copyWith(color: neo.textMain),
        labelMedium: NeoTypography.labelMedium.copyWith(color: neo.textMuted),
        labelSmall: NeoTypography.labelSmall.copyWith(color: neo.textDim),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: neo.bgMain,
        foregroundColor: neo.textMain,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      cardTheme: CardThemeData(
        color: neo.bgCard,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.zero,
        ),
      ),
      dividerTheme: DividerThemeData(
        color: neo.borderColor,
        thickness: 2,
      ),
    );
  }
}

