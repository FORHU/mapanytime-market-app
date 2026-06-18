import 'package:flutter/material.dart';

import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/helpers.dart';
import '../../../../shared/widgets/app_card.dart';

class WelcomeCard extends StatelessWidget {
  const WelcomeCard({super.key, required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: AppSpacing.edgeInsetsMd,
      child: AppCard(
        child: Row(
          children: [
            const CircleAvatar(child: Icon(Icons.person)),
            AppSpacing.gapMd,
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${Helpers.greeting()},',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  Text(
                    name,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
