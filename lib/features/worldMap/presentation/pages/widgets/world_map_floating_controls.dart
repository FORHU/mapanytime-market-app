import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:mapanytime_market_app/theme/tokens/colors.dart';
import 'package:mapanytime_market_app/theme/tokens/effects.dart';
import 'package:mapanytime_market_app/theme/tokens/radius.dart';
import 'package:mapanytime_market_app/theme/tokens/spacing.dart';

class WorldMapFloatingControls extends StatelessWidget {
  const WorldMapFloatingControls({
    required this.onStyleSelected,
    required this.onLocateMe,
    super.key,
  });

  final ValueChanged<String> onStyleSelected;
  final VoidCallback onLocateMe;

  static const _styles = <(String, String)>[
    ('Streets', 'mapbox://styles/mapbox/streets-v12'),
    ('Satellite', 'mapbox://styles/mapbox/satellite-streets-v12'),
    ('Dark', 'mapbox://styles/mapbox/dark-v11'),
    ('Light', 'mapbox://styles/mapbox/light-v11'),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _CircleControl(
          icon: Icons.my_location_rounded,
          tooltip: 'Locate me',
          onTap: onLocateMe,
        ),
        const Gap(AppSpacing.sm),
        PopupMenuButton<String>(
          tooltip: 'Map style',
          color: AppColors.ui.surface,
          shape: RoundedRectangleBorder(borderRadius: AppRadius.brMd),
          onSelected: onStyleSelected,
          itemBuilder: (context) => [
            for (final style in _styles)
              PopupMenuItem<String>(
                value: style.$2,
                child: Text(
                  style.$1,
                  style: TextStyle(color: AppColors.text.primary),
                ),
              ),
          ],
          child: const _CircleControl(icon: Icons.layers_rounded),
        ),
      ],
    );
  }
}

class _CircleControl extends StatelessWidget {
  const _CircleControl({required this.icon, this.tooltip, this.onTap});

  final IconData icon;
  final String? tooltip;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final button = GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: AppColors.ui.surface,
          shape: BoxShape.circle,
          boxShadow: AppEffects.cardShadow,
        ),
        child: Icon(icon, color: AppColors.text.primary, size: 22),
      ),
    );

    if (tooltip == null) return button;
    return Tooltip(message: tooltip, child: button);
  }
}
