import 'package:go_router/go_router.dart';

import 'models.dart';
import 'screens/credits_screen.dart';
import 'screens/end_screen.dart';
import 'screens/landing_screen.dart';
import 'screens/scene_screen.dart';

/// Builds the app router. QR codes deep-link to `/stop/:id`; unknown ids (a
/// mistyped or stale QR) redirect gracefully to the landing screen.
GoRouter buildRouter(Story story) {
  return GoRouter(
    initialLocation: '/',
    routes: [
      GoRoute(
        path: '/',
        builder: (context, state) => LandingScreen(story: story),
      ),
      GoRoute(
        path: '/stop/:id',
        redirect: (context, state) {
          final id = state.pathParameters['id'];
          if (id == 'end') return '/end';
          if (id == null || !story.has(id)) return '/';
          return null;
        },
        builder: (context, state) =>
            SceneScreen(story: story, nodeId: state.pathParameters['id']!),
      ),
      GoRoute(
        path: '/end',
        builder: (context, state) => EndScreen(story: story),
      ),
      GoRoute(
        path: '/credits',
        builder: (context, state) => CreditsScreen(story: story),
      ),
    ],
    errorBuilder: (context, state) => LandingScreen(story: story),
  );
}
