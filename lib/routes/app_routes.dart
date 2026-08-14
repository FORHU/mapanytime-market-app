import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mapanytime_market_app/core/services/storage_service.dart';
import 'package:mapanytime_market_app/core/utils/context_extensions.dart';
import 'package:mapanytime_market_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:mapanytime_market_app/features/auth/presentation/pages/forgot_password_page.dart';
import 'package:mapanytime_market_app/features/auth/presentation/pages/login_page.dart';
import 'package:mapanytime_market_app/features/auth/presentation/pages/register_page.dart';
import 'package:mapanytime_market_app/features/auth/presentation/pages/register_success_page.dart';
import 'package:mapanytime_market_app/features/auth/presentation/pages/reset_password_page.dart';
import 'package:mapanytime_market_app/features/cart/presentation/pages/cart_page.dart';
import 'package:mapanytime_market_app/features/cart/presentation/pages/checkout_page.dart';
import 'package:mapanytime_market_app/features/home/presentation/pages/home_page.dart';
import 'package:mapanytime_market_app/features/notifications/presentation/pages/notification_feed_page.dart';
import 'package:mapanytime_market_app/features/onboarding/presentation/pages/onboarding_page.dart';
import 'package:mapanytime_market_app/features/orders/domain/entities/buyer_order.dart';
import 'package:mapanytime_market_app/features/orders/presentation/pages/order_confirmation_page.dart';
import 'package:mapanytime_market_app/features/orders/presentation/pages/order_history_page.dart';
import 'package:mapanytime_market_app/features/orders/presentation/pages/order_tracking_page.dart';
import 'package:mapanytime_market_app/features/orders/presentation/pages/pickup_pass_page.dart';
import 'package:mapanytime_market_app/features/profile/presentation/pages/profile_page.dart';
import 'package:mapanytime_market_app/features/recommendations/presentation/pages/recommendations_page.dart';
import 'package:mapanytime_market_app/features/store/domain/entities/merchant_ad.dart';
import 'package:mapanytime_market_app/features/store/domain/entities/store_product.dart';
import 'package:mapanytime_market_app/features/store/presentation/pages/job_posting_detail_page.dart';
import 'package:mapanytime_market_app/features/store/presentation/pages/product_detail_page.dart';
import 'package:mapanytime_market_app/features/store/presentation/pages/storefront_page.dart';
import 'package:mapanytime_market_app/features/worldMap/domain/entities/store_entity.dart';
import 'package:mapanytime_market_app/features/worldMap/presentation/pages/world_map_page.dart';
import 'package:mapanytime_market_app/routes/route_names.dart';
import 'package:mapanytime_market_app/shared/widgets/main_layout.dart';

/// Listenable helper to notify GoRouter whenever auth state changes.
class RouterNotifier extends ChangeNotifier {
  RouterNotifier(this._ref) {
    _ref.listen<AuthState>(
      authControllerProvider,
      (previous, next) {
        if (previous?.isAuthenticated != next.isAuthenticated) {
          notifyListeners();
        }
      },
    );
  }

  final Ref _ref;
}

final routerNotifierProvider = Provider<RouterNotifier>((ref) {
  return RouterNotifier(ref);
});

/// The app's router. `redirect` guards routes based on auth state; the login
/// form and logout button also navigate explicitly with `context.go(...)`.
final goRouterProvider = Provider<GoRouter>((ref) {
  final notifier = ref.watch(routerNotifierProvider);

  return GoRouter(
    initialLocation: RouteNames.home,
    refreshListenable: notifier,
    redirect: (context, state) {
      final isAuth = ref.read(authControllerProvider).isAuthenticated;
      final goingToLogin = state.matchedLocation == RouteNames.login;
      final goingToRegister = state.matchedLocation == RouteNames.register;
      final goingToForgotPassword =
          state.matchedLocation == RouteNames.forgotPassword;
      final goingToResetPassword =
          state.matchedLocation == RouteNames.resetPassword;
      final goingToRegisterSuccess =
          state.matchedLocation == RouteNames.registerSuccess;
      final goingToOnboarding = state.matchedLocation == RouteNames.onboarding;

      if (!isAuth) {
        final goingToAuthFlow =
            goingToLogin ||
            goingToRegister ||
            goingToForgotPassword ||
            goingToResetPassword ||
            goingToRegisterSuccess;
        return goingToAuthFlow ? null : RouteNames.login;
      }

      // First-run onboarding gate: new users (local flag unset) see it once.
      final seenOnboarding = ref.read(storageServiceProvider).onboardingSeen;
      if (!seenOnboarding) {
        return goingToOnboarding ? null : RouteNames.onboarding;
      }
      if (goingToOnboarding) return RouteNames.home;

      if (goingToLogin ||
          goingToRegister ||
          goingToForgotPassword ||
          goingToResetPassword ||
          goingToRegisterSuccess) {
        return RouteNames.home;
      }
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
        path: RouteNames.registerSuccess,
        builder: (context, state) => const RegisterSuccessPage(),
      ),
      GoRoute(
        path: RouteNames.forgotPassword,
        builder: (context, state) => const ForgotPasswordPage(),
      ),
      GoRoute(
        path: RouteNames.resetPassword,
        builder: (context, state) {
          final email = state.extra as String?;
          if (email == null) {
            return Scaffold(
              body: Center(child: Text(context.l10n.errorNoEmail)),
            );
          }
          return ResetPasswordPage(email: email);
        },
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
            builder: (context, state) => const HomePage(),
          ),
          GoRoute(
            path: RouteNames.recommendations,
            builder: (context, state) => const RecommendationsPage(),
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
            path: RouteNames.orderConfirmation,
            builder: (context, state) {
              final orderId = state.extra as String?;
              if (orderId == null) {
                return Scaffold(
                  body: Center(child: Text(context.l10n.errorNoOrderId)),
                );
              }
              return OrderConfirmationPage(orderId: orderId);
            },
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
                return Scaffold(
                  body: Center(child: Text(context.l10n.errorNoOrder)),
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
                return Scaffold(
                  body: Center(child: Text(context.l10n.errorNoOrder)),
                );
              }
              return PickupPassPage(order: order);
            },
          ),
          GoRoute(
            path: RouteNames.notifications,
            builder: (context, state) => const NotificationFeedPage(),
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
                return Scaffold(
                  body: Center(child: Text(context.l10n.errorNoStore)),
                );
              }
              return StorefrontPage(store: store);
            },
          ),
          GoRoute(
            path: RouteNames.productDetail,
            builder: (context, state) {
              final args =
                  state.extra
                      as ({
                        StoreProduct product,
                        String storeId,
                        String storeName,
                        MerchantAd? promo,
                      })?;
              if (args == null) {
                return Scaffold(
                  body: Center(child: Text(context.l10n.errorNoProduct)),
                );
              }
              return ProductDetailPage(
                product: args.product,
                storeId: args.storeId,
                storeName: args.storeName,
                promo: args.promo,
              );
            },
          ),
          GoRoute(
            path: RouteNames.jobPostingDetail,
            builder: (context, state) {
              final args =
                  state.extra
                      as ({MerchantAd ad, String storeId, String storeName})?;
              if (args == null) {
                return const Scaffold(
                  body: Center(child: Text('Error: No job posting provided')),
                );
              }
              return JobPostingDetailPage(
                ad: args.ad,
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
