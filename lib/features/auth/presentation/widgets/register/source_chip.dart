import 'package:flutter/material.dart';
import 'package:mapanytime_market_app/core/utils/context_extensions.dart';
import 'package:mapanytime_market_app/theme/tokens/colors.dart';

/// Where a value on the "Check your details" step came from.
enum FieldSource {
  /// Read from the ID photo and untouched.
  fromId,

  /// Read by guesswork (or not found) — worth a second look.
  check,

  /// Changed by the buyer.
  edited;

  static FieldSource of({
    required String value,
    required String original,
    required bool unsure,
  }) {
    if (value.trim() != original.trim()) return FieldSource.edited;
    if (unsure || value.trim().isEmpty) return FieldSource.check;
    return FieldSource.fromId;
  }
}

/// Small pill in a field's label row naming the value's [FieldSource].
class SourceChip extends StatelessWidget {
  const SourceChip(this.source, {super.key});

  final FieldSource source;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final (label, icon, fill, ink) = switch (source) {
      FieldSource.fromId => (
        l10n.sourceFromId,
        Icons.document_scanner_outlined,
        AppColors.ink.withValues(alpha: 0.08),
        AppColors.ink,
      ),
      FieldSource.check => (
        l10n.sourceCheck,
        Icons.error_outline_rounded,
        AppColors.status.warning.withValues(alpha: 0.14),
        AppColors.status.warningStrong,
      ),
      FieldSource.edited => (
        l10n.sourceEdited,
        Icons.edit_rounded,
        AppColors.ui.borderHairline,
        AppColors.text.secondary,
      ),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: ink),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: ink,
            ),
          ),
        ],
      ),
    );
  }
}

/// A [SourceChip] that follows [controller] as the buyer types.
class ControllerSourceChip extends StatelessWidget {
  const ControllerSourceChip({
    required this.controller,
    required this.original,
    required this.unsure,
    super.key,
  });

  final TextEditingController controller;
  final String original;
  final bool unsure;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, _) => SourceChip(
        FieldSource.of(
          value: value.text,
          original: original,
          unsure: unsure,
        ),
      ),
    );
  }
}
