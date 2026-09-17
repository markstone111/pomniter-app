import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'src/app.dart';
import 'src/providers/theme_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();

  // Check first-launch: if privacy not accepted, override the initial route.
  final hasAccepted = prefs.getBool('hasAcceptedPrivacy') ?? false;

  runApp(
    ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        initialRouteProvider.overrideWithValue(hasAccepted ? '/home' : '/privacy'),
      ],
      child: const PomniterApp(),
    ),
  );
}

