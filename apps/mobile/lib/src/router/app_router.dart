import 'package:go_router/go_router.dart';
import '../features/home/home_screen.dart';
import '../features/search/search_screen.dart';
import '../features/gallery/gallery_screen.dart';
import '../features/detail/screenshot_detail_screen.dart';
import '../features/settings/settings_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/home',
  routes: [
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
