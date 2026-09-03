import 'package:flutter/material.dart';

/// The one deliberate exception to the app's solid-ink circular icon-button
/// shape: a bare chevron with no fill, used only for back navigation. See
/// DESIGN.md's "Icon Buttons" section.
class BackChevronButton extends StatelessWidget {
  const BackChevronButton({required this.onTap, super.key});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      icon: Icon(
        Icons.arrow_back_ios_new_rounded,
        size: 20,
        color: Theme.of(context).colorScheme.onSurface,
      ),
    );
  }
}
