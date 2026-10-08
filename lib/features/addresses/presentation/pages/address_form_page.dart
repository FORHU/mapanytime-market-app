import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:mapanytime_market_app/core/utils/validators.dart';
import 'package:mapanytime_market_app/features/addresses/domain/entities/buyer_address.dart';
import 'package:mapanytime_market_app/features/addresses/presentation/controllers/addresses_controller.dart';
import 'package:mapanytime_market_app/features/profile/presentation/controllers/profile_controller.dart';
import 'package:mapanytime_market_app/shared/widgets/buttons.dart';
import 'package:mapanytime_market_app/shared/widgets/modern_app_bar.dart';
import 'package:mapanytime_market_app/shared/widgets/modern_text_field.dart';
import 'package:mapanytime_market_app/shared/widgets/top_toast.dart';
import 'package:mapanytime_market_app/theme/tokens/colors.dart';
import 'package:mapanytime_market_app/theme/tokens/radius.dart';
import 'package:mapanytime_market_app/theme/tokens/spacing.dart';

/// Add an address, or edit [initial]. A new address starts with the
/// account's name and the default address's phone filled in.
class AddressFormPage extends ConsumerStatefulWidget {
  const AddressFormPage({this.initial, super.key});

  final BuyerAddress? initial;

  @override
  ConsumerState<AddressFormPage> createState() => _AddressFormPageState();
}

class _AddressFormPageState extends ConsumerState<AddressFormPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _phone;
  late final TextEditingController _address;
  late AddressType _type;
  late bool _isDefault;
  var _saving = false;

  bool get _isEdit => widget.initial != null;

  /// The buyer's only default can't be switched off here (pick another
  /// address as default instead), and a first address is always the default.
  late final bool _defaultLocked;

  @override
  void initState() {
    super.initState();
    final initial = widget.initial;
    final existing = ref.read(addressesControllerProvider).value ?? const [];
    final fallbackPhone = ref.read(defaultAddressProvider)?.phoneNumber ?? '';

    _name = TextEditingController(
      text: initial?.recipientName ?? ref.read(profileProvider)?.name ?? '',
    );
    _phone = TextEditingController(
      text: _localPhone(initial?.phoneNumber ?? fallbackPhone),
    );
    _address = TextEditingController(text: initial?.addressLine1 ?? '');
    _type = initial?.type ?? AddressType.home;
    _defaultLocked = (initial?.isDefault ?? false) || existing.isEmpty;
    _isDefault = _defaultLocked || (initial?.isDefault ?? false);
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _address.dispose();
    super.dispose();
  }

  /// `+639171234567` → `9171234567`, to sit after the field's `+63` prefix.
  static String _localPhone(String e164) =>
      e164.startsWith('+63') ? e164.substring(3) : e164;

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final draft = AddressDraft(
      type: _type,
      recipientName: _name.text.trim(),
      phoneNumber: Validators.normalizePhMobile(_phone.text)!,
      addressLine1: _address.text.trim(),
      isDefault: _isDefault,
    );
    final controller = ref.read(addressesControllerProvider.notifier);
    final ok = _isEdit
        ? await controller.edit(widget.initial!.id, draft)
        : await controller.add(draft);
    if (!mounted) return;
    setState(() => _saving = false);

    if (ok) {
      showTopToast(context, 'Address saved');
      context.pop();
    } else {
      showTopToast(context, "Couldn't save the address. Try again.");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ModernAppBar(title: _isEdit ? 'Edit address' : 'Add address'),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.md),
          children: [
            const _Label('Type'),
            Row(
              children: [
                for (final (i, type) in AddressType.values.indexed) ...[
                  if (i > 0) AppSpacing.sm.h,
                  Expanded(
                    child: _TypeChip(
                      key: ValueKey('type-${type.apiValue}'),
                      label: type.label,
                      selected: _type == type,
                      onTap: () => setState(() => _type = type),
                    ),
                  ),
                ],
              ],
            ),
            AppSpacing.lg.v,
            ModernTextField(
              key: const ValueKey('recipientName'),
              label: 'Recipient name',
              hint: 'Juan Dela Cruz',
              controller: _name,
              textCapitalization: TextCapitalization.words,
              validator: Validators.notEmpty,
            ),
            AppSpacing.md.v,
            ModernTextField(
              key: const ValueKey('addressPhone'),
              label: 'Phone number',
              hint: '917 123 4567',
              controller: _phone,
              prefixText: '+63 ',
              keyboardType: TextInputType.phone,
              validator: Validators.phMobile,
            ),
            AppSpacing.md.v,
            ModernTextField(
              key: const ValueKey('addressLine'),
              label: 'Address',
              hint: 'House no., street, barangay, city, province',
              controller: _address,
              keyboardType: TextInputType.streetAddress,
              textCapitalization: TextCapitalization.words,
              minLines: 2,
              maxLines: 4,
              validator: Validators.notEmpty,
            ),
            AppSpacing.md.v,
            SwitchListTile.adaptive(
              key: const ValueKey('isDefault'),
              contentPadding: EdgeInsets.zero,
              value: _isDefault,
              activeTrackColor: AppColors.ink,
              onChanged: _defaultLocked
                  ? null
                  : (v) => setState(() => _isDefault = v),
              title: const Text('Set as default'),
              subtitle: _defaultLocked
                  ? Text(
                      _isEdit
                          ? 'To change it, set another address as default.'
                          : 'Your first address is your default.',
                    )
                  : null,
            ),
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(
          AppSpacing.md,
          AppSpacing.sm,
          AppSpacing.md,
          AppSpacing.md,
        ),
        child: PrimaryButton(
          label: 'Save address',
          isLoading: _saving,
          onPressed: _save,
        ),
      ),
    );
  }
}

class _Label extends StatelessWidget {
  const _Label(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.text.secondary,
        ),
      ),
    );
  }
}

class _TypeChip extends StatelessWidget {
  const _TypeChip({
    required this.label,
    required this.selected,
    required this.onTap,
    super.key,
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
            padding: const EdgeInsets.symmetric(vertical: 13),
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14.5,
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
