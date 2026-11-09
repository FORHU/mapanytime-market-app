import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:mapanytime_market_app/core/errors/exceptions.dart';
import 'package:mapanytime_market_app/features/auth/presentation/controllers/auth_controller.dart';
import 'package:mapanytime_market_app/features/store/domain/entities/review_item.dart';
import 'package:mapanytime_market_app/features/store/presentation/controllers/store_controller.dart';
import 'package:mapanytime_market_app/shared/widgets/buttons.dart';
import 'package:mapanytime_market_app/shared/widgets/top_toast.dart';
import 'package:mapanytime_market_app/theme/tokens/colors.dart';
import 'package:mapanytime_market_app/theme/tokens/radius.dart';
import 'package:mapanytime_market_app/theme/tokens/spacing.dart';

/// Displays verified buyer reviews and a composer for a product (`CAT-6`).
class ProductReviewsSection extends ConsumerWidget {
  const ProductReviewsSection({required this.productId, super.key});

  final String productId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reviewsAsync = ref.watch(productReviewsProvider(productId));
    final currentUserId = ref.watch(authControllerProvider).user?.id;

    return _ReviewsSectionView(
      title: 'Reviews',
      actionLabel: 'Write a review',
      emptyMessage:
          'No reviews yet. Complete an order with this product '
          'to leave the first review.',
      reviewsAsync: reviewsAsync,
      currentUserId: currentUserId,
      onSubmit: (rating, comment) async {
        await ref
            .read(reviewRemoteDataSourceProvider)
            .upsertProductReview(
              productId: productId,
              rating: rating,
              comment: comment,
            );
        ref.invalidate(productReviewsProvider(productId));
      },
      onDelete: (reviewId) async {
        await ref
            .read(reviewRemoteDataSourceProvider)
            .deleteProductReview(reviewId);
        ref.invalidate(productReviewsProvider(productId));
      },
    );
  }
}

/// Displays verified buyer reviews and a composer for a store (`STO-6`).
class StoreReviewsSection extends ConsumerWidget {
  const StoreReviewsSection({required this.storeId, super.key});

  final String storeId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reviewsAsync = ref.watch(storeReviewsProvider(storeId));
    final currentUserId = ref.watch(authControllerProvider).user?.id;

    return _ReviewsSectionView(
      title: 'Store Reviews',
      actionLabel: 'Rate store',
      emptyMessage:
          'No store reviews yet. Complete an order from this store '
          'to share your feedback.',
      reviewsAsync: reviewsAsync,
      currentUserId: currentUserId,
      onSubmit: (rating, comment) async {
        await ref
            .read(reviewRemoteDataSourceProvider)
            .upsertStoreReview(
              storeId: storeId,
              rating: rating,
              comment: comment,
            );
        ref
          ..invalidate(storeReviewsProvider(storeId))
          ..invalidate(storeDetailsProvider(storeId));
      },
      onDelete: (reviewId) async {
        await ref
            .read(reviewRemoteDataSourceProvider)
            .deleteStoreReview(reviewId);
        ref
          ..invalidate(storeReviewsProvider(storeId))
          ..invalidate(storeDetailsProvider(storeId));
      },
    );
  }
}

class _ReviewsSectionView extends ConsumerWidget {
  const _ReviewsSectionView({
    required this.title,
    required this.actionLabel,
    required this.emptyMessage,
    required this.reviewsAsync,
    required this.currentUserId,
    required this.onSubmit,
    required this.onDelete,
  });

