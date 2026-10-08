import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:mapanytime_market_app/core/utils/context_extensions.dart';
import 'package:mapanytime_market_app/core/utils/validators.dart';
import 'package:mapanytime_market_app/features/auth/data/id_scan/id_text_parser.dart';
import 'package:mapanytime_market_app/features/auth/domain/entities/registration_profile.dart';
import 'package:mapanytime_market_app/features/auth/presentation/widgets/register/id_upload_step.dart';
import 'package:mapanytime_market_app/features/auth/presentation/widgets/register/source_chip.dart';
import 'package:mapanytime_market_app/shared/widgets/modern_text_field.dart';
import 'package:mapanytime_market_app/theme/tokens/colors.dart';
import 'package:mapanytime_market_app/theme/tokens/radius.dart';
import 'package:mapanytime_market_app/theme/tokens/spacing.dart';

/// A date of birth as shown in the field, e.g. "Mar 15, 1994" in English.
String formatDateOfBirth(BuildContext context, DateTime date) =>
    DateFormat.yMMMd(Localizations.localeOf(context).toString()).format(date);

/// The details on the review step: prefilled from the scan, edited by the
/// buyer. Owned by the register page so values survive moving between steps.
/// The buyer's name isn't here: it's entered on the account step and only
/// checked against the ID, never taken from it.
class IdReviewFields {
  final dateOfBirthText = TextEditingController();
  final address = TextEditingController();
  final idNumber = TextEditingController();

  DateTime? dateOfBirth;
  Sex? sex;
  IdType? idType;

  /// What the scan produced — the baseline the source chips compare against.
  ScannedId scanned = ScannedId.nothing;
  String _scannedDateText = '';

  /// Replaces every value with what [id] holds.
  void fill(ScannedId id, String Function(DateTime) formatDate) {
    scanned = id;
    dateOfBirth = id.dateOfBirth;
    _scannedDateText = id.dateOfBirth == null
        ? ''
        : formatDate(id.dateOfBirth!);
    dateOfBirthText.text = _scannedDateText;
    sex = id.sex;
    address.text = id.address;
    idType = id.idType;
    idNumber.text = id.idNumber;
  }

  void dispose() {
    for (final c in [
      dateOfBirthText,
      address,
      idNumber,
    ]) {
      c.dispose();
    }
  }
}

/// Sign-up step 3: the buyer's first and last name (as entered on the
/// account step; the middle name stays there) plus every detail read from the
/// ID, all editable, the ID details marked with where they came from.
/// Validation runs through the page's enclosing [Form]; call
/// [IdReviewStepState.scrollToFirstError] after a failed validate.
class IdReviewStep extends StatefulWidget {
  const IdReviewStep({
    required this.fields,
    required this.firstName,
    required this.lastName,
    required this.photoPath,
    required this.onRetake,
    super.key,
  });

  final IdReviewFields fields;

  /// The account step's name controllers: the same values, editable here too.
  /// Never filled from the ID.
  final TextEditingController firstName;
  final TextEditingController lastName;
  final String? photoPath;
  final VoidCallback onRetake;

  @override
  State<IdReviewStep> createState() => IdReviewStepState();
}

class IdReviewStepState extends State<IdReviewStep> {
  IdReviewFields get _f => widget.fields;

  // One key per validated field, in screen order, for scrolling to the first
  // error.
  final Map<IdField, GlobalKey> _keys = {
    for (final f in IdField.values) f: GlobalKey(),
  };

  String? _dateOfBirthError(String? _) {
    final dob = _f.dateOfBirth;
    if (dob == null) return Validators.notEmpty(null);
    if (dob.isAfter(DateTime.now())) return context.l10n.dateOfBirthFuture;
    return null;
  }

  String? _idTypeError(IdType? value) =>
      value == null ? Validators.notEmpty(null) : null;

  /// Brings the name fields into view, e.g. when they no longer match the ID.
  void scrollToName() => _scrollTo(_keys[IdField.firstName]!);

  void _scrollTo(GlobalKey key) {
    final ctx = key.currentContext;
    if (ctx == null) return;
    unawaited(
      Scrollable.ensureVisible(
        ctx,
        alignment: 0.2,
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeOut,
      ),
    );
  }

  /// Scrolls the first invalid field into view. Mirrors the validators wired
  /// into the fields below.
  void scrollToFirstError() {
    final checks = <(GlobalKey, String?)>[
      (_keys[IdField.firstName]!, Validators.notEmpty(widget.firstName.text)),
      (_keys[IdField.lastName]!, Validators.notEmpty(widget.lastName.text)),
      (_keys[IdField.dateOfBirth]!, _dateOfBirthError(null)),
      (_keys[IdField.address]!, Validators.notEmpty(_f.address.text)),
      (_keys[IdField.idType]!, _idTypeError(_f.idType)),
      (_keys[IdField.idNumber]!, Validators.notEmpty(_f.idNumber.text)),
    ];
    for (final (key, error) in checks) {
      if (error != null) return _scrollTo(key);
    }
  }

