import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pomniter_design_system/pomniter_design_system.dart';
import 'providers/theme_provider.dart';
import 'router/app_router.dart';

class PomniterApp extends ConsumerWidget {
  const PomniterApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final neoThemeData = ref.watch(neoThemeProvider);

    return NeoTheme(
      data: neoThemeData,
      child: MaterialApp.router(
        title: 'Pomniter',
        debugShowCheckedModeBanner: false,
        theme: NeoTheme.toMaterialTheme(NeoThemeData.light),
        darkTheme: NeoTheme.toMaterialTheme(NeoThemeData.dark),
        themeMode: neoThemeData.isDark ? ThemeMode.dark : ThemeMode.light,
        routerConfig: appRouter,
      ),
    );
  }
}
