import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mapanytime_market_app/core/services/storage_service.dart';
import 'package:mapanytime_market_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:mapanytime_market_app/features/auth/presentation/pages/login_page.dart';
import 'package:mapanytime_market_app/features/auth/presentation/pages/register_page.dart';
import 'package:mapanytime_market_app/features/cart/presentation/pages/cart_page.dart';
import 'package:mapanytime_market_app/features/cart/presentation/pages/checkout_page.dart';
import 'package:mapanytime_market_app/features/landing/presentation/pages/landing_page.dart';
import 'package:mapanytime_market_app/features/onboarding/presentation/pages/onboarding_page.dart';
import 'package:mapanytime_market_app/features/orders/domain/entities/buyer_order.dart';
import 'package:mapanytime_market_app/features/orders/presentation/pages/order_history_page.dart';
import 'package:mapanytime_market_app/features/orders/presentation/pages/order_tracking_page.dart';
import 'package:mapanytime_market_app/features/orders/presentation/pages/pickup_pass_page.dart';
import 'package:mapanytime_market_app/features/profile/presentation/pages/profile_page.dart';
import 'package:mapanytime_market_app/features/store/domain/entities/store_product.dart';
import 'package:mapanytime_market_app/features/store/presentation/pages/product_detail_page.dart';
import 'package:mapanytime_market_app/features/store/presentation/pages/storefront_page.dart';
import 'package:mapanytime_market_app/features/worldMap/domain/entities/store_entity.dart';
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
      final goingToOnboarding =
          state.matchedLocation == RouteNames.onboarding;

      if (!isAuth) {
        return (goingToLogin || goingToRegister) ? null : RouteNames.login;
      }

      // First-run onboarding gate: new users (local flag unset) see it once.
      final seenOnboarding = ref.read(storageServiceProvider).onboardingSeen;
      if (!seenOnboarding) {
        return goingToOnboarding ? null : RouteNames.onboarding;
      }
      if (goingToOnboarding) return RouteNames.home;

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
      GoRoute(
        path: RouteNames.onboarding,
        builder: (context, state) => const OnboardingPage(),
      ),
      ShellRoute(
        builder: (context, state, child) => MainLayout(child: child),
        routes: [
          GoRoute(
            path: RouteNames.home,
            builder: (context, state) => const LandingPage(),
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
            builder: (context, state) => const CartPage(),
          ),
          GoRoute(
            path: RouteNames.checkout,
            builder: (context, state) => const CheckoutPage(),
          ),
          GoRoute(
            path: RouteNames.orders,
            builder: (context, state) => const OrderHistoryPage(),
          ),
          GoRoute(
            path: RouteNames.orderTracking,
            builder: (context, state) {
              final order = state.extra as BuyerOrder?;
              if (order == null) {
                return const Scaffold(
                  body: Center(child: Text('Error: No order provided')),
                );
              }
              return OrderTrackingPage(order: order);
            },
          ),
          GoRoute(
            path: RouteNames.pickupPass,
            builder: (context, state) {
              final order = state.extra as BuyerOrder?;
              if (order == null) {
                return const Scaffold(
                  body: Center(child: Text('Error: No order provided')),
                );
              }
              return PickupPassPage(order: order);
            },
          ),
          GoRoute(
            path: RouteNames.profile,
            builder: (context, state) => const ProfilePage(),
          ),
          GoRoute(
            path: RouteNames.storefront,
            builder: (context, state) {
              final store = state.extra as StoreEntity?;
              if (store == null) {
                return const Scaffold(
                  body: Center(child: Text('Error: No store provided')),
                );
              }
              return StorefrontPage(store: store);
            },
          ),
          GoRoute(
            path: RouteNames.productDetail,
            builder: (context, state) {
              final args = state.extra
                  as ({
                    StoreProduct product,
                    String storeId,
                    String storeName,
                  })?;
              if (args == null) {
                return const Scaffold(
                  body: Center(child: Text('Error: No product provided')),
                );
              }
              return ProductDetailPage(
                product: args.product,
                storeId: args.storeId,
                storeName: args.storeName,
              );
            },
          ),
        ],
      ),
    ],
  );
});
