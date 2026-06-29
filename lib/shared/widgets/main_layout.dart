import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mapanytime_market_app/core/utils/context_extensions.dart';
import 'package:mapanytime_market_app/routes/route_names.dart';
import 'package:mapanytime_market_app/shared/widgets/animated_bottom_navigation.dart';

/// App shell: hosts the routed [child] and the premium glass bottom navigation.
class MainLayout extends StatelessWidget {
  const MainLayout({
    required this.child,
    super.key,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    // Tab destinations paired with their routes (order = tab order).
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
      const _Destination(
        item: NavBarItem(
          label: 'Cart',
          icon: Icons.shopping_bag_outlined,
          activeIcon: Icons.shopping_bag_rounded,
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

    // Resolve the active tab from the current route (ignoring root '/').
    final location = GoRouterState.of(context).matchedLocation;
    var currentIndex = destinations.indexWhere(
      (d) => d.route != '/' && location.startsWith(d.route),
    );
    if (currentIndex == -1) {
      currentIndex = destinations.indexWhere(
        (d) => d.route == RouteNames.home,
      );
      if (currentIndex == -1) currentIndex = 0;
    }

    return Scaffold(
      body: child,
      bottomNavigationBar: AnimatedBottomNavigation(
        items: [for (final d in destinations) d.item],
        currentIndex: currentIndex,
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