  /// [scrollKey] for the fields [scrollToFirstError] may need to reach.
  Widget _nameField(
    String name,
    TextEditingController controller, {
    required String label,
    required String hint,
    GlobalKey? scrollKey,
    String? Function(String?)? validator,
  }) {
    return KeyedSubtree(
      key: scrollKey,
      child: ModernTextField(
        key: ValueKey(name),
        label: label,
        hint: hint,
        controller: controller,
        validator: validator,
        textCapitalization: TextCapitalization.words,
      ),
    );
  }

  bool _unsure(IdField field) => _f.scanned.unsure.contains(field);

  Widget _chip(
    IdField field,
    TextEditingController controller,
    String original,
  ) => ControllerSourceChip(
    controller: controller,
    original: original,
    unsure: _unsure(field),
  );

  Widget _textField(
    IdField field,
    TextEditingController controller,
    String original, {
    required String label,
    required String hint,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    TextCapitalization capitalization = TextCapitalization.words,
    int? maxLength,
    int? minLines,
    int maxLines = 1,
  }) {
    return KeyedSubtree(
      key: _keys[field],
      child: ModernTextField(
        key: ValueKey(field.name),
        label: label,
        hint: hint,
        controller: controller,
        validator: validator,
        keyboardType: keyboardType,
        textCapitalization: capitalization,
        maxLength: maxLength,
        minLines: minLines,
        maxLines: maxLines,
        labelTrailing: _chip(field, controller, original),
      ),
    );
  }

  Future<void> _pickDateOfBirth() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _f.dateOfBirth ?? DateTime(now.year - 25),
      firstDate: DateTime(1900),
      lastDate: now,
      initialEntryMode: DatePickerEntryMode.calendarOnly,
    );
    if (picked == null || !mounted) return;
    setState(() {
      _f.dateOfBirth = picked;
      _f.dateOfBirthText.text = formatDateOfBirth(context, picked);
    });
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final s = _f.scanned;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _SourceCard(
          photoPath: widget.photoPath,
          idType: _f.idType,
          onRetake: widget.onRetake,
        ),
        AppSpacing.md.v,
        _Banner(text: l10n.idReviewBanner),
        _GroupHeading(l10n.idGroupName),
        _nameField(
          'firstName',
          widget.firstName,
          scrollKey: _keys[IdField.firstName],
          label: l10n.firstName,
          hint: l10n.firstNameHint,
          validator: Validators.notEmpty,
        ),
        AppSpacing.md.v,
        _nameField(
          'lastName',
          widget.lastName,
          scrollKey: _keys[IdField.lastName],
          label: l10n.lastName,
          hint: l10n.lastNameHint,
          validator: Validators.notEmpty,
        ),
        _GroupHeading(l10n.idGroupPersonal),
        KeyedSubtree(
          key: _keys[IdField.dateOfBirth],
          child: ModernTextField(
            key: const ValueKey('dateOfBirth'),
            label: l10n.dateOfBirth,
            hint: l10n.dateOfBirthHint,
            controller: _f.dateOfBirthText,
            readOnly: true,
            onTap: _pickDateOfBirth,
            validator: _dateOfBirthError,
            suffixIcon: Icon(
              Icons.calendar_today_outlined,
              size: 20,
              color: AppColors.text.secondary,
            ),
            labelTrailing: ControllerSourceChip(
              controller: _f.dateOfBirthText,
              original: _f._scannedDateText,
              unsure: _unsure(IdField.dateOfBirth),
            ),
          ),
        ),
        AppSpacing.md.v,
        _SexField(
          value: _f.sex,
          source: FieldSource.of(
            value: _f.sex?.name ?? '',
            original: s.sex?.name ?? '',
            unsure: _unsure(IdField.sex),
          ),
          onChanged: (sex) => setState(() => _f.sex = sex),
        ),
        AppSpacing.md.v,
        _textField(
          IdField.address,
          _f.address,
          s.address,
          label: l10n.address,
          hint: l10n.addressHint,
          validator: Validators.notEmpty,
          keyboardType: TextInputType.streetAddress,
          minLines: 1,
          maxLines: 3,
        ),
        _GroupHeading(l10n.idGroupId),
        KeyedSubtree(
          key: _keys[IdField.idType],
          child: _IdTypeField(
            value: _f.idType,
            source: FieldSource.of(
              value: _f.idType?.name ?? '',
              original: s.idType?.name ?? '',
              unsure: _unsure(IdField.idType),
            ),
            validator: _idTypeError,
            onChanged: (type) => setState(() => _f.idType = type),
          ),
        ),
        AppSpacing.md.v,
        _textField(
          IdField.idNumber,
          _f.idNumber,
          s.idNumber,
          label: l10n.idNumber,
          hint: l10n.idNumberHint,
          validator: Validators.notEmpty,
          capitalization: TextCapitalization.characters,
        ),
      ],
    );
  }
}

