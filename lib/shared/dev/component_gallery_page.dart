import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:mapanytime_market_app/routes/route_names.dart';
import 'package:mapanytime_market_app/shared/widgets/animated_fab.dart';
import 'package:mapanytime_market_app/shared/widgets/buttons.dart';
import 'package:mapanytime_market_app/shared/widgets/category_chip.dart';
import 'package:mapanytime_market_app/shared/widgets/floating_search_bar.dart';
import 'package:mapanytime_market_app/shared/widgets/glass_card.dart';
import 'package:mapanytime_market_app/shared/widgets/modern_app_bar.dart';
import 'package:mapanytime_market_app/shared/widgets/modern_text_field.dart';
import 'package:mapanytime_market_app/shared/widgets/order_status.dart';
import 'package:mapanytime_market_app/shared/widgets/order_timeline.dart';
import 'package:mapanytime_market_app/shared/widgets/pickup_status_card.dart';
import 'package:mapanytime_market_app/shared/widgets/price_tag.dart';
import 'package:mapanytime_market_app/shared/widgets/product_card.dart';
import 'package:mapanytime_market_app/shared/widgets/qr_card.dart';
import 'package:mapanytime_market_app/shared/widgets/section_title.dart';
import 'package:mapanytime_market_app/shared/widgets/store_card.dart';
import 'package:mapanytime_market_app/theme/tokens/colors.dart';
import 'package:mapanytime_market_app/theme/tokens/spacing.dart';

/// Dev-only gallery to preview every design-system component in one place.
class ComponentGalleryPage extends StatefulWidget {
  const ComponentGalleryPage({super.key});

  @override
  State<ComponentGalleryPage> createState() => _ComponentGalleryPageState();
}

class _ComponentGalleryPageState extends State<ComponentGalleryPage> {
  int _chip = 0;
  static const _img = 'https://picsum.photos/seed/mapanytime';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ModernAppBar(
        title: 'Component Gallery',
        onBack: () => context.go(RouteNames.profile),
      ),
      floatingActionButton: AnimatedFab(
        icon: Icons.add_rounded,
        label: 'Action',
        onPressed: () {},
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.sm,
          AppSpacing.md,
          120,
        ),
        children: [
          const _Label('Buttons'),
          PrimaryButton(label: 'Primary Button', onPressed: () {}),
          const Gap(AppSpacing.sm),
          GradientButton(
            label: 'Gradient Button',
            icon: Icons.bolt_rounded,
            onPressed: () {},
          ),
          const Gap(AppSpacing.sm),
          const PrimaryButton(label: 'Disabled', onPressed: null),
          const Gap(AppSpacing.lg),

          const _Label('Section title + price'),
          SectionTitle(
            title: 'Featured Products',
            actionLabel: 'See all',
            onAction: () {},
          ),
          const Gap(AppSpacing.sm),
          const Row(
            children: [
              PriceTag(amount: 1299.5),
              Gap(AppSpacing.md),
              PriceTag(amount: 89, filled: true),
            ],
          ),
          const Gap(AppSpacing.lg),

          const _Label('Category chips'),
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: [
              for (var i = 0; i < _chips.length; i++)
                CategoryChip(
                  label: _chips[i].$1,
                  icon: _chips[i].$2,
                  selected: _chip == i,
                  onTap: () => setState(() => _chip = i),
                ),
            ],
          ),
          const Gap(AppSpacing.lg),

          const _Label('Search + inputs'),
          const FloatingSearchBar(onFilterTap: _noop),
          const Gap(AppSpacing.md),
          const ModernTextField(
            label: 'Email',
            hint: 'you@example.com',
            prefixIcon: Icons.mail_outline_rounded,
          ),
          const Gap(AppSpacing.lg),

          const _Label('Glass card'),
          GlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'GlassCard',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const Gap(6),
                Text(
                  'Floating surface with soft shadow + hairline border.',
                  style: TextStyle(color: AppColors.text.secondaryDark),
                ),
              ],
            ),
          ),
          const Gap(AppSpacing.lg),

          const _Label('Product cards'),
          SizedBox(
            height: 250,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: [
                ProductCard(
                  name: 'Japanese Matcha Kit',
                  imageUrl: '$_img-1/400',
                  price: 942,
                  storeName: 'ZenMarket',
                  distanceKm: 1.2,
                  onTap: () {},
                ),
                const Gap(AppSpacing.md),
                ProductCard(
                  name: 'Studio Desk Lamp',
                  imageUrl: '$_img-2/400',
                  price: 1599,
                  storeName: 'Nova Home',
                  distanceKm: 3.4,
                  onTap: () {},
                ),
              ],
            ),
          ),
          const Gap(AppSpacing.lg),

          const _Label('Store card'),
          StoreCard(
            name: 'ZenMarket',
            imageUrl: '$_img-3/200',
            rating: 4.8,
            distanceKm: 1.2,
            category: 'Specialty • Tea & Coffee',
            onTap: () {},
          ),
          const Gap(AppSpacing.lg),

          const _Label('Order status + timeline'),
          const PickupStatusCard(
            status: OrderStatus.preparing,
            etaLabel: 'Ready in ~8 min',
          ),
          const Gap(AppSpacing.md),
          const GlassCard(
            child: OrderTimeline(
              current: OrderStatus.preparing,
              timestamps: {
                OrderStatus.confirmed: '2:14 PM',
                OrderStatus.preparing: '2:16 PM',
              },
            ),
          ),
          const Gap(AppSpacing.lg),

          const _Label('QR / Pickup pass'),
          const Center(
            child: QrCard(data: 'MA-9921', code: 'MA-9921', glow: true),
          ),
          const Gap(AppSpacing.xl),
        ],
      ),
    );
  }

  static void _noop() {}

  static const List<(String, IconData)> _chips = [
    ('All', Icons.grid_view_rounded),
    ('Food', Icons.restaurant_rounded),
    ('Fashion', Icons.checkroom_rounded),
    ('Tech', Icons.devices_rounded),
  ];
}

class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm, top: 4),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
          color: AppColors.text.tertiaryDark,
        ),
      ),
    );
  }
}
