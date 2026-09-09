import 'package:flutter/material.dart';
import 'package:gap/gap.dart';
import 'package:mapanytime_market_app/theme/tokens/colors.dart';
import 'package:mapanytime_market_app/theme/tokens/radius.dart';

/// A premium text field with an optional floating label and icons. Reads
/// colors from [Theme.of(context)] so it renders correctly under either the
/// dark (default, app-wide) or light theme (currently only the auth flow's
/// locally-scoped override).
///
/// When [obscureText] is true and no [suffixIcon] is given, a show/hide eye
/// toggle renders automatically — callers don't need to manage that state.
class ModernTextField extends StatefulWidget {
  const ModernTextField({
    this.label,
    this.hint,
    this.controller,
    this.prefixIcon,
    this.suffixIcon,
    this.obscureText = false,
    this.keyboardType,
    this.maxLength,
    this.onChanged,
    this.validator,
    this.borderRadius,
    super.key,
  });

  final String? label;
  final String? hint;
  final TextEditingController? controller;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final bool obscureText;
  final TextInputType? keyboardType;
  final int? maxLength;
  final ValueChanged<String>? onChanged;
  final String? Function(String?)? validator;

  /// Overrides the default [AppRadius.field] corner radius, for a caller
  /// that deliberately wants a different shape.
  final double? borderRadius;

  @override
  State<ModernTextField> createState() => _ModernTextFieldState();
}

class _ModernTextFieldState extends State<ModernTextField> {
  late bool _obscured = widget.obscureText;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final radius = widget.borderRadius != null
        ? BorderRadius.circular(widget.borderRadius!)
        : AppRadius.brField;

    final suffix =
        widget.suffixIcon ??
        (widget.obscureText
            ? IconButton(
                icon: _VisibilityGlyph(
                  hidden: _obscured,
                  color: colors.onSurfaceVariant,
                ),
                onPressed: () => setState(() => _obscured = !_obscured),
              )
            : null);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label != null) ...[
          Text(
            widget.label!,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: colors.onSurfaceVariant,
            ),
          ),
          const Gap(8),
        ],
        TextFormField(
          controller: widget.controller,
          obscureText: _obscured,
          keyboardType: widget.keyboardType,
          maxLength: widget.maxLength,
          onChanged: widget.onChanged,
          validator: widget.validator,
          style: TextStyle(color: colors.onSurface, fontSize: 15),
          cursorColor: AppColors.ink,
          decoration: InputDecoration(
            hintText: widget.hint,
            hintStyle: TextStyle(
              color: colors.onSurfaceVariant.withValues(alpha: 0.6),
            ),
            filled: true,
            fillColor: colors.surfaceContainerHighest,
            counterText: '',
            prefixIcon: widget.prefixIcon != null
                ? Icon(widget.prefixIcon, color: colors.onSurfaceVariant)
                : null,
            suffixIcon: suffix,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            border: OutlineInputBorder(
              borderRadius: radius,
              borderSide: BorderSide(color: colors.outline),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: radius,
              borderSide: BorderSide(color: colors.outline),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: radius,
              borderSide: const BorderSide(color: AppColors.ink, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }
}

/// A plain circle outline, crossed by a diagonal line while the password is
/// hidden — the auth redesign's minimal password-visibility glyph, in place
/// of a Material eye icon.
class _VisibilityGlyph extends StatelessWidget {
  const _VisibilityGlyph({required this.hidden, required this.color});

  final bool hidden;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 22,
      height: 22,
      child: Stack(
        alignment: Alignment.center,
        clipBehavior: Clip.none,
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: color, width: 1.5),
            ),
          ),
          if (hidden)
            Transform.rotate(
              angle: 0.7853981633974483, // 45 degrees
              child: Container(width: 22, height: 1.5, color: color),
            ),
        ],
      ),
    );
  }
}
