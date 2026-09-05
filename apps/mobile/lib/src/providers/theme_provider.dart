import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pomniter_design_system/pomniter_design_system.dart';

/// Provider managing active ThemeMode (light or dark).
final themeModeProvider = StateProvider<ThemeMode>((ref) => ThemeMode.light);

/// Resolved NeoThemeData based on active ThemeMode.
final neoThemeProvider = Provider<NeoThemeData>((ref) {
  final mode = ref.watch(themeModeProvider);
  return mode == ThemeMode.dark ? NeoThemeData.dark : NeoThemeData.light;
});
