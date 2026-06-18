import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/features/auth/presentation/controllers/auth_controller.dart';
import 'package:flutter_template/features/auth/presentation/pages/login_page.dart';
import 'package:flutter_template/features/home/presentation/pages/home_page.dart';
import 'package:flutter_template/features/profile/presentation/pages/profile_page.dart';
import 'package:flutter_template/routes/route_names.dart';
import 'package:go_router/go_router.dart';

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
      GoRoute(
        path: RouteNames.home,
        builder: (context, state) => const HomePage(),
      ),
      GoRoute(
        path: RouteNames.profile,
        builder: (context, state) => const ProfilePage(),
      ),
    ],
  );
});
