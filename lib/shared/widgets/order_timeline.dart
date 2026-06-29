import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:mapanytime_market_app/shared/widgets/order_status.dart';
import 'package:mapanytime_market_app/theme/tokens/colors.dart';
import 'package:mapanytime_market_app/theme/tokens/spacing.dart';

/// A vertical status timeline for an order. Steps before [current] render as
/// done, [current] as active, and later steps as pending.
class OrderTimeline extends StatelessWidget {
  const OrderTimeline({
    required this.current,
    this.timestamps = const {},
    super.key,
  });

  final OrderStatus current;

  /// Optional per-status time label, e.g. `{OrderStatus.confirmed: '2:14 PM'}`.
  final Map<OrderStatus, String> timestamps;

  @override
  Widget build(BuildContext context) {
    const steps = OrderStatus.values;
    return Column(
      children: [
        for (var i = 0; i < steps.length; i++)
          _Step(
            status: steps[i],
            isDone: i < current.index,
            isActive: i == current.index,
            isLast: i == steps.length - 1,
            time: timestamps[steps[i]],
          ),
      ],
    );
  }
}

class _Step extends StatelessWidget {
  const _Step({
    required this.status,
    required this.isDone,
    required this.isActive,
    required this.isLast,
    this.time,
  });

  final OrderStatus status;
  final bool isDone;
  final bool isActive;
  final bool isLast;
  final String? time;

  @override
  Widget build(BuildContext context) {
    final reached = isDone || isActive;
    final color = isActive
        ? status.color
        : (isDone ? AppColors.status.success : AppColors.text.tertiaryDark);

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: reached
                      ? color.withValues(alpha: 0.18)
                      : AppColors.ui.surfaceElevatedDark,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: reached ? color : AppColors.ui.borderDark,
                    width: 1.5,
                  ),
                ),
                child: Icon(
                  isDone ? Icons.check_rounded : status.icon,
                  size: 15,
                  color: reached ? color : AppColors.text.tertiaryDark,
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    color: isDone
                        ? AppColors.status.success
                        : AppColors.ui.borderDark,
                  ),
                ),
            ],
          ),
          const Gap(AppSpacing.md),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 4, bottom: AppSpacing.lg),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      status.label,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: reached ? FontWeight.w700 : FontWeight.w500,
                        color: reached
                            ? AppColors.text.primaryDark
                            : AppColors.text.tertiaryDark,
                      ),
                    ),
                  ),
                  if (time != null)
                    Text(
                      time!,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.text.tertiaryDark,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
