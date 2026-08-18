import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mapanytime_market_app/core/utils/context_extensions.dart';
import 'package:mapanytime_market_app/features/cart/presentation/controllers/cart_controller.dart';
import 'package:mapanytime_market_app/routes/route_names.dart';
import 'package:mapanytime_market_app/shared/widgets/animated_bottom_navigation.dart';

/// App shell: hosts the routed [child] and the floating bottom navigation.
class MainLayout extends ConsumerStatefulWidget {
  const MainLayout({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends ConsumerState<MainLayout> {
  bool _navCompact = false;
  String? _prevLocation;

  bool _onScroll(ScrollNotification notification) {
    if (notification is ScrollUpdateNotification &&
        notification.metrics.axis == Axis.vertical) {
      final delta = notification.scrollDelta ?? 0;
      if (delta > 1 && !_navCompact) {
        setState(() => _navCompact = true);
      } else if (delta < -1 && _navCompact) {
        setState(() => _navCompact = false);
      }
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final cartHasUnseen = ref.watch(cartHasUnseenProvider);
    final destinations = <_Destination>[
      _Destination(
        item: NavBarItem(
          label: context.l10n.home,
          icon: Icons.home_outlined,
          activeIcon: Icons.home_rounded,
        ),
        route: RouteNames.home,
      ),
      const _Destination(
        item: NavBarItem(
          label: 'For You',
          icon: Icons.auto_awesome_outlined,
          activeIcon: Icons.auto_awesome_rounded,
        ),
        route: RouteNames.recommendations,
      ),
      const _Destination(
        item: NavBarItem(
          label: 'Map',
          icon: Icons.map_outlined,
          activeIcon: Icons.map_rounded,
        ),
        route: RouteNames.worldMap,
      ),
      _Destination(
        item: NavBarItem(
          label: 'Cart',
          icon: Icons.shopping_bag_outlined,
          activeIcon: Icons.shopping_bag_rounded,
          showBadge: cartHasUnseen,
        ),
        route: RouteNames.cart,
      ),
      _Destination(
        item: NavBarItem(
          label: context.l10n.profile,
          icon: Icons.person_outline_rounded,
          activeIcon: Icons.person_rounded,
        ),
        route: RouteNames.profile,
      ),
    ];

    final location = GoRouterState.of(context).matchedLocation;
    if (_prevLocation != null && _prevLocation != location && _navCompact) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) setState(() => _navCompact = false);
      });
    }
    _prevLocation = location;

    var currentIndex = destinations.indexWhere(
      (d) => d.route != '/' && location.startsWith(d.route),
    );
    if (location == RouteNames.orders ||
        location.startsWith(RouteNames.orders) ||
        location == RouteNames.orderTracking ||
        location == RouteNames.pickupPass) {
      currentIndex = destinations.indexWhere(
        (d) => d.route == RouteNames.profile,
      );
    }
    if (currentIndex == -1) {
      currentIndex = destinations.indexWhere((d) => d.route == RouteNames.home);
      if (currentIndex == -1) currentIndex = 0;
    }

    return Scaffold(
      extendBody: true,
      body: NotificationListener<ScrollNotification>(
        onNotification: _onScroll,
        child: widget.child,
      ),
      bottomNavigationBar: AnimatedBottomNavigation(
        items: [for (final d in destinations) d.item],
        currentIndex: currentIndex,
        isCompact: _navCompact,
        onTap: (index) => context.go(destinations[index].route),
      ),
    );
  }
}

class _Destination {
  const _Destination({required this.item, required this.route});

  final NavBarItem item;
  final String route;
}