/// Thumbnail of the uploaded ID, its detected type, and Retake.
class _SourceCard extends StatelessWidget {
  const _SourceCard({
    required this.photoPath,
    required this.idType,
    required this.onRetake,
  });

  final String? photoPath;
  final IdType? idType;
  final VoidCallback onRetake;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final path = photoPath;
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 10, 6, 10),
      decoration: BoxDecoration(
        color: AppColors.ui.surface,
        border: Border.all(color: AppColors.ui.borderHairline),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: 76,
              height: 48,
              child: path == null ? const SizedBox() : IdPhoto(path),
            ),
          ),
          AppSpacing.md.h,
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  idType?.label ?? l10n.idType,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Icon(
                      Icons.check_circle_rounded,
                      size: 14,
                      color: AppColors.status.success,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      l10n.idPhotoAdded,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: AppColors.text.secondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          TextButton(
            key: const ValueKey('retakeId'),
            onPressed: onRetake,
            style: TextButton.styleFrom(foregroundColor: AppColors.ink),
            child: Text(
              l10n.idRetake,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  const _Banner({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.ink.withValues(alpha: 0.07),
        borderRadius: AppRadius.brField,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            size: 18,
            color: AppColors.ink,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13.5,
                height: 1.45,
                color: AppColors.text.primary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GroupHeading extends StatelessWidget {
  const _GroupHeading(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.lg, bottom: 12),
      child: Text(
        text.toUpperCase(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.7,
          color: AppColors.text.tertiary,
        ),
      ),
    );
  }
}

/// Label row shared by the non-text fields, matching [ModernTextField]'s.
class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.label, required this.source});

  final String label;
  final FieldSource source;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.text.secondary,
              ),
            ),
          ),
          SourceChip(source),
        ],
      ),
    );
  }
}

class _SexField extends StatelessWidget {
  const _SexField({
    required this.value,
    required this.source,
    required this.onChanged,
  });

  final Sex? value;
  final FieldSource source;
  final ValueChanged<Sex> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _FieldLabel(label: l10n.sex, source: source),
        Row(
          children: [
            for (final (i, sex) in Sex.values.indexed) ...[
              if (i > 0) AppSpacing.sm.h,
              Expanded(
                child: _Segment(
                  label: sex == Sex.male ? l10n.sexMale : l10n.sexFemale,
                  selected: value == sex,
                  onTap: () => onChanged(sex),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

class _Segment extends StatelessWidget {
  const _Segment({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected ? AppColors.ink : AppColors.ui.surfaceMuted,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.brField,
          side: BorderSide(
            color: selected ? AppColors.ink : AppColors.ui.borderHairline,
          ),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadius.brField,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 14),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w400,
                color: selected ? AppColors.text.onInk : AppColors.text.primary,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _IdTypeField extends StatelessWidget {
  const _IdTypeField({
    required this.value,
    required this.source,
    required this.validator,
    required this.onChanged,
  });

  final IdType? value;
  final FieldSource source;
  final FormFieldValidator<IdType> validator;
  final ValueChanged<IdType?> onChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    OutlineInputBorder border(Color color, [double width = 1]) =>
        OutlineInputBorder(
          borderRadius: AppRadius.brField,
          borderSide: BorderSide(color: color, width: width),
        );
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _FieldLabel(label: l10n.idType, source: source),
        DropdownButtonFormField<IdType>(
          key: const ValueKey('idType'),
          initialValue: value,
          validator: validator,
          onChanged: onChanged,
          isExpanded: true,
          borderRadius: AppRadius.brField,
          hint: Text(
            l10n.idTypeHint,
            style: TextStyle(
              color: AppColors.text.secondary.withValues(alpha: 0.6),
            ),
          ),
          style: TextStyle(color: AppColors.text.primary, fontSize: 15),
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.ui.surfaceMuted,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 16,
            ),
            border: border(AppColors.ui.borderHairline),
            enabledBorder: border(AppColors.ui.borderHairline),
            focusedBorder: border(AppColors.ink, 1.5),
          ),
          items: [
            for (final type in IdType.values)
              DropdownMenuItem(value: type, child: Text(type.label)),
          ],
        ),
      ],
    );
  }
}
