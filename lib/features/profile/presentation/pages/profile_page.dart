import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';

import 'package:mapanytime_market_app/core/utils/context_extensions.dart';
import 'package:mapanytime_market_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:mapanytime_market_app/features/profile/presentation/controllers/profile_controller.dart';
import 'package:mapanytime_market_app/routes/route_names.dart';
import 'package:mapanytime_market_app/shared/widgets/glass_card.dart';
import 'package:mapanytime_market_app/shared/widgets/modern_app_bar.dart';
import 'package:mapanytime_market_app/shared/widgets/top_toast.dart';
import 'package:mapanytime_market_app/theme/tokens/colors.dart';
import 'package:mapanytime_market_app/theme/tokens/radius.dart';
import 'package:mapanytime_market_app/theme/tokens/spacing.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(profileProvider);
    final name = user?.name ?? 'Unknown';
    final initial = (user?.name?.isNotEmpty ?? false)
        ? user!.name![0].toUpperCase()
        : '?';

    return Scaffold(
      appBar: ModernAppBar(title: context.l10n.profile, showBack: false),
      body: RefreshIndicator(
        onRefresh: () async {
          ref.invalidate(profileProvider);
          await Future<void>.delayed(const Duration(milliseconds: 300));
        },
        color: AppColors.brand.primary,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.fromLTRB(
            AppSpacing.md,
            AppSpacing.sm,
            AppSpacing.md,
            AppSpacing.md + MediaQuery.paddingOf(context).bottom,
          ),
          children: [
            _ProfileHeader(name: name, email: user?.email ?? '-', initial: initial),
            const Gap(AppSpacing.md),
            const _StatsRow(),
            const Gap(AppSpacing.lg),
            _MenuGroup(
              children: [
                _MenuTile(
                  icon: Icons.receipt_long_rounded,
                  label: 'My Orders',
                  subtitle: 'Track and view past orders',
                  onTap: () => context.push(RouteNames.orders),
                ),
                _MenuTile(
                  icon: Icons.favorite_outline_rounded,
                  label: 'Saved',
                  subtitle: 'Your favourite stores & products',
                  onTap: () => _soon(context),
                ),
                _MenuTile(
                  icon: Icons.location_on_outlined,
                  label: 'Addresses',
                  onTap: () => _soon(context),
                ),
                _MenuTile(
                  icon: Icons.credit_card_rounded,
                  label: 'Payment methods',
                  onTap: () => _soon(context),
                ),
              ],
            ),
            const Gap(AppSpacing.md),
            _MenuGroup(
              children: [
                _MenuTile(
                  icon: Icons.notifications_none_rounded,
                  label: 'Notifications',
                  onTap: () => _soon(context),
                ),
                _MenuTile(
                  icon: Icons.help_outline_rounded,
                  label: 'Help & Support',
                  onTap: () => _soon(context),
                ),
                _MenuTile(
                  icon: Icons.info_outline_rounded,
                  label: 'About',
                  onTap: () => _soon(context),
                ),
              ],
            ),
            const Gap(AppSpacing.md),
            _MenuGroup(
              children: [
                _MenuTile(
                  icon: Icons.logout_rounded,
                  label: context.l10n.logout,
                  danger: true,
                  onTap: () async {
                    final ok = await ref
                        .read(authControllerProvider.notifier)
                        .logout();
                    if (!context.mounted) return;
                    if (ok) {
                      context.go(RouteNames.login);
                    } else {
                      final error = ref.read(authControllerProvider).error;
                      showTopToast(
                        context,
                        error ?? 'Logout failed. Please try again.',
                      );
                    }
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static void _soon(BuildContext context) {
    showTopToast(context, context.l10n.comingSoon);
  }
}

class _ProfileHeader extends StatelessWidget {
  const _ProfileHeader({
    required this.name,
    required this.email,
    required this.initial,
  });

  final String name;
  final String email;
  final String initial;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return GlassCard(
      child: Row(
        children: [
          Container(
            width: 64,
            height: 64,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.ui.surfaceDark,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.brand.primary, width: 2),
            ),
            child: Text(
              initial,
              style: TextStyle(
                color: AppColors.brand.primary,
                fontSize: 26,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const Gap(AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name, style: tt.titleLarge),
                const Gap(2),
                Text(
                  email,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: tt.bodyMedium?.copyWith(
                    color: AppColors.text.secondaryDark,
                  ),
                ),
                const Gap(AppSpacing.sm),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.status.warning.withValues(alpha: 0.15),
                    borderRadius: AppRadius.brPill,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.workspace_premium_rounded,
                        size: 14,
                        color: AppColors.status.warning,
                      ),
                      const Gap(4),
                      Text(
                        'Gold member',
                        style: tt.labelSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.status.warning,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow();

  @override
  Widget build(BuildContext context) {
    return const Row(
      children: [
        Expanded(child: _StatTile(value: '8', label: 'Orders')),
        Gap(AppSpacing.sm),
        Expanded(child: _StatTile(value: '320', label: 'Points')),
        Gap(AppSpacing.sm),
        Expanded(child: _StatTile(value: '12', label: 'Saved')),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.value, required this.label});

  final String value;
  final String label;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    return GlassCard(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
      child: Column(
        children: [
          Text(
            value,
            style: tt.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
              color: AppColors.text.primaryDark,
            ),
          ),
          const Gap(2),
          Text(
            label,
            style: tt.labelSmall?.copyWith(color: AppColors.text.tertiaryDark),
          ),
        ],
      ),
    );
  }
}

class _MenuGroup extends StatelessWidget {
  const _MenuGroup({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: EdgeInsets.zero,
      child: Column(
        children: [
          for (var i = 0; i < children.length; i++) ...[
            children[i],
            if (i < children.length - 1)
              Divider(height: 1, indent: 56, color: AppColors.ui.borderDark),
          ],
        ],
      ),
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.subtitle,
    this.danger = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final String? subtitle;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final tt = Theme.of(context).textTheme;
    final color = danger ? AppColors.status.error : AppColors.text.primaryDark;
    return Semantics(
      button: true,
      label: label,
      child: InkWell(
        onTap: onTap,
        borderRadius: AppRadius.brCard,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm + 4,
          ),
          child: Row(
            children: [
              Icon(
                icon,
                size: 22,
                color: danger ? color : AppColors.brand.primary,
              ),
              const Gap(AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: tt.titleSmall?.copyWith(color: color),
                    ),
                    if (subtitle != null) ...[
                      const Gap(2),
                      Text(
                        subtitle!,
                        style: tt.bodySmall?.copyWith(
                          color: AppColors.text.tertiaryDark,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (!danger)
                Icon(
                  Icons.chevron_right_rounded,
                  size: 20,
                  color: AppColors.text.tertiaryDark,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
