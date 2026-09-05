import 'package:flutter/material.dart';
import 'neo_colors.dart';

/// Neo-Brutal border definitions.
///
/// Thick, visible borders are a core characteristic of neo-brutalism.
/// All interactive elements use solid black borders with defined widths.
abstract final class NeoBorders {
  /// Standard border width (2px)
  static const double width = 2.0;

  /// Thick border width (3px) — used for section dividers
  static const double widthThick = 3.0;

  /// Thin border width (1.5px) — used for subtle separators
  static const double widthThin = 1.5;

  /// Standard border radius — neo-brutal uses 0 (sharp corners)
  static const BorderRadius radius = BorderRadius.zero;

  /// Slightly rounded corners for softer elements (badges, chips)
  static final BorderRadius radiusSoft = BorderRadius.circular(4);

  /// Standard border (light mode)
  static Border standard({Color? color}) => Border.all(
        color: color ?? NeoColors.borderLight,
        width: width,
      );

  /// Thick border
  static Border thick({Color? color}) => Border.all(
        color: color ?? NeoColors.borderLight,
        width: widthThick,
      );

  /// Thin border
  static Border thin({Color? color}) => Border.all(
        color: color ?? NeoColors.borderLight,
        width: widthThin,
      );

  /// Bottom-only border (for list items, table rows)
  static Border bottom({Color? color}) => Border(
        bottom: BorderSide(
          color: color ?? NeoColors.borderLight,
          width: width,
        ),
      );
}
