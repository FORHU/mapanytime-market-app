import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:mapanytime_market_app/features/store/domain/entities/store_hours.dart';
import 'package:mapanytime_market_app/shared/widgets/section_title.dart';
import 'package:mapanytime_market_app/theme/tokens/colors.dart';
import 'package:mapanytime_market_app/theme/tokens/spacing.dart';

/// Weekly hours section shown in the map bottom sheet. Renders nothing when
/// [hours] is empty (the backend hasn't set up a schedule for this store).
class StoreHoursSection extends StatelessWidget {
  const StoreHoursSection({required this.hours, super.key});

  final List<StoreDayHours> hours;

  @override
  Widget build(BuildContext context) {
    if (hours.isEmpty) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final todayDow = DateTime.now().weekday % 7;
    final byDay = {for (final d in hours) d.dayOfWeek: d};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionTitle(title: 'Hours'),
        const Gap(AppSpacing.sm),
        for (var dow = 0; dow < 7; dow++)
          if (byDay[dow] case final day?)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 3),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      weekdayLabels[dow],
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: dow == todayDow
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: dow == todayDow
                            ? AppColors.text.primaryDark
                            : AppColors.text.secondaryDark,
                      ),
                    ),
                  ),
                  Text(
                    hours.formatted(day),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontWeight: dow == todayDow
                          ? FontWeight.w700
                          : FontWeight.w500,
                      color: dow == todayDow
                          ? AppColors.text.primaryDark
                          : AppColors.text.secondaryDark,
                    ),
                  ),
                ],
              ),
            ),
      ],
    );
  }
}
