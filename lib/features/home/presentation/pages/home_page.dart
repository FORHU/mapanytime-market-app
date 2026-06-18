import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_template/core/utils/context_extensions.dart';
import 'package:flutter_template/features/auth/presentation/controllers/auth_controller.dart';
import 'package:flutter_template/features/home/presentation/controllers/home_controller.dart';
import 'package:flutter_template/features/home/presentation/widgets/welcome_card.dart';
import 'package:flutter_template/routes/route_names.dart';
import 'package:go_router/go_router.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final count = ref.watch(homeControllerProvider);
    final user = ref.watch(authControllerProvider).user;

    return Scaffold(
      appBar: AppBar(
        title: Text(context.l10n.home),
        actions: [
          IconButton(
            tooltip: context.l10n.profile,
            icon: const Icon(Icons.person_outline),
            onPressed: () => context.push(RouteNames.profile),
          ),
          IconButton(
            tooltip: context.l10n.logout,
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await ref.read(authControllerProvider.notifier).logout();
              if (context.mounted) context.go(RouteNames.login);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          WelcomeCard(name: user?.name ?? 'guest'),
          const Spacer(),
          const Text('You have pushed the button this many times:'),
          Text('$count', style: Theme.of(context).textTheme.headlineMedium),
          const Spacer(),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => ref.read(homeControllerProvider.notifier).increment(),
        tooltip: 'Increment',
        child: const Icon(Icons.add),
      ),
    );
  }
}
