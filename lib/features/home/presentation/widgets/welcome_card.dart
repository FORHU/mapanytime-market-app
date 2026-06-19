import 'package:flutter/material.dart';

import 'package:mapanytime_market_web/theme/tokens/spacing.dart';
import 'package:mapanytime_market_web/core/utils/helpers.dart';
import 'package:mapanytime_market_web/shared/widgets/app_card.dart';

class WelcomeCard extends StatelessWidget {
  const WelcomeCard({required this.name, super.key});

  final String name;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: AppSpacing.edgeInsetsMd,
      child: AppCard(
        child: Row(
          children: [
            const CircleAvatar(child: Icon(Icons.person)),
            AppSpacing.md.v,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${Helpers.greeting()},',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  Text(name, style: Theme.of(context).textTheme.titleMedium),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
