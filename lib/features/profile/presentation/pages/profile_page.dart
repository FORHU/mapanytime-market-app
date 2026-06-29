import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:mapanytime_market_app/core/utils/context_extensions.dart';
import 'package:mapanytime_market_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:mapanytime_market_app/features/profile/presentation/controllers/profile_controller.dart';
import 'package:mapanytime_market_app/routes/route_names.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(profileProvider);
    final initial = (user?.name?.isNotEmpty ?? false)
        ? user!.name![0].toUpperCase()
        : '?';

    return Scaffold(
      appBar: AppBar(title: Text(context.l10n.profile)),
      body: Center(
        child: SingleChildScrollView(
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
              const SizedBox(height: 32),
              ListTile(
                leading: const Icon(Icons.receipt_long_rounded),
                title: const Text('My Orders'),
                subtitle: const Text('Track and view past orders'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => context.push(RouteNames.orders),
              ),
              // TODO(revert): temporary dev entry to the component gallery.
              ListTile(
                leading: const Icon(Icons.palette_outlined),
                title: const Text('Component Gallery'),
                subtitle: const Text('Preview the design system'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => context.go(RouteNames.gallery),
              ),
              ListTile(
                leading: const Icon(Icons.logout_rounded),
                title: Text(context.l10n.logout),
                onTap: () async {
                  await ref.read(authControllerProvider.notifier).logout();
                  if (context.mounted) context.go(RouteNames.login);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