  final String title;
  final String actionLabel;
  final String emptyMessage;
  final AsyncValue<ReviewListResult> reviewsAsync;
  final String? currentUserId;
  final Future<void> Function(int rating, String? comment) onSubmit;
  final Future<void> Function(String reviewId) onDelete;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final result = reviewsAsync.value;
    final existingOwnReview = currentUserId == null || result == null
        ? null
        : result.items.where((r) => r.buyerId == currentUserId).firstOrNull;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Row(
                children: [
                  Text(title, style: theme.textTheme.titleMedium),
                  if (result != null && result.total > 0) ...[
                    const Gap(AppSpacing.sm),
                    Icon(
                      Icons.star_rounded,
                      size: 18,
                      color: AppColors.status.warning,
                    ),
                    const Gap(2),
                    Text(
                      result.averageRating.toStringAsFixed(1),
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: AppColors.text.primary,
                      ),
                    ),
                    Text(
                      ' (${result.total})',
                      style: TextStyle(color: AppColors.text.tertiary),
                    ),
                  ],
                ],
              ),
            ),
            TextButton.icon(
              onPressed: () {
                final isAuthenticated = ref
                    .read(authControllerProvider)
                    .isAuthenticated;
                if (!isAuthenticated) {
                  showTopToast(context, 'Please sign in to leave a review.');
                  return;
                }
                _showReviewComposerSheet(
                  context: context,
                  title: existingOwnReview != null
                      ? 'Update review'
                      : actionLabel,
                  initialRating: existingOwnReview?.rating ?? 5,
                  initialComment: existingOwnReview?.comment ?? '',
                  onSubmit: onSubmit,
                );
              },
              icon: const Icon(Icons.rate_review_outlined, size: 16),
              label: Text(
                existingOwnReview != null ? 'Edit review' : actionLabel,
              ),
            ),
          ],
        ),
        const Gap(AppSpacing.sm),
        reviewsAsync.when(
          loading: () => const Padding(
            padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
            child: Center(
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2),
              ),
            ),
          ),
          error: (_, _) => Text(
            'Unable to load reviews right now.',
            style: TextStyle(color: AppColors.text.tertiary, fontSize: 13),
          ),
          data: (data) {
            if (data.items.isEmpty) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.ui.surfaceMuted,
                  borderRadius: AppRadius.brLg,
                ),
                child: Text(
                  emptyMessage,
                  style: TextStyle(
                    color: AppColors.text.secondary,
                    fontSize: 13,
                  ),
                ),
              );
            }

            return Column(
              children: [
                for (final item in data.items) ...[
                  _ReviewCard(
                    review: item,
                    isOwnReview:
                        currentUserId != null && item.buyerId == currentUserId,
                    onDelete: () async {
                      try {
                        await onDelete(item.id);
                        if (context.mounted) {
                          showTopToast(context, 'Review deleted.');
                        }
                      } on AppException catch (e) {
                        if (context.mounted) {
                          showTopToast(context, e.message);
                        }
                      }
                    },
                  ),
                  const Gap(AppSpacing.sm),
                ],
              ],
            );
          },
        ),
      ],
    );
  }

  void _showReviewComposerSheet({
    required BuildContext context,
    required String title,
    required int initialRating,
    required String initialComment,
    required Future<void> Function(int rating, String? comment) onSubmit,
  }) {
    unawaited(
      showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: AppColors.ui.surface,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(AppRadius.xl),
          ),
        ),
        builder: (sheetContext) => _ReviewComposerSheet(
          title: title,
          initialRating: initialRating,
          initialComment: initialComment,
          onSubmit: onSubmit,
        ),
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({
    required this.review,
    required this.isOwnReview,
    required this.onDelete,
  });

  final ReviewItem review;
  final bool isOwnReview;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final formattedDate = review.createdAt != null
        ? DateFormat.yMMMd().format(review.createdAt!)
        : null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.ui.surfaceMuted,
        borderRadius: AppRadius.brLg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  review.buyerName,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: AppColors.text.primary,
                  ),
                ),
              ),
              if (formattedDate != null)
                Text(
                  formattedDate,
                  style: TextStyle(
                    fontSize: 12,
                    color: AppColors.text.tertiary,
                  ),
                ),
              if (isOwnReview) ...[
                const Gap(AppSpacing.xs),
                InkWell(
                  onTap: onDelete,
                  borderRadius: AppRadius.brPill,
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      Icons.delete_outline_rounded,
                      size: 16,
                      color: AppColors.text.tertiary,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const Gap(4),
          Row(
            children: List.generate(
              5,
              (index) => Icon(
                index < review.rating
                    ? Icons.star_rounded
                    : Icons.star_border_rounded,
                size: 16,
                color: AppColors.status.warning,
              ),
            ),
          ),
          if (review.comment != null && review.comment!.trim().isNotEmpty) ...[
            const Gap(AppSpacing.xs),
            Text(
              review.comment!,
              style: TextStyle(
                color: AppColors.text.secondary,
                fontSize: 13,
                height: 1.4,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ReviewComposerSheet extends StatefulWidget {
  const _ReviewComposerSheet({
    required this.title,
    required this.initialRating,
    required this.initialComment,
    required this.onSubmit,
  });

  final String title;
  final int initialRating;
  final String initialComment;
  final Future<void> Function(int rating, String? comment) onSubmit;

  @override
  State<_ReviewComposerSheet> createState() => _ReviewComposerSheetState();
}

class _ReviewComposerSheetState extends State<_ReviewComposerSheet> {
  late int _rating = widget.initialRating;
  late final TextEditingController _commentController = TextEditingController(
    text: widget.initialComment,
  );
  bool _submitting = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (_submitting) return;
    setState(() => _submitting = true);
    try {
      await widget.onSubmit(_rating, _commentController.text);
      if (mounted) {
        Navigator.of(context).pop();
        showTopToast(context, 'Review submitted.');
      }
    } on AppException catch (e) {
      if (mounted) {
        showTopToast(context, e.message);
      }
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.md,
        bottomInset + AppSpacing.lg,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(widget.title, style: theme.textTheme.titleLarge),
          const Gap(AppSpacing.sm),
          Row(
            children: List.generate(5, (index) {
              final starValue = index + 1;
              return IconButton(
                onPressed: _submitting
                    ? null
                    : () => setState(() => _rating = starValue),
                icon: Icon(
                  starValue <= _rating
                      ? Icons.star_rounded
                      : Icons.star_border_rounded,
                  size: 32,
                  color: AppColors.status.warning,
                ),
              );
            }),
          ),
          const Gap(AppSpacing.sm),
          TextField(
            controller: _commentController,
            enabled: !_submitting,
            maxLines: 3,
            maxLength: 500,
            decoration: InputDecoration(
              hintText: 'Share your experience (optional)',
              filled: true,
              fillColor: AppColors.ui.surfaceMuted,
              border: OutlineInputBorder(
                borderRadius: AppRadius.brLg,
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const Gap(AppSpacing.md),
          PrimaryButton(
            label: _submitting ? 'Submitting...' : 'Submit review',
            onPressed: _submitting ? null : _handleSubmit,
          ),
        ],
      ),
    );
  }
}
