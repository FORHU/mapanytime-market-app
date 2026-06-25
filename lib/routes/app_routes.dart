import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mapanytime_market_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:mapanytime_market_app/features/auth/presentation/pages/login_page.dart';
import 'package:mapanytime_market_app/features/auth/presentation/pages/register_page.dart';
import 'package:mapanytime_market_app/features/home/presentation/pages/home_page.dart';
import 'package:mapanytime_market_app/features/profile/presentation/pages/profile_page.dart';
import 'package:mapanytime_market_app/features/worldMap/presentation/pages/world_map_page.dart';
import 'package:mapanytime_market_app/routes/route_names.dart';
import 'package:mapanytime_market_app/shared/widgets/main_layout.dart';

/// The app's router. `redirect` guards routes based on auth state; the login
/// form and logout button also navigate explicitly with `context.go(...)`.
final goRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: RouteNames.home,
    redirect: (context, state) {
      final isAuth = ref.read(authControllerProvider).isAuthenticated;
      final goingToLogin = state.matchedLocation == RouteNames.login;
      final goingToRegister = state.matchedLocation == RouteNames.register;

      if (!isAuth) {
        return (goingToLogin || goingToRegister) ? null : RouteNames.login;
      }
      if (goingToLogin || goingToRegister) return RouteNames.home;
      return null;
    },
    routes: [
      GoRoute(
        path: RouteNames.login,
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: RouteNames.register,
        builder: (context, state) => const RegisterPage(),
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
