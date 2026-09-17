import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pomniter_design_system/pomniter_design_system.dart';
import 'package:shared_preferences/shared_preferences.dart';

const String _kThemeKey = 'pomniter_theme_mode';

/// SharedPreferences instance provider, overridden at app startup.
final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('sharedPreferencesProvider must be overridden in ProviderScope');
});

/// StateNotifier that keeps ThemeMode synchronized with persistent storage.
class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  final SharedPreferences _prefs;

  ThemeModeNotifier(this._prefs) : super(_loadInitialMode(_prefs));

  static ThemeMode _loadInitialMode(SharedPreferences prefs) {
    final saved = prefs.getString(_kThemeKey);
    if (saved == 'dark') return ThemeMode.dark;
    if (saved == 'light') return ThemeMode.light;
    return ThemeMode.light;
  }

  Future<void> setMode(ThemeMode mode) async {
    if (state == mode) return;
    state = mode;
    await _prefs.setString(_kThemeKey, mode == ThemeMode.dark ? 'dark' : 'light');
  }

  Future<void> toggle() async {
    await setMode(state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark);
  }
}

/// Global provider for active ThemeMode.
final themeModeProvider =
    StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return ThemeModeNotifier(prefs);
});

/// Resolved NeoThemeData based on active ThemeMode.
final neoThemeProvider = Provider<NeoThemeData>((ref) {
  final mode = ref.watch(themeModeProvider);
  return mode == ThemeMode.dark ? NeoThemeData.dark : NeoThemeData.light;
});

/// The initial route for the app — set at startup based on whether the
/// user has previously accepted the privacy consent screen.
/// Overridden in [ProviderScope] from [main.dart].
final initialRouteProvider = Provider<String>((ref) => '/home');
