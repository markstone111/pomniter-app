import 'package:flutter/material.dart';

/// Neo-Brutal color palette for Pomniter.
///
/// These colors directly mirror the website's CSS custom properties,
/// ensuring visual consistency across web and mobile platforms.
abstract final class NeoColors {
  // ─── Primary Accents ───
  /// Bright yellow — primary accent, CTAs, highlights
  static const Color yellow = Color(0xFFFFE156);
  static const Color cyan = Color(0xFF00E5FF);

  /// Vibrant pink — secondary accent, badges
  static const Color pink = Color(0xFFFF6B9D);

  /// Fresh green — success states, confirmations
  static const Color green = Color(0xFF4ADE80);

  /// Rich purple — info, tags, categories
  static const Color purple = Color(0xFFA855F7);

  /// Cool blue — links, interactive elements
  static const Color blue = Color(0xFF60A5FA);

  /// Warm peach — soft accent, warm highlights
  static const Color peach = Color(0xFFFFB088);

  /// Soft lavender — gentle accent, secondary info
  static const Color lavender = Color(0xFFC4B5FD);

  // ─── Neutral Palette (Light Mode) ───
  static const Color black = Color(0xFF121212);
  static const Color darkGray = Color(0xFF1A1A1A);
  static const Color gray800 = Color(0xFF2D2D2D);
  static const Color gray600 = Color(0xFF555555);
  static const Color gray400 = Color(0xFF888888);
  static const Color gray200 = Color(0xFFCCCCCC);
  static const Color gray100 = Color(0xFFE8E8E8);
  static const Color offWhite = Color(0xFFF5F5F0);
  static const Color white = Color(0xFFFFFFFF);

  // ─── Semantic Colors ───
  static const Color error = Color(0xFFEF4444);
  static const Color warning = Color(0xFFEAB308);
  static const Color success = green;
  static const Color info = blue;

  // ─── Background Colors (Light Mode) ───
  static const Color bgMain = offWhite;
  static const Color bgSurface = Color(0xFFEDEDE8);
  static const Color bgCard = white;

  // ─── Background Colors (Dark Mode) ───
  static const Color bgMainDark = Color(0xFF0A0A0A);
  static const Color bgSurfaceDark = Color(0xFF141414);
  static const Color bgCardDark = Color(0xFF1E1E1E);

  // ─── Text Colors (Light Mode) ───
  static const Color textMain = black;
  static const Color textMuted = gray600;
  static const Color textDim = gray400;

  // ─── Text Colors (Dark Mode) ───
  static const Color textMainDark = Color(0xFFE8E8E8);
  static const Color textMutedDark = Color(0xFFAAAAAA);
  static const Color textDimDark = Color(0xFF666666);

  // ─── Border Colors ───
  static const Color borderLight = black;
  static const Color borderDark = white;
}
