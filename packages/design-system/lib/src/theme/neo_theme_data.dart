import 'package:flutter/material.dart';
import '../tokens/neo_colors.dart';

/// Holds the resolved Neo-Brutal theme data for the current mode.
///
/// Access via [NeoTheme.of(context)] in widget tree.
class NeoThemeData {
  final Color bgMain;
  final Color bgSurface;
  final Color bgCard;
  final Color textMain;
  final Color textMuted;
  final Color textDim;
  final Color borderColor;
  final Color shadowColor;
  final Brightness brightness;

  const NeoThemeData({
    required this.bgMain,
    required this.bgSurface,
    required this.bgCard,
    required this.textMain,
    required this.textMuted,
    required this.textDim,
    required this.borderColor,
    required this.shadowColor,
    required this.brightness,
  });

  /// Light mode theme data
  static const NeoThemeData light = NeoThemeData(
    bgMain: NeoColors.bgMain,
    bgSurface: NeoColors.bgSurface,
    bgCard: NeoColors.bgCard,
    textMain: NeoColors.textMain,
    textMuted: NeoColors.textMuted,
    textDim: NeoColors.textDim,
    borderColor: NeoColors.borderLight,
    shadowColor: NeoColors.black,
    brightness: Brightness.light,
  );

  /// Dark mode theme data
  static const NeoThemeData dark = NeoThemeData(
    bgMain: NeoColors.bgMainDark,
    bgSurface: NeoColors.bgSurfaceDark,
    bgCard: NeoColors.bgCardDark,
    textMain: NeoColors.textMainDark,
    textMuted: NeoColors.textMutedDark,
    textDim: NeoColors.textDimDark,
    borderColor: NeoColors.borderDark,
    shadowColor: NeoColors.white,
    brightness: Brightness.dark,
  );

  bool get isDark => brightness == Brightness.dark;
}
