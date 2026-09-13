import 'package:go_router/go_router.dart';

import '../features/home/home_screen.dart';
import '../features/search/search_screen.dart';
import '../features/gallery/gallery_screen.dart';
import '../features/detail/screenshot_detail_screen.dart';
import '../features/settings/settings_screen.dart';
import '../features/onboarding/ml_init_screen.dart';

final appRouter = GoRouter(
  // Start at home by default; the app checks model readiness and redirects
  // to /init on first launch via the model_ready_provider guard.
  initialLocation: '/home',
  routes: [
    // ── Onboarding / Init ──────────────────────────────────────────────────
    GoRoute(
      path: '/init',
      name: 'init',
      builder: (context, state) => const MlInitScreen(),
    ),

    // ── Core Screens ───────────────────────────────────────────────────────
    GoRoute(
      path: '/home',
      name: 'home',
      builder: (context, state) => const HomeScreen(),
    ),
    GoRoute(
      path: '/search',
      name: 'search',
      builder: (context, state) => const SearchScreen(),
    ),
    GoRoute(
      path: '/gallery',
      name: 'gallery',
      builder: (context, state) => const GalleryScreen(),
    ),
    GoRoute(
      path: '/detail/:id',
      name: 'detail',
      builder: (context, state) {
        final id = state.pathParameters['id'] ?? '';
        return ScreenshotDetailScreen(screenshotId: id);
      },
    ),
    GoRoute(
      path: '/settings',
      name: 'settings',
      builder: (context, state) => const SettingsScreen(),
    ),
  ],
);
