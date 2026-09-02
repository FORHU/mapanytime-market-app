import 'package:flutter/material.dart';
import 'package:mapanytime_market_app/shared/widgets/back_chevron_button.dart';

/// Minimal, transparent app bar with a circular back button and optional
/// actions. Implements [PreferredSizeWidget] for the `Scaffold.appBar` slot.
class ModernAppBar extends StatelessWidget implements PreferredSizeWidget {
  const ModernAppBar({
    this.title,
    this.actions,
    this.showBack = true,
    this.onBack,
    this.centerTitle = false,
    super.key,
  });

  final String? title;
  final List<Widget>? actions;
  final bool showBack;
  final VoidCallback? onBack;
  final bool centerTitle;

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: centerTitle,
      titleSpacing: 8,
      leading: showBack
          ? BackChevronButton(
              onTap: onBack ?? () => Navigator.of(context).maybePop(),
            )
          : null,
      title: title != null
          ? Text(title!, style: Theme.of(context).textTheme.titleLarge)
          : null,
      actions: actions,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
