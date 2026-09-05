import 'package:flutter/material.dart';
import 'neo_colors.dart';

/// Neo-Brutal shadow definitions.
///
/// Hard, offset drop shadows with zero blur are the defining visual
/// characteristic of neo-brutalism. They create a stacked paper/sticker
/// effect that makes elements feel tactile and physical.
abstract final class NeoShadows {
  /// Small shadow (3px offset) — buttons, badges, small cards
  static List<BoxShadow> sm({Color? color}) => [
        BoxShadow(
          color: color ?? NeoColors.black,
          offset: const Offset(3, 3),
          blurRadius: 0,
          spreadRadius: 0,
        ),
      ];

  /// Medium shadow (4px offset) — cards, containers
  static List<BoxShadow> md({Color? color}) => [
        BoxShadow(
          color: color ?? NeoColors.black,
          offset: const Offset(4, 4),
          blurRadius: 0,
          spreadRadius: 0,
        ),
      ];

  /// Large shadow (6px offset) — modals, prominent cards
  static List<BoxShadow> lg({Color? color}) => [
        BoxShadow(
          color: color ?? NeoColors.black,
          offset: const Offset(6, 6),
          blurRadius: 0,
          spreadRadius: 0,
        ),
      ];

  /// Pressed state shadow (1px offset) — active/pressed buttons
  static List<BoxShadow> pressed({Color? color}) => [
        BoxShadow(
          color: color ?? NeoColors.black,
          offset: const Offset(1, 1),
          blurRadius: 0,
          spreadRadius: 0,
        ),
      ];

  /// No shadow — for flat elements
  static const List<BoxShadow> none = [];
}
