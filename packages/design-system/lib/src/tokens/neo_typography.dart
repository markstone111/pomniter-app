import 'package:flutter/material.dart';

/// Neo-Brutal typography scale for Pomniter.
///
/// Uses Space Grotesk for headings and body text (bold, geometric),
/// and JetBrains Mono for code/technical text (monospace).
/// Falls back to system fonts until custom fonts are bundled.
abstract final class NeoTypography {
  // ─── Font Families ───
  static const String fontHeading = 'SpaceGrotesk';
  static const String fontBody = 'SpaceGrotesk';
  static const String fontMono = 'JetBrainsMono';

  // ─── System Fallbacks ───
  static const List<String> headingFallbacks = ['Inter', 'Roboto', 'sans-serif'];
  static const List<String> monoFallbacks = ['Fira Code', 'Courier New', 'monospace'];

  // ─── Heading Styles ───
  static const TextStyle displayLarge = TextStyle(
    fontFamily: fontHeading,
    fontSize: 48,
    fontWeight: FontWeight.w900,
    height: 1.05,
    letterSpacing: -1.5,
  );

  static const TextStyle displayMedium = TextStyle(
    fontFamily: fontHeading,
    fontSize: 36,
    fontWeight: FontWeight.w900,
    height: 1.1,
    letterSpacing: -1.0,
  );

  static const TextStyle displaySmall = TextStyle(
    fontFamily: fontHeading,
    fontSize: 28,
    fontWeight: FontWeight.w800,
    height: 1.15,
    letterSpacing: -0.5,
  );

  static const TextStyle headlineLarge = TextStyle(
    fontFamily: fontHeading,
    fontSize: 24,
    fontWeight: FontWeight.w800,
    height: 1.2,
    letterSpacing: -0.3,
  );

  static const TextStyle headlineMedium = TextStyle(
    fontFamily: fontHeading,
    fontSize: 20,
    fontWeight: FontWeight.w700,
    height: 1.25,
  );

  static const TextStyle headlineSmall = TextStyle(
    fontFamily: fontHeading,
    fontSize: 18,
    fontWeight: FontWeight.w700,
    height: 1.3,
  );

  // ─── Body Styles ───
  static const TextStyle bodyLarge = TextStyle(
    fontFamily: fontBody,
    fontSize: 16,
    fontWeight: FontWeight.w500,
    height: 1.6,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontFamily: fontBody,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  static const TextStyle bodySmall = TextStyle(
    fontFamily: fontBody,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  // ─── Label / Button Styles ───
  static const TextStyle labelLarge = TextStyle(
    fontFamily: fontHeading,
    fontSize: 14,
    fontWeight: FontWeight.w800,
    height: 1.2,
    letterSpacing: 0.8,
  );

  static const TextStyle labelMedium = TextStyle(
    fontFamily: fontHeading,
    fontSize: 12,
    fontWeight: FontWeight.w700,
    height: 1.2,
    letterSpacing: 0.5,
  );

  static const TextStyle labelSmall = TextStyle(
    fontFamily: fontHeading,
    fontSize: 10,
    fontWeight: FontWeight.w700,
    height: 1.2,
    letterSpacing: 1.0,
  );

  // ─── Mono / Code Styles ───
  static const TextStyle codeLarge = TextStyle(
    fontFamily: fontMono,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.5,
  );

  static const TextStyle codeMedium = TextStyle(
    fontFamily: fontMono,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    height: 1.5,
  );

  static const TextStyle codeSmall = TextStyle(
    fontFamily: fontMono,
    fontSize: 10,
    fontWeight: FontWeight.w400,
    height: 1.4,
  );
}
