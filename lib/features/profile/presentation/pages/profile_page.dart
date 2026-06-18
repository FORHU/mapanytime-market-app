import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:flutter_template/core/utils/context_extensions.dart';
import 'package:flutter_template/features/profile/controllers/profile_controller.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(profileProvider);
    final initial = (user?.name.isNotEmpty ?? false)
        ? user!.name[0].toUpperCase()
        : '?';

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.profile)),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 40,
              child: Text(initial, style: const TextStyle(fontSize: 32)),
            ),
            const SizedBox(height: 16),
            Text(
              user?.name ?? 'Unknown',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 4),
            Text(user?.email ?? '-'),
          ],
        ),
      ),
    );
  }
}
