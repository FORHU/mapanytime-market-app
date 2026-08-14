import 'package:flutter/material.dart';
import 'package:mapanytime_market_app/theme/tokens/radius.dart';

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
          ? Padding(
              padding: const EdgeInsets.only(left: 12),
              child: _CircleIconButton(
                icon: Icons.arrow_back_ios_new_rounded,
                onTap: onBack ?? () => Navigator.of(context).maybePop(),
              ),
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

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({required this.icon, required this.onTap});

  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: AppRadius.brPill,
          border: Border.all(color: colors.outline),
        ),
        child: Icon(icon, size: 18, color: colors.onSurface),
      ),
    );
  }
}
