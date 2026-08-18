import 'package:flutter/material.dart';
import 'package:mapanytime_market_app/theme/tokens/colors.dart';
import 'package:mapanytime_market_app/theme/tokens/radius.dart';
import 'package:mapanytime_market_app/theme/tokens/spacing.dart';

/// A digit-box code entry field with its own attached numeric keypad —
/// matches the reference exactly rather than relying on the system
/// keyboard. Wraps an internal [FormField] so it participates in an
/// ancestor [Form]'s `validate()` the same way any other field does.
///
/// The keypad collapses once the code is complete, freeing vertical space
/// for whatever comes after it (e.g. password fields on the reset-password
/// screen) instead of sitting there unused next to the real system
/// keyboard. Tap the completed boxes to clear the last digit and bring the
/// keypad back.
class OtpCodeField extends StatefulWidget {
  const OtpCodeField({
    this.length = 4,
    this.validator,
    this.onChanged,
    super.key,
  });

  final int length;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onChanged;

  @override
  State<OtpCodeField> createState() => _OtpCodeFieldState();
}

class _OtpCodeFieldState extends State<OtpCodeField> {
  String _code = '';

  bool get _isComplete => _code.length >= widget.length;

  void _onDigit(String digit, FormFieldState<String> field) {
    if (_isComplete) return;
    setState(() => _code += digit);
    field.didChange(_code);
    widget.onChanged?.call(_code);
  }

  void _onBackspace(FormFieldState<String> field) {
    if (_code.isEmpty) return;
    setState(() => _code = _code.substring(0, _code.length - 1));
    field.didChange(_code);
    widget.onChanged?.call(_code);
  }

  @override
  Widget build(BuildContext context) {
    return FormField<String>(
      validator: widget.validator,
      builder: (field) {
        return Column(
          children: [
            GestureDetector(
              onTap: _isComplete ? () => _onBackspace(field) : null,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var i = 0; i < widget.length; i++) ...[
                    if (i > 0) AppSpacing.xs.h,
                    _DigitBox(
                      value: i < _code.length ? _code[i] : '',
                      isNext: i == _code.length,
                    ),
                  ],
                ],
              ),
            ),
            if (field.hasError) ...[
              const SizedBox(height: 6),
              Text(
                field.errorText!,
                style: TextStyle(color: AppColors.status.error, fontSize: 12),
              ),
            ],
            AnimatedSize(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              child: _isComplete
                  ? const SizedBox.shrink()
                  : Padding(
                      padding: const EdgeInsets.only(top: AppSpacing.lg),
                      child: _NumericKeypad(
                        onDigit: (d) => _onDigit(d, field),
                        onBackspace: () => _onBackspace(field),
                      ),
                    ),
            ),
          ],
        );
      },
    );
  }
}

class _DigitBox extends StatelessWidget {
  const _DigitBox({required this.value, required this.isNext});

  final String value;
  final bool isNext;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: 56,
      height: 56,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: colors.surfaceContainerHighest,
        borderRadius: AppRadius.brLg,
        border: Border.all(
          color: isNext ? AppColors.ink : colors.outline,
          width: isNext ? 1.5 : 1,
        ),
      ),
      child: Text(
        value,
        style: TextStyle(
          color: colors.onSurface,
          fontSize: 22,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _NumericKeypad extends StatelessWidget {
  const _NumericKeypad({required this.onDigit, required this.onBackspace});

  final ValueChanged<String> onDigit;
  final VoidCallback onBackspace;

  static const _letters = {
    '2': 'ABC',
    '3': 'DEF',
    '4': 'GHI',
    '5': 'JKL',
    '6': 'MNO',
    '7': 'PQRS',
    '8': 'TUV',
    '9': 'WXYZ',
  };

  @override
  Widget build(BuildContext context) {
    const rows = [
      ['1', '2', '3'],
      ['4', '5', '6'],
      ['7', '8', '9'],
      ['', '0', '⌫'],
    ];

    return Column(
      children: [
        for (final row in rows) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              for (final key in row)
                _KeypadKey(
                  digit: key,
                  letters: _letters[key],
                  onTap: key.isEmpty
                      ? null
                      : key == '⌫'
                      ? onBackspace
                      : () => onDigit(key),
                ),
            ],
          ),
          AppSpacing.sm.v,
        ],
      ],
    );
  }
}

class _KeypadKey extends StatelessWidget {
  const _KeypadKey({required this.digit, this.letters, this.onTap});

  final String digit;
  final String? letters;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return SizedBox(
      width: 72,
      height: 56,
      child: digit.isEmpty
          ? const SizedBox.shrink()
          : Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: onTap,
                borderRadius: AppRadius.brPill,
                child: Center(
                  child: digit == '⌫'
                      ? Icon(
                          Icons.backspace_outlined,
                          color: colors.onSurface,
                          size: 22,
                        )
                      : Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              digit,
                              style: TextStyle(
                                color: colors.onSurface,
                                fontSize: 22,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            if (letters != null)
                              Text(
                                letters!,
                                style: TextStyle(
                                  color: colors.onSurfaceVariant,
                                  fontSize: 9,
                                  letterSpacing: 1,
                                ),
                              ),
                          ],
                        ),
                ),
              ),
            ),
    );
  }
}
