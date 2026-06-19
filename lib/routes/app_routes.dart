import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mapanytime_market_web/features/auth/presentation/controllers/auth_controller.dart';
import 'package:mapanytime_market_web/features/auth/presentation/pages/login_page.dart';
import 'package:mapanytime_market_web/features/home/presentation/pages/home_page.dart';
import 'package:mapanytime_market_web/features/profile/presentation/pages/profile_page.dart';
import 'package:mapanytime_market_web/routes/route_names.dart';
import 'package:mapanytime_market_web/shared/widgets/main_layout.dart';
import 'package:go_router/go_router.dart';
import 'package:mapanytime_market_web/features/worldMap/presentation/pages/world_map_page.dart';

/// The app's router. `redirect` guards routes based on auth state; the login
/// form and logout button also navigate explicitly with `context.go(...)`.
final goRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: RouteNames.home,
    redirect: (context, state) {
      final isAuth = ref.read(authControllerProvider).isAuthenticated;
      final goingToLogin = state.matchedLocation == RouteNames.login;

      if (!isAuth) return goingToLogin ? null : RouteNames.login;
      if (goingToLogin) return RouteNames.home;
      return null;
    },
    routes: [
      GoRoute(
        path: RouteNames.login,
        builder: (context, state) => const LoginPage(),
      ),
      ShellRoute(
        builder: (context, state, child) => MainLayout(child: child),
        routes: [
          GoRoute(
            path: RouteNames.home,
            builder: (context, state) => const HomePage(),
          ),
          // Example of a route with children
          GoRoute(
            path: RouteNames.recommendations,
            // Assuming you'd have a RecommendationsPage here
            builder: (context, state) =>
                const Scaffold(body: Center(child: Text('Recommendations'))),
            routes: [
              // Child route: /recommendations/details
              // Note: Do not start child paths with a slash '/'
              GoRoute(
                path: 'details',
                // Assuming you'd have a DetailsPage here
                builder: (context, state) =>
                    const Scaffold(body: Center(child: Text('Details'))),
              ),
            ],
          ),
          GoRoute(
            path: RouteNames.worldMap,
            builder: (context, state) => const WorldMapPage(),
          ),
          GoRoute(
            path: RouteNames.cart,
            builder: (context, state) =>
                const Scaffold(body: Center(child: Text('Cart'))),
          ),
          GoRoute(
            path: RouteNames.profile,
            builder: (context, state) => const ProfilePage(),
          ),
        ],
      ),
    ],
  );
});
