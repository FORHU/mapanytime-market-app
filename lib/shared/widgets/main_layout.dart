import 'package:flutter/material.dart';
import 'package:mapanytime_market_web/core/utils/context_extensions.dart';
import 'package:mapanytime_market_web/routes/route_names.dart';
import 'package:go_router/go_router.dart';

class MainLayout extends StatelessWidget {
  const MainLayout({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    // 1. Define items WITH their corresponding route paths
    final navItems = [
      NavigationItem(
        label: context.l10n.home,
        icon: Icons.home_outlined,
        activeIcon: Icons.home,
        order: 0,
        route: RouteNames.home,
        activeColor: Colors.greenAccent, // 👈 Custom active color for this tab
      ),
      const NavigationItem(
        label: 'For You',
        icon: Icons.star_outline,
        activeIcon: Icons.star,
        order: 1,
        route: RouteNames.recommendations,
        activeColor: Colors.amber, // 👈 Custom active color for this tab
      ),
      const NavigationItem(
        label: 'World Map',
        icon: Icons.map_outlined,
        activeIcon: Icons.map,
        order: 2,
        route: RouteNames.worldMap,
        activeColor: Colors.blue, // 👈 Custom active color for this tab
      ),
      const NavigationItem(
        label: 'Cart',
        icon: Icons.shopping_cart_outlined,
        activeIcon: Icons.shopping_cart,
        order: 3,
        route: RouteNames.cart,
        activeColor: Colors.orangeAccent,
      ),
      NavigationItem(
        label: context.l10n.profile,
        icon: Icons.person_outline,
        activeIcon: Icons.person,
        order: 4,
        route: RouteNames.profile,
        activeColor: Colors.deepPurpleAccent,
      ),
    ];

    // Sort the items by the new order property
    navItems.sort((a, b) => a.order.compareTo(b.order));

    // Calculate current index dynamically based on the current location
    final location = GoRouterState.of(context).matchedLocation;
    // We check backwards or specifically to ensure we find the right match (ignoring default '/')
    int currentIndex = navItems.indexWhere(
      (item) => item.route != '/' && location.startsWith(item.route),
    );

    // If not found (or it's the root '/'), default to index of Home
    if (currentIndex == -1) {
      currentIndex = navItems.indexWhere(
        (item) => item.route == RouteNames.home,
      );
      if (currentIndex == -1) currentIndex = 0; // Fallback
    }

    return Scaffold(
      body: child,
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType
            .fixed, // Ensure all items show properly when > 3
        currentIndex: currentIndex,
        onTap: (index) {
          // Navigate dynamically based on the tapped item's route
          context.go(navItems[index].route);
        },
        selectedItemColor: Colors.black, // 👈 selected icon color
        unselectedItemColor: Colors.black,
        // Map your custom NavigationItems into BottomNavigationBarItems
        items: navItems.map((item) {
          return BottomNavigationBarItem(
            // NOTE: BottomNavigationBarItem does not accept a 'key' parameter since it's not a Widget.
            icon: Icon(item.icon),
            activeIcon: Icon(
              item.activeIcon,
              color: item.activeColor, // Apply the custom color if it exists
            ),
            label: item.label,
          );
        }).toList(),
      ),
    );
  }
}

// Define your custom data class at the bottom of the file
class NavigationItem {
  const NavigationItem({
    required this.label,
    required this.icon,
    required this.activeIcon,
    required this.order,
    required this.route,
    this.activeColor, // Optional custom color when selected
  });

  final String label;
  final IconData icon;
  final IconData activeIcon;
  final int order;
  final String route;
  final Color? activeColor;
}
