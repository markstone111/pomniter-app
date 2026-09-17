import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'app_shell.dart';
import '../features/home/home_screen.dart';
import '../features/search/search_screen.dart';
import '../features/gallery/gallery_screen.dart';
import '../features/detail/screenshot_detail_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/onboarding/ml_init_screen.dart';
import '../features/onboarding/privacy_consent_screen.dart';

import '../providers/theme_provider.dart';

final GlobalKey<NavigatorState> _rootNavigatorKey = GlobalKey<NavigatorState>();

/// Riverpod provider that builds the router with the correct initial location.
/// Ensures first-launch users see /privacy before /home.
final appRouterProvider = Provider<GoRouter>((ref) {
  final initialRoute = ref.watch(initialRouteProvider);
  return _buildRouter(initialRoute);
});

/// Legacy top-level export for backward compat — reads /home by default.
/// Prefer [appRouterProvider] in new code.
GoRouter buildAppRouter(String initialLocation) => _buildRouter(initialLocation);

GoRouter _buildRouter(String initialLocation) => GoRouter(
  navigatorKey: _rootNavigatorKey,
  initialLocation: initialLocation,
  routes: [
    // ── Privacy Consent (first-launch, root-level) ────────────────────────
    GoRoute(
      path: '/privacy',
      name: 'privacy',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const PrivacyConsentScreen(),
    ),

    // ── Onboarding / Init ──────────────────────────────────────────────────
    GoRoute(
      path: '/init',
      name: 'init',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) => const MlInitScreen(),
    ),

    // ── Persistent Shell with Motionless Bottom Navigation ────────────────
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) =>
          AppShell(navigationShell: navigationShell),
      branches: [
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/home',
              name: 'home',
              builder: (context, state) => const HomeScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/search',
              name: 'search',
              builder: (context, state) => const SearchScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/gallery',
              name: 'gallery',
              builder: (context, state) => const GalleryScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: [
            GoRoute(
              path: '/settings',
              name: 'settings',
              builder: (context, state) => const SettingsScreen(),
            ),
          ],
        ),
      ],
    ),

    // ── Detail Screen (pushed above shell for true modal back-stack) ───────
    GoRoute(
      path: '/detail/:id',
      name: 'detail',
      parentNavigatorKey: _rootNavigatorKey,
      builder: (context, state) {
        final id = state.pathParameters['id'] ?? '';
        return ScreenshotDetailScreen(screenshotId: id);
      },
    ),
  ],
);
